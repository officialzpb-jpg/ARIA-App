import { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { prisma } from '../lib/prisma';

const addProviderSchema = z.object({
  provider: z.enum(['openai', 'anthropic', 'google', 'mistral', 'local']),
  apiKey: z.string(),
  label: z.string().optional()
});

const validateProviderSchema = z.object({
  provider: z.string(),
  apiKey: z.string()
});

export async function providerRoutes(app: FastifyInstance) {
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
  
  // List available providers
  app.get('/', async () => {
    return {
      providers: [
        {
          id: 'openai',
          name: 'OpenAI',
          models: ['gpt-4o', 'gpt-4o-mini', 'o1-preview'],
          features: ['function-calling', 'vision', 'json-mode']
        },
        {
          id: 'anthropic',
          name: 'Anthropic Claude',
          models: ['claude-3-5-sonnet', 'claude-3-opus'],
          features: ['100k-context', 'artifacts']
        },
        {
          id: 'google',
          name: 'Google Gemini',
          models: ['gemini-1.5-pro', 'gemini-1.5-flash'],
          features: ['1m-context', 'multimodal']
        },
        {
          id: 'mistral',
          name: 'Mistral AI',
          models: ['mistral-large', 'mistral-medium'],
          features: ['eu-data', 'function-calling']
        },
        {
          id: 'local',
          name: 'Local LLM',
          models: ['ollama', 'lm-studio'],
          features: ['privacy', 'offline']
        }
      ]
    };
  });
  
  // Get user's configured providers
  app.get('/configured', async (request) => {
    const providers = await prisma.apiKey.findMany({
      where: { userId: request.user.id },
      select: {
        id: true,
        provider: true,
        label: true,
        createdAt: true
        // Note: apiKey itself is not returned for security
      }
    });
    
    return { providers };
  });
  
  // Add provider API key
  app.post('/', async (request, reply) => {
    try {
      const { provider, apiKey, label } = addProviderSchema.parse(request.body);
      
      // In production, encrypt the API key before storing
      // For now, we store it (but would use encryption in real app)
      const encryptedKey = apiKey; // TODO: Implement encryption
      
      const providerConfig = await prisma.apiKey.create({
        data: {
          userId: request.user.id,
          provider,
          encryptedKey,
          label: label || provider
        },
        select: {
          id: true,
          provider: true,
          label: true,
          createdAt: true
        }
      });
      
      return { provider: providerConfig };
    } catch (error) {
      if (error instanceof z.ZodError) {
        return reply.status(400).send({
          error: true,
          message: 'Invalid input',
          details: error.errors
        });
      }
      throw error;
    }
  });
  
  // Validate provider API key
  app.post('/validate', async (request, reply) => {
    try {
      const { provider, apiKey } = validateProviderSchema.parse(request.body);
      
      // Validate based on provider
      let isValid = false;
      let models: string[] = [];
      
      switch (provider) {
        case 'openai':
          const openaiResult = await validateOpenAI(apiKey);
          isValid = openaiResult.valid;
          models = openaiResult.models;
          break;
        case 'anthropic':
          const anthropicResult = await validateAnthropic(apiKey);
          isValid = anthropicResult.valid;
          models = anthropicResult.models;
          break;
        // Add more providers
        default:
          return reply.status(400).send({
            error: true,
            message: 'Unsupported provider'
          });
      }
      
      return {
        valid: isValid,
        models: models
      };
    } catch (error) {
      if (error instanceof z.ZodError) {
        return reply.status(400).send({
          error: true,
          message: 'Invalid input',
          details: error.errors
        });
      }
      throw error;
    }
  });
  
  // Delete provider
  app.delete('/:id', async (request, reply) => {
    const { id } = request.params as { id: string };
    
    await prisma.apiKey.deleteMany({
      where: {
        id,
        userId: request.user.id
      }
    });
    
    return { success: true };
  });
}

// Validation helpers
async function validateOpenAI(apiKey: string): Promise<{ valid: boolean; models: string[] }> {
  try {
    const response = await fetch('https://api.openai.com/v1/models', {
      headers: {
        'Authorization': `Bearer ${apiKey}`
      }
    });
    
    if (!response.ok) {
      return { valid: false, models: [] };
    }
    
    const data = await response.json() as { data: Array<{ id: string }> };
    const models = data.data
      .filter(m => m.id.includes('gpt'))
      .map(m => m.id)
      .slice(0, 10);
    
    return { valid: true, models };
  } catch {
    return { valid: false, models: [] };
  }
}

async function validateAnthropic(apiKey: string): Promise<{ valid: boolean; models: string[] }> {
  try {
    const response = await fetch('https://api.anthropic.com/v1/models', {
      headers: {
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01'
      }
    });
    
    if (!response.ok) {
      return { valid: false, models: [] };
    }
    
    return { valid: true, models: ['claude-3-5-sonnet', 'claude-3-opus'] };
  } catch {
    return { valid: false, models: [] };
  }
}
