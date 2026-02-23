import { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { prisma } from '../lib/prisma';

const discordWebhookSchema = z.object({
  content: z.string(),
  webhookUrl: z.string().url()
});

const telegramSchema = z.object({
  content: z.string(),
  botToken: z.string(),
  chatId: z.string()
});

const smsSchema = z.object({
  content: z.string(),
  phoneNumber: z.string(),
  twilioAccountSid: z.string().optional(),
  twilioAuthToken: z.string().optional()
});

const emailSchema = z.object({
  to: z.string().email(),
  subject: z.string(),
  body: z.string(),
  provider: z.enum(['sendgrid', 'ses', 'smtp']).optional()
});

const slackSchema = z.object({
  content: z.string(),
  webhookUrl: z.string().url()
});

const genericWebhookSchema = z.object({
  url: z.string().url(),
  method: z.enum(['GET', 'POST', 'PUT', 'PATCH', 'DELETE']).default('POST'),
  headers: z.record(z.string()).optional(),
  body: z.any().optional()
});

export async function webhookRoutes(app: FastifyInstance) {
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
  
  // Discord webhook
  app.post('/discord', async (request, reply) => {
    try {
      const { content, webhookUrl } = discordWebhookSchema.parse(request.body);
      
      const response = await fetch(webhookUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          content,
          username: 'ARIA Assistant'
        })
      });
      
      if (!response.ok) {
        throw new Error(`Discord webhook failed: ${response.status}`);
      }
      
      // Log the message
      await prisma.messageLog.create({
        data: {
          userId: request.user.id,
          channel: 'discord',
          destination: webhookUrl,
          content: content.slice(0, 1000), // Limit storage
          status: 'sent'
        }
      });
      
      return { success: true };
    } catch (error) {
      // Log failure
      await prisma.messageLog.create({
        data: {
          userId: request.user.id,
          channel: 'discord',
          destination: (request.body as any)?.webhookUrl || '',
          content: (request.body as any)?.content?.slice(0, 1000) || '',
          status: 'failed',
          error: error instanceof Error ? error.message : 'Unknown error'
        }
      });
      
      return reply.status(500).send({
        error: true,
        message: error instanceof Error ? error.message : 'Failed to send to Discord'
      });
    }
  });
  
  // Telegram bot
  app.post('/telegram', async (request, reply) => {
    try {
      const { content, botToken, chatId } = telegramSchema.parse(request.body);
      
      const response = await fetch(`https://api.telegram.org/bot${botToken}/sendMessage`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          chat_id: chatId,
          text: content,
          parse_mode: 'Markdown'
        })
      });
      
      if (!response.ok) {
        throw new Error(`Telegram API failed: ${response.status}`);
      }
      
      await prisma.messageLog.create({
        data: {
          userId: request.user.id,
          channel: 'telegram',
          destination: chatId,
          content: content.slice(0, 1000),
          status: 'sent'
        }
      });
      
      return { success: true };
    } catch (error) {
      await prisma.messageLog.create({
        data: {
          userId: request.user.id,
          channel: 'telegram',
          destination: (request.body as any)?.chatId || '',
          content: (request.body as any)?.content?.slice(0, 1000) || '',
          status: 'failed',
          error: error instanceof Error ? error.message : 'Unknown error'
        }
      });
      
      return reply.status(500).send({
        error: true,
        message: error instanceof Error ? error.message : 'Failed to send to Telegram'
      });
    }
  });
  
  // SMS via Twilio
  app.post('/sms', async (request, reply) => {
    try {
      const { content, phoneNumber } = smsSchema.parse(request.body);
      
      // In production, use Twilio SDK
      // For now, return success (Twilio integration would go here)
      
      await prisma.messageLog.create({
        data: {
          userId: request.user.id,
          channel: 'sms',
          destination: phoneNumber,
          content: content.slice(0, 1000),
          status: 'sent'
        }
      });
      
      return { success: true, note: 'Twilio integration required' };
    } catch (error) {
      return reply.status(500).send({
        error: true,
        message: error instanceof Error ? error.message : 'Failed to send SMS'
      });
    }
  });
  
  // Email
  app.post('/email', async (request, reply) => {
    try {
      const { to, subject, body } = emailSchema.parse(request.body);
      
      // In production, integrate with SendGrid/AWS SES
      // For now, return success
      
      await prisma.messageLog.create({
        data: {
          userId: request.user.id,
          channel: 'email',
          destination: to,
          content: subject,
          status: 'sent'
        }
      });
      
      return { success: true, note: 'Email provider integration required' };
    } catch (error) {
      return reply.status(500).send({
        error: true,
        message: error instanceof Error ? error.message : 'Failed to send email'
      });
    }
  });
  
  // Slack webhook
  app.post('/slack', async (request, reply) => {
    try {
      const { content, webhookUrl } = slackSchema.parse(request.body);
      
      const response = await fetch(webhookUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ text: content })
      });
      
      if (!response.ok) {
        throw new Error(`Slack webhook failed: ${response.status}`);
      }
      
      await prisma.messageLog.create({
        data: {
          userId: request.user.id,
          channel: 'slack',
          destination: webhookUrl,
          content: content.slice(0, 1000),
          status: 'sent'
        }
      });
      
      return { success: true };
    } catch (error) {
      await prisma.messageLog.create({
        data: {
          userId: request.user.id,
          channel: 'slack',
          destination: (request.body as any)?.webhookUrl || '',
          content: (request.body as any)?.content?.slice(0, 1000) || '',
          status: 'failed',
          error: error instanceof Error ? error.message : 'Unknown error'
        }
      });
      
      return reply.status(500).send({
        error: true,
        message: error instanceof Error ? error.message : 'Failed to send to Slack'
      });
    }
  });
  
  // Generic webhook
  app.post('/custom', async (request, reply) => {
    try {
      const { url, method, headers, body } = genericWebhookSchema.parse(request.body);
      
      const response = await fetch(url, {
        method,
        headers: {
          'Content-Type': 'application/json',
          ...headers
        },
        body: body ? JSON.stringify(body) : undefined
      });
      
      const responseBody = await response.text();
      
      await prisma.messageLog.create({
        data: {
          userId: request.user.id,
          channel: 'webhook',
          destination: url,
          content: JSON.stringify(body)?.slice(0, 1000) || '',
          status: response.ok ? 'sent' : 'failed',
          error: response.ok ? null : `HTTP ${response.status}`
        }
      });
      
      return {
        success: response.ok,
        status: response.status,
        response: responseBody.slice(0, 1000)
      };
    } catch (error) {
      return reply.status(500).send({
        error: true,
        message: error instanceof Error ? error.message : 'Failed to send webhook'
      });
    }
  });
}
