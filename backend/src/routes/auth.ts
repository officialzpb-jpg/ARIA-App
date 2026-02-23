import { FastifyInstance } from 'fastify';
import bcrypt from 'bcryptjs';
import { z } from 'zod';
import { prisma } from '../lib/prisma';

const registerSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
  name: z.string().optional()
});

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string()
});

export async function authRoutes(app: FastifyInstance) {
  // Register
  app.post('/register', async (request, reply) => {
    try {
      const { email, password, name } = registerSchema.parse(request.body);
      
      // Check if user exists
      const existingUser = await prisma.user.findUnique({
        where: { email }
      });
      
      if (existingUser) {
        return reply.status(400).send({
          error: true,
          message: 'User already exists'
        });
      }
      
      // Hash password
      const hashedPassword = await bcrypt.hash(password, 10);
      
      // Create user
      const user = await prisma.user.create({
        data: {
          email,
          password: hashedPassword,
          name,
          subscriptionTier: 'free'
        },
        select: {
          id: true,
          email: true,
          name: true,
          subscriptionTier: true,
          createdAt: true
        }
      });
      
      // Generate JWT
      const token = app.jwt.sign({
        id: user.id,
        email: user.email
      });
      
      return {
        user,
        token
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
  
  // Login
  app.post('/login', async (request, reply) => {
    try {
      const { email, password } = loginSchema.parse(request.body);
      
      // Find user
      const user = await prisma.user.findUnique({
        where: { email }
      });
      
      if (!user) {
        return reply.status(401).send({
          error: true,
          message: 'Invalid credentials'
        });
      }
      
      // Verify password
      const validPassword = await bcrypt.compare(password, user.password);
      
      if (!validPassword) {
        return reply.status(401).send({
          error: true,
          message: 'Invalid credentials'
        });
      }
      
      // Update last active
      await prisma.user.update({
        where: { id: user.id },
        data: { lastActive: new Date() }
      });
      
      // Generate JWT
      const token = app.jwt.sign({
        id: user.id,
        email: user.email
      });
      
      return {
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
          subscriptionTier: user.subscriptionTier
        },
        token
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
  
  // Refresh token
  app.post('/refresh', async (request, reply) => {
    try {
      await request.jwtVerify();
      
      const user = await prisma.user.findUnique({
        where: { id: request.user.id }
      });
      
      if (!user) {
        return reply.status(401).send({
          error: true,
          message: 'User not found'
        });
      }
      
      const token = app.jwt.sign({
        id: user.id,
        email: user.email
      });
      
      return { token };
    } catch (error) {
      return reply.status(401).send({
        error: true,
        message: 'Invalid token'
      });
    }
  });
  
  // Logout (client-side token deletion, but we can track sessions)
  app.post('/logout', async (request, reply) => {
    // In a more complex setup, we'd invalidate the token
    // For now, client just deletes the token
    return { success: true };
  });
}
