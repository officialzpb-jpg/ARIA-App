# ARIA Backend API

AI Routing & Integration Assistant - Backend Server

## Features

- 🔐 JWT Authentication with bcrypt
- 🗄️ PostgreSQL database with Prisma ORM
- 🚦 Rate limiting per user
- 🔌 WebSocket support for streaming
- 📊 Conversation history and analytics
- 🎯 AI provider management (OpenAI, Anthropic, etc.)
- 🔄 Routing rules engine
- 📤 Webhook integrations (Discord, Telegram, Slack, SMS, Email)

## Quick Start

### 1. Install Dependencies

```bash
npm install
```

### 2. Set up Environment

```bash
cp .env.example .env
# Edit .env with your configuration
```

### 3. Set up Database

```bash
# Start PostgreSQL (Docker)
docker run -d \
  --name aria-postgres \
  -e POSTGRES_USER=aria \
  -e POSTGRES_PASSWORD=aria123 \
  -e POSTGRES_DB=aria \
  -p 5432:5432 \
  postgres:15

# Run migrations
npm run db:migrate

# Generate Prisma client
npm run db:generate
```

### 4. Start Development Server

```bash
npm run dev
```

Server will start on http://localhost:3000

## API Endpoints

### Authentication
- `POST /api/v1/auth/register` - Register new user
- `POST /api/v1/auth/login` - Login
- `POST /api/v1/auth/refresh` - Refresh JWT token
- `POST /api/v1/auth/logout` - Logout

### User
- `GET /api/v1/user/profile` - Get user profile
- `PUT /api/v1/user/profile` - Update profile
- `GET /api/v1/user/usage` - Get usage statistics
- `DELETE /api/v1/user/account` - Delete account

### AI Providers
- `GET /api/v1/providers` - List available providers
- `GET /api/v1/providers/configured` - Get user's configured providers
- `POST /api/v1/providers` - Add provider API key
- `POST /api/v1/providers/validate` - Validate provider API key
- `DELETE /api/v1/providers/:id` - Remove provider

### Routing Rules
- `GET /api/v1/routes` - List routing rules
- `POST /api/v1/routes` - Create routing rule
- `PUT /api/v1/routes/:id` - Update routing rule
- `PATCH /api/v1/routes/:id/toggle` - Toggle rule on/off
- `DELETE /api/v1/routes/:id` - Delete rule
- `POST /api/v1/routes/:id/test` - Test rule against content

### Conversations
- `GET /api/v1/conversations` - List conversations
- `GET /api/v1/conversations/:id` - Get single conversation
- `POST /api/v1/conversations` - Create conversation
- `DELETE /api/v1/conversations/:id` - Delete conversation
- `DELETE /api/v1/conversations` - Delete all conversations
- `GET /api/v1/conversations/search?q=query` - Search conversations

### AI
- `POST /api/v1/ai/generate` - Generate AI response
- `POST /api/v1/ai/transcribe` - Transcribe audio
- `GET /api/v1/ai/models` - List available models
- `GET /api/v1/ai/stream` - WebSocket streaming endpoint

### Webhooks
- `POST /api/v1/webhooks/discord` - Send to Discord
- `POST /api/v1/webhooks/telegram` - Send to Telegram
- `POST /api/v1/webhooks/sms` - Send SMS via Twilio
- `POST /api/v1/webhooks/email` - Send email
- `POST /api/v1/webhooks/slack` - Send to Slack
- `POST /api/v1/webhooks/custom` - Send to custom webhook

## Database Schema

See `prisma/schema.prisma` for full schema definition.

### Main Entities

- **User**: Accounts and authentication
- **ApiKey**: Encrypted API keys for AI providers
- **RoutingRule**: User-defined routing automation rules
- **Conversation**: History of voice queries and AI responses
- **MessageLog**: Delivery tracking for routed messages

## Development

### Running Tests

```bash
npm test
```

### Linting

```bash
npm run lint
```

### Database Studio

```bash
npm run db:studio
```

## Deployment

### Docker

```bash
docker build -t aria-backend .
docker run -p 3000:3000 --env-file .env aria-backend
```

### Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `DATABASE_URL` | PostgreSQL connection string | Yes |
| `JWT_SECRET` | Secret for JWT signing | Yes |
| `REDIS_URL` | Redis connection (optional) | No |
| `CORS_ORIGIN` | Allowed CORS origins | No |

## Architecture

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   iOS App   │────▶│  Fastify    │────▶│  PostgreSQL │
│ Android App │     │   Server    │     │   (Prisma)  │
└─────────────┘     └─────────────┘     └─────────────┘
                           │
                    ┌──────┴──────┐
                    ▼             ▼
              ┌─────────┐   ┌─────────┐
              │  Redis  │   │ AI APIs │
              │ (Cache) │   │(OpenAI) │
              └─────────┘   └─────────┘
```

## License

MIT
