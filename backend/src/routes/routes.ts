import { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { prisma } from '../lib/prisma';

const createRouteSchema = z.object({
  name: z.string().min(1),
  conditions: z.array(z.object({
    type: z.enum(['contains', 'starts_with', 'sentiment', 'time_of_day', 'keyword']),
    value: z.string()
  })),
  actions: z.array(z.object({
    channel: z.enum(['discord', 'telegram', 'sms', 'email', 'slack', 'webhook']),
    destination: z.string()
  })),
  priority: z.number().default(0)
});

export async function routeRoutes(app: FastifyInstance) {
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
  
  // List routes
  app.get('/', async (request) => {
    const routes = await prisma.routingRule.findMany({
      where: { userId: request.user.id },
      orderBy: { priority: 'desc' }
    });
    
    return { routes };
  });
  
  // Create route
  app.post('/', async (request, reply) => {
    try {
      const data = createRouteSchema.parse(request.body);
      
      const route = await prisma.routingRule.create({
        data: {
          userId: request.user.id,
          name: data.name,
          conditions: data.conditions,
          actions: data.actions,
          priority: data.priority,
          isEnabled: true
        }
      });
      
      return { route };
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
  
  // Update route
  app.put('/:id', async (request, reply) => {
    try {
      const { id } = request.params as { id: string };
      const data = createRouteSchema.partial().parse(request.body);
      
      const route = await prisma.routingRule.updateMany({
        where: {
          id,
          userId: request.user.id
        },
        data: {
          ...data,
          updatedAt: new Date()
        }
      });
      
      if (route.count === 0) {
        return reply.status(404).send({
          error: true,
          message: 'Route not found'
        });
      }
      
      return { success: true };
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
  
  // Toggle route
  app.patch('/:id/toggle', async (request, reply) => {
    const { id } = request.params as { id: string };
    
    const existingRoute = await prisma.routingRule.findFirst({
      where: {
        id,
        userId: request.user.id
      }
    });
    
    if (!existingRoute) {
      return reply.status(404).send({
        error: true,
        message: 'Route not found'
      });
    }
    
    await prisma.routingRule.update({
      where: { id },
      data: { isEnabled: !existingRoute.isEnabled }
    });
    
    return { success: true, isEnabled: !existingRoute.isEnabled };
  });
  
  // Delete route
  app.delete('/:id', async (request, reply) => {
    const { id } = request.params as { id: string };
    
    await prisma.routingRule.deleteMany({
      where: {
        id,
        userId: request.user.id
      }
    });
    
    return { success: true };
  });
  
  // Test route
  app.post('/:id/test', async (request, reply) => {
    const { id } = request.params as { id: string };
    const { content } = request.body as { content: string };
    
    const route = await prisma.routingRule.findFirst({
      where: {
        id,
        userId: request.user.id
      }
    });
    
    if (!route) {
      return reply.status(404).send({
        error: true,
        message: 'Route not found'
      });
    }
    
    // Check if content matches conditions
    const matches = checkConditions(content, route.conditions as any[]);
    
    return {
      matches,
      route: {
        name: route.name,
        actions: route.actions
      }
    };
  });
}

// Helper to check if content matches conditions
function checkConditions(content: string, conditions: Array<{ type: string; value: string }>): boolean {
  const lowerContent = content.toLowerCase();
  
  for (const condition of conditions) {
    switch (condition.type) {
      case 'contains':
        if (!lowerContent.includes(condition.value.toLowerCase())) {
          return false;
        }
        break;
      case 'starts_with':
        if (!lowerContent.startsWith(condition.value.toLowerCase())) {
          return false;
        }
        break;
      case 'keyword':
        const keywords = condition.value.split(',').map(k => k.trim().toLowerCase());
        if (!keywords.some(k => lowerContent.includes(k))) {
          return false;
        }
        break;
      // Add more condition types
    }
  }
  
  return true;
}
