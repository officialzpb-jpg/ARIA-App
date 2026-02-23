import { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { prisma } from '../lib/prisma';

const createConversationSchema = z.object({
  transcript: z.string(),
  aiResponse: z.string(),
  modelUsed: z.string(),
  latencyMs: z.number().optional(),
  routedTo: z.array(z.string()).optional()
});

export async function conversationRoutes(app: FastifyInstance) {
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
  
  // List conversations
  app.get('/', async (request) => {
    const { page = '1', limit = '20' } = request.query as { page?: string; limit?: string };
    
    const skip = (parseInt(page) - 1) * parseInt(limit);
    const take = parseInt(limit);
    
    const [conversations, total] = await Promise.all([
      prisma.conversation.findMany({
        where: { userId: request.user.id },
        orderBy: { createdAt: 'desc' },
        skip,
        take
      }),
      prisma.conversation.count({
        where: { userId: request.user.id }
      })
    ]);
    
    return {
      conversations,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / take)
      }
    };
  });
  
  // Get single conversation
  app.get('/:id', async (request, reply) => {
    const { id } = request.params as { id: string };
    
    const conversation = await prisma.conversation.findFirst({
      where: {
        id,
        userId: request.user.id
      }
    });
    
    if (!conversation) {
      return reply.status(404).send({
        error: true,
        message: 'Conversation not found'
      });
    }
    
    return { conversation };
  });
  
  // Create conversation
  app.post('/', async (request, reply) => {
    try {
      const data = createConversationSchema.parse(request.body);
      
      const conversation = await prisma.conversation.create({
        data: {
          userId: request.user.id,
          transcript: data.transcript,
          aiResponse: data.aiResponse,
          modelUsed: data.modelUsed,
          latencyMs: data.latencyMs,
          routedTo: data.routedTo || []
        }
      });
      
      return { conversation };
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
  
  // Delete conversation
  app.delete('/:id', async (request, reply) => {
    const { id } = request.params as { id: string };
    
    await prisma.conversation.deleteMany({
      where: {
        id,
        userId: request.user.id
      }
    });
    
    return { success: true };
  });
  
  // Delete all conversations
  app.delete('/', async (request) => {
    await prisma.conversation.deleteMany({
      where: { userId: request.user.id }
    });
    
    return { success: true };
  });
  
  // Search conversations
  app.get('/search', async (request) => {
    const { q } = request.query as { q: string };
    
    if (!q) {
      return { conversations: [] };
    }
    
    const conversations = await prisma.conversation.findMany({
      where: {
        userId: request.user.id,
        OR: [
          { transcript: { contains: q, mode: 'insensitive' } },
          { aiResponse: { contains: q, mode: 'insensitive' } }
        ]
      },
      orderBy: { createdAt: 'desc' },
      take: 20
    });
    
    return { conversations };
  });
}
