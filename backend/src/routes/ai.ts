import { FastifyInstance } from 'fastify';
import { z } from 'zod';
import OpenAI from 'openai';
import { prisma } from '../lib/prisma';

const generateSchema = z.object({
  prompt: z.string(),
  provider: z.enum(['openai', 'anthropic', 'google', 'mistral']).default('openai'),
  model: z.string().optional(),
  systemPrompt: z.string().optional(),
  temperature: z.number().min(0).max(2).default(0.7),
  maxTokens: z.number().default(1000)
});

const transcribeSchema = z.object({
  audioBase64: z.string(),
  provider: z.enum(['whisper', 'google', 'aws']).default('whisper')
});

export async function aiRoutes(app: FastifyInstance) {
  // Middleware to verify JWT
  app.addHook('onRequest', async (request, reply) => {
    try {
      await request.jwtVerify();
    } catch (err) {
      reply.status(401).send({
        error: true,
        message: 'Unauthorized'
      });
    }
  });
  
  // Generate AI response
  app.post('/generate', async (request, reply) => {
    const startTime = Date.now();
    
    try {
      const data = generateSchema.parse(request.body);
      
      // Get user's API key for the provider
      const apiKeyConfig = await prisma.apiKey.findFirst({
        where: {
          userId: request.user.id,
          provider: data.provider
        }
      });
      
      if (!apiKeyConfig) {
        return reply.status(400).send({
          error: true,
          message: `No API key configured for ${data.provider}`
        });
      }
      
      let response: string;
      let modelUsed: string;
      
      switch (data.provider) {
        case 'openai':
          const openaiResult = await callOpenAI(data, apiKeyConfig.encryptedKey);
          response = openaiResult.response;
          modelUsed = openaiResult.model;
          break;
        case 'anthropic':
          const anthropicResult = await callAnthropic(data, apiKeyConfig.encryptedKey);
          response = anthropicResult.response;
          modelUsed = anthropicResult.model;
          break;
        default:
          return reply.status(400).send({
            error: true,
            message: 'Provider not yet implemented'
          });
      }
      
      const latencyMs = Date.now() - startTime;
      
      return {
        response,
        model: modelUsed,
        latencyMs,
        provider: data.provider
      };
    } catch (error) {
      if (error instanceof z.ZodError) {
        return reply.status(400).send({
          error: true,
          message: 'Invalid input',
          details: error.errors
        });
      }
      
      return reply.status(500).send({
        error: true,
        message: error instanceof Error ? error.message : 'AI generation failed'
      });
    }
  });
  
  // Transcribe audio
  app.post('/transcribe', async (request, reply) => {
    try {
      const { audioBase64, provider } = transcribeSchema.parse(request.body);
      
      // Get user's OpenAI key for Whisper
      const apiKeyConfig = await prisma.apiKey.findFirst({
        where: {
          userId: request.user.id,
          provider: 'openai'
        }
      });
      
      if (!apiKeyConfig) {
        return reply.status(400).send({
          error: true,
          message: 'OpenAI API key required for transcription'
        });
      }
      
      // Decode base64 audio
      const audioBuffer = Buffer.from(audioBase64, 'base64');
      
      // Call Whisper API
      const openai = new OpenAI({ apiKey: apiKeyConfig.encryptedKey });
      
      const file = new File([audioBuffer], 'audio.wav', { type: 'audio/wav' });
      
      const transcription = await openai.audio.transcriptions.create({
        file: file as any,
        model: 'whisper-1'
      });
      
      return {
        transcript: transcription.text,
        provider: 'whisper-1'
      };
    } catch (error) {
      if (error instanceof z.ZodError) {
        return reply.status(400).send({
          error: true,
          message: 'Invalid input',
          details: error.errors
        });
      }
      
      return reply.status(500).send({
        error: true,
        message: error instanceof Error ? error.message : 'Transcription failed'
      });
    }
  });
  
  // List available models
  app.get('/models', async () => {
    return {
      models: [
        { id: 'gpt-4o', provider: 'openai', name: 'GPT-4o', contextWindow: 128000 },
        { id: 'gpt-4o-mini', provider: 'openai', name: 'GPT-4o Mini', contextWindow: 128000 },
        { id: 'o1-preview', provider: 'openai', name: 'o1 Preview', contextWindow: 128000 },
        { id: 'claude-3-5-sonnet', provider: 'anthropic', name: 'Claude 3.5 Sonnet', contextWindow: 200000 },
        { id: 'claude-3-opus', provider: 'anthropic', name: 'Claude 3 Opus', contextWindow: 200000 },
        { id: 'gemini-1.5-pro', provider: 'google', name: 'Gemini 1.5 Pro', contextWindow: 1000000 },
        { id: 'gemini-1.5-flash', provider: 'google', name: 'Gemini 1.5 Flash', contextWindow: 1000000 }
      ]
    };
  });
  
  // Stream generation via SSE (Server-Sent Events)
  app.get('/stream', async (request, reply) => {
    reply.raw.writeHead(200, {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      'Connection': 'keep-alive'
    });
    
    reply.raw.write('data: {"type": "connected"}\n\n');
    
    // In a real implementation, you'd stream from the AI provider
    // For now, just close the connection
    reply.raw.end();
  });
}

// OpenAI integration
async function callOpenAI(data: z.infer<typeof generateSchema>, apiKey: string): Promise<{ response: string; model: string }> {
  const openai = new OpenAI({ apiKey });
  
  const model = data.model || 'gpt-4o-mini';
  
  const response = await openai.chat.completions.create({
    model,
    messages: [
      { role: 'system', content: data.systemPrompt || 'You are a helpful assistant.' },
      { role: 'user', content: data.prompt }
    ],
    temperature: data.temperature,
    max_tokens: data.maxTokens
  });
  
  return {
    response: response.choices[0]?.message?.content || '',
    model
  };
}

// Anthropic integration
async function callAnthropic(data: z.infer<typeof generateSchema>, apiKey: string): Promise<{ response: string; model: string }> {
  const model = data.model || 'claude-3-5-sonnet-20241022';
  
  const response = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'x-api-key': apiKey,
      'anthropic-version': '2023-06-01'
    },
    body: JSON.stringify({
      model,
      max_tokens: data.maxTokens,
      system: data.systemPrompt || 'You are a helpful assistant.',
      messages: [
        { role: 'user', content: data.prompt }
      ]
    })
  });
  
  if (!response.ok) {
    throw new Error(`Anthropic API error: ${response.status}`);
  }
  
  const result = await response.json() as any;
  
  return {
    response: result.content?.[0]?.text || '',
    model
  };
}
