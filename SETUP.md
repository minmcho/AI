# Quick Setup Guide for NutriVision AI

## Prerequisites Check

Before starting, verify you have:
- [ ] Docker Desktop installed and running
- [ ] Git installed
- [ ] At least 8GB RAM available
- [ ] At least 20GB disk space

## Quick Start (5 minutes)

### Step 1: Clone and Configure

```bash
# Clone repository
git clone https://github.com/minmcho/radiant-vision-app.git
cd radiant-vision-app

# Copy environment file
cp backend/.env.example backend/.env
```

### Step 2: Start Services

```bash
# Start all services with Docker Compose
docker-compose up -d

# Wait for services to be healthy (~30 seconds)
docker-compose ps
```

### Step 3: Initialize AI Models

```bash
# Pull LLaMA 3.2 model (one-time, ~4GB download)
docker exec -it nutrivision-ollama ollama pull llama3.2

# Verify model is loaded
docker exec -it nutrivision-ollama ollama list
```

### Step 4: Initialize Database

```bash
# Run database migrations
docker exec -it nutrivision-backend alembic upgrade head

# Or manually initialize
docker exec -it nutrivision-backend python -c "from app.db.database import init_db; import asyncio; asyncio.run(init_db())"
```

### Step 5: Verify Installation

```bash
# Check backend health
curl http://localhost:8000/health

# Expected response:
# {"status":"healthy","database":"connected","ai_models":"ready"}
```

## Access Points

- **GraphQL Playground**: http://localhost:8000/graphql
- **API Docs**: http://localhost:8000/docs
- **Backend API**: http://localhost:8000

## Test the API

### Example GraphQL Query

Visit http://localhost:8000/graphql and try:

```graphql
query {
  hello
}
```

### Example: Chat with Cooking Assistant

```graphql
mutation {
  chatWithCookingAssistant(message: "How do I make pasta al dente?") {
    message
    agentName
    confidence
  }
}
```

## Troubleshooting

### Services won't start
```bash
# Check logs
docker-compose logs

# Restart services
docker-compose restart
```

### Database connection errors
```bash
# Verify PostgreSQL is running
docker-compose ps postgres

# Check database logs
docker-compose logs postgres
```

### Ollama model issues
```bash
# Check if Ollama is running
docker-compose ps ollama

# Verify models
docker exec -it nutrivision-ollama ollama list

# Re-pull model if needed
docker exec -it nutrivision-ollama ollama pull llama3.2
```

### Port conflicts
If ports 8000, 5432, 6379, or 11434 are already in use:

1. Stop conflicting services
2. Or modify `docker-compose.yml` to use different ports

## Manual Setup (Without Docker)

If you prefer not to use Docker:

### Backend Only

```bash
# 1. Install PostgreSQL 15+
# 2. Install Redis 7+
# 3. Install Python 3.11+

# Create virtual environment
cd backend
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Create database
createdb nutrivision

# Configure environment
cp .env.example .env
# Edit .env with your database credentials

# Start Redis
redis-server

# Install and start Ollama
# Download from: https://ollama.ai
ollama serve
ollama pull llama3.2

# Run migrations
alembic upgrade head

# Start backend
uvicorn app.main:app --reload
```

## What's Next?

1. **Explore the API**: Visit http://localhost:8000/docs
2. **Try GraphQL**: http://localhost:8000/graphql
3. **Read the Architecture**: See ARCHITECTURE.md
4. **Check Examples**: See examples/ directory (coming soon)

## Getting Help

- Check logs: `docker-compose logs -f backend`
- Review architecture: `ARCHITECTURE.md`
- Open an issue: https://github.com/minmcho/radiant-vision-app/issues

## Stopping Services

```bash
# Stop all services
docker-compose down

# Stop and remove volumes (WARNING: deletes data)
docker-compose down -v
```

## Next Steps

- Set up API keys for external services (YouTube, USDA, Edamam)
- Explore the multi-agent system
- Build the frontend (Next.js coming soon)
- Customize agents for your needs
