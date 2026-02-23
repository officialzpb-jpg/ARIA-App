// Type declarations for ARIA Backend

import { FastifyRequest } from 'fastify';

// Extend FastifyRequest to include user from JWT
declare module 'fastify' {
  interface FastifyRequest {
    user: {
      id: string;
      email: string;
    };
  }
}

// JWT payload type
declare module '@fastify/jwt' {
  interface FastifyJWT {
    payload: {
      id: string;
      email: string;
    };
    user: {
      id: string;
      email: string;
    };
  }
}
