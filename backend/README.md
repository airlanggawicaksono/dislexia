# Dislexia Backend

FastAPI backend for the Dislexia Reader monorepo with 7-digit access code authentication.

## Features

- **7-digit Access Code Authentication** (like Mullvad) — no passwords, just codes
- **JWT Token** sessions after login
- **Auto-generated usernames** (Adjective + Animal)
- **Feature stubs**: Summarize, Professionalize, Define
- **History routes**: `/{md5_hash}/{feature}/history`
- **Async PostgreSQL** with SQLAlchemy 2.0
- **Docker** ready with docker-compose

## Quick Start

```bash
cd backend

# 1. Create .env
cp .env.example .env

# 2. Run with Docker (recommended)
make dev

# 3. API docs at http://localhost:8000/docs
```

## Project Structure

```
backend/
├── app/
│   ├── config/       # Settings & database
│   ├── dto/          # Data Transfer Objects
│   │   ├── auth/     # Auth DTOs
│   │   └── feature/  # Feature DTOs (summarize, professionalize, define)
│   ├── models/       # SQLAlchemy models
│   ├── routers/      # API endpoints
│   │   ├── auth.py           # /api/v1/auth/*
│   │   ├── summarize.py      # /api/v1/{hash}/summarize/*
│   │   ├── professionalize.py # /api/v1/{hash}/professionalize/*
│   │   └── define.py         # /api/v1/{hash}/define/*
│   ├── services/     # Business logic
│   └── utils/        # Helpers (JWT, access code gen, username gen)
├── tests/
├── Dockerfile
├── docker-compose.yml
├── docker-compose.prod.yml
├── Makefile
└── requirements.txt
```

## API Routes

| Method | Route | Description |
|--------|-------|-------------|
| POST | `/api/v1/auth/signup` | Create account (returns 7-digit code) |
| POST | `/api/v1/auth/login` | Login with 7-digit code (returns JWT) |
| POST | `/api/v1/{hash}/summarize/process` | Summarize text |
| GET | `/api/v1/{hash}/summarize/history` | Summarize history |
| POST | `/api/v1/{hash}/professionalize/process` | Professionalize text |
| GET | `/api/v1/{hash}/professionalize/history` | Professionalize history |
| POST | `/api/v1/{hash}/define/process` | Define/simplify text |
| GET | `/api/v1/{hash}/define/history` | Define history |

## Make Commands

```bash
make dev          # Development with hot reload
make prod         # Production mode
make build        # Build Docker images
make down         # Stop containers
make logs         # View logs
make shell        # Shell into app container
make db-shell     # PostgreSQL shell
make test         # Run tests
make clean        # Clean cache
```

## Environment Variables

See `.env.example` for all options.

## Notes

- Access codes are **7 digits**, uppercase letters + numbers
- History routes use **MD5 hash** of the access code for URL privacy
- Feature implementations (LLM integration) are **stubs** — to be filled by team
