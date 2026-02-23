import Fastify from 'fastify';
import cors from '@fastify/cors';
import jwt from '@fastify/jwt';
import rateLimit from '@fastify/rate-limit';
import staticPlugin from '@fastify/static';
import path from 'path';
import dotenv from 'dotenv';

import { authRoutes } from './routes/auth';
import { userRoutes } from './routes/user';
import { providerRoutes } from './routes/providers';
import { routeRoutes } from './routes/routes';
import { conversationRoutes } from './routes/conversations';
import { webhookRoutes } from './routes/webhooks';
import { aiRoutes } from './routes/ai';

dotenv.config();

const app = Fastify({
  logger: true
});

// Register plugins
async function registerPlugins() {
  // CORS - Allow all origins for development
  await app.register(cors, {
    origin: true,
    credentials: true
  });

  // Serve static files from dashboard folder
  await app.register(staticPlugin, {
    root: path.join(__dirname, '../../dashboard'),
    prefix: '/',
  });

  // JWT
  await app.register(jwt, {
    secret: process.env.JWT_SECRET || 'your-secret-key-change-in-production',
    sign: {
      expiresIn: '7d'
    }
  });

  // Rate limiting
  await app.register(rateLimit, {
    max: 100,
    timeWindow: '1 minute'
  });
}

// Register routes
async function registerRoutes() {
  await app.register(authRoutes, { prefix: '/api/v1/auth' });
  await app.register(userRoutes, { prefix: '/api/v1/user' });
  await app.register(providerRoutes, { prefix: '/api/v1/providers' });
  await app.register(routeRoutes, { prefix: '/api/v1/routes' });
  await app.register(conversationRoutes, { prefix: '/api/v1/conversations' });
  await app.register(webhookRoutes, { prefix: '/api/v1/webhooks' });
  await app.register(aiRoutes, { prefix: '/api/v1/ai' });
}

// Health check
app.get('/health', async () => {
  return {
    status: 'ok',
    version: '1.0.0',
    service: 'aria-backend',
    timestamp: new Date().toISOString()
  };
});

// Error handler
app.setErrorHandler((error, request, reply) => {
  app.log.error(error);
  
  reply.status(error.statusCode || 500).send({
    error: true,
    message: error.message,
    code: error.code || 'INTERNAL_ERROR'
  });
});

// Start server
async function start() {
  try {
    await registerPlugins();
    await registerRoutes();
    
    const port = parseInt(process.env.PORT || '3000');
    const host = '0.0.0.0'; // Listen on all interfaces
    
    await app.listen({ port, host });
    
    app.log.info(`ARIA Backend running on:`);
    app.log.info(`  - Local:   http://localhost:${port}`);
    app.log.info(`  - Network: http://192.168.56.1:${port}`);
  } catch (err) {
    app.log.error(err);
    process.exit(1);
  }
}

start();
