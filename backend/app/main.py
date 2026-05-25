from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from contextlib import asynccontextmanager
from app.routers import auth, admin
from app.routers.features import summarize, professionalize, define, me, screen
from app.config.database import close_db, init_db
from app.exceptions import LLMUnavailableError

# Import all models so they register with Base.metadata
from app.models import user, chat_session  # noqa: F401


tags_metadata = [
    {
        "name": "Health",
        "description": "Service liveness and readiness probes.",
    },
    {
        "name": "Authentication",
        "description": (
            "Mullvad-style account auth. No email, no password. "
            "Generate a 16-digit account number, log in with it, receive a JWT."
        ),
    },
    {
        "name": "Summarize",
        "description": "Summarize long text into clear, accessible bullet points for dyslexic readers.",
    },
    {
        "name": "Professionalize",
        "description": "Rewrite casual text in a formal, professional tone while preserving meaning.",
    },
    {
        "name": "Define",
        "description": "Define a word or concept using simple vocabulary and short sentences.",
    },
    {
        "name": "Screening",
        "description": (
            "Multi-turn dyslexia screening based on the Adult Reading History Questionnaire (ARHQ). "
            "Server controls the 23-question sequence; the LLM rephrases each one warmly."
        ),
    },
    {
        "name": "Me",
        "description": "Per-user history endpoints. Requires JWT.",
    },
    {
        "name": "Admin",
        "description": "Admin history lookup across users. Filters by MD5(account_number) and feature.",
    },
]


description = """
# Dislexia API

FastAPI backend for the **Dislexia Reader** — a reading-assistance app for people with dyslexia.

## Auth
All `/api/v1/me/*`, `/api/v1/admin/*`, and feature endpoints require a `Bearer` JWT
obtained via `POST /api/v1/auth/login`.

## Features
- **Summarize / Professionalize / Define** — single-turn LLM transformations
- **Screening** — multi-turn ARHQ conversation, server-controlled question sequence
- **History** — per-user and admin lookup of past feature usage
"""


@asynccontextmanager
async def lifespan(app: FastAPI):
    await init_db()
    yield
    await close_db()


app = FastAPI(
    title="Dislexia API",
    description=description,
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json",
    openapi_tags=tags_metadata,
    lifespan=lifespan,
)


@app.exception_handler(LLMUnavailableError)
async def llm_unavailable_handler(request: Request, exc: LLMUnavailableError):
    return JSONResponse(status_code=503, content={"detail": str(exc)})


# Include routers
app.include_router(auth.router)
app.include_router(summarize.router)
app.include_router(professionalize.router)
app.include_router(define.router)
app.include_router(me.router)
app.include_router(screen.router)
app.include_router(admin.router)


@app.get("/", tags=["Health"], summary="Root health check")
async def root():
    """Returns basic service status and links to docs."""
    return {
        "status": "ok",
        "message": "Dislexia API is running",
        "docs": "/docs",
        "redoc": "/redoc",
    }


@app.get("/health", tags=["Health"], summary="Detailed health check")
async def health():
    """Returns service health and version. Use for liveness probes."""
    return {"status": "healthy", "version": "1.0.0"}
