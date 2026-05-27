from fastapi import FastAPI
from contextlib import asynccontextmanager

from app.config.database import async_session_maker, close_db, init_db
from app.scripts.seed_admin import ensure_seed_admin
from app.routers import auth, admin, admin_auth
from app.routers.features import summarize, professionalize, define, me, screen

# Register models with Base.metadata
from app.models import user, chat_session, admin as admin_model  # noqa: F401


HEALTH_TAG = {
    "name": "Health",
    "description": "Service liveness and readiness probes.",
}

tags_metadata = [
    HEALTH_TAG,
    auth.TAG,
    summarize.TAG,
    professionalize.TAG,
    define.TAG,
    screen.TAG,
    me.TAG,
    admin_auth.TAG,
    admin.TAG,
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
    async with async_session_maker() as db:
        await ensure_seed_admin(db)
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

app.include_router(auth.router)
app.include_router(summarize.router)
app.include_router(professionalize.router)
app.include_router(define.router)
app.include_router(me.router)
app.include_router(screen.router)
app.include_router(admin_auth.router)
app.include_router(admin.router)


@app.get("/", tags=[HEALTH_TAG["name"]], summary="Root health check")
async def root():
    """Returns basic service status and links to docs."""
    return {
        "status": "ok",
        "message": "Dislexia API is running",
        "docs": "/docs",
        "redoc": "/redoc",
    }


@app.get("/health", tags=[HEALTH_TAG["name"]], summary="Detailed health check")
async def health():
    """Returns service health and version. Use for liveness probes."""
    return {"status": "healthy", "version": "1.0.0"}
