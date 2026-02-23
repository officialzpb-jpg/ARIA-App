import { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { prisma } from '../lib/prisma';

const updateProfileSchema = z.object({
  name: z.string().optional(),
  email: z.string().email().optional()
});

export async function userRoutes(app: FastifyInstance) {
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
  
  // Get profile
  app.get('/profile', async (request) => {
    const user = await prisma.user.findUnique({
      where: { id: request.user.id },
      select: {
        id: true,
        email: true,
        name: true,
        subscriptionTier: true,
        createdAt: true,
        lastActive: true
      }
    });
    
    return { user };
  });
  
  // Update profile
  app.put('/profile', async (request, reply) => {
    try {
      const data = updateProfileSchema.parse(request.body);
      
      const user = await prisma.user.update({
        where: { id: request.user.id },
        data,
        select: {
          id: true,
          email: true,
          name: true,
          subscriptionTier: true,
          createdAt: true,
          lastActive: true
        }
      });
      
      return { user };
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
  
  // Get usage stats
  app.get('/usage', async (request) => {
    const now = new Date();
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
    
    const [
      totalConversations,
      monthlyConversations,
      totalMessages,
      routingStats
    ] = await Promise.all([
      prisma.conversation.count({
        where: { userId: request.user.id }
      }),
      prisma.conversation.count({
        where: {
          userId: request.user.id,
          createdAt: { gte: startOfMonth }
        }
      }),
      prisma.messageLog.count({
        where: { userId: request.user.id }
      }),
      prisma.messageLog.groupBy({
        by: ['channel'],
        where: { userId: request.user.id },
        _count: { channel: true }
      })
    ]);
    
    return {
      totalConversations,
      monthlyConversations,
      totalMessages,
      routingStats: routingStats.map(stat => ({
        channel: stat.channel,
        count: stat._count.channel
      }))
    };
  });
  
  // Delete account
  app.delete('/account', async (request, reply) => {
    await prisma.user.delete({
      where: { id: request.user.id }
    });
    
    return { success: true };
  });
}
