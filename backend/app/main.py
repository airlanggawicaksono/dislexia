import secrets as _secrets
from contextlib import asynccontextmanager

from fastapi import Depends, FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.openapi.docs import get_redoc_html, get_swagger_ui_html
from fastapi.security import HTTPBasic, HTTPBasicCredentials

from app.config.database import async_session_maker, close_db, init_db
from app.config.settings import settings
from app.scripts.seed_admin import ensure_seed_admin
from app.middleware.flutter_wasm_cors import FlutterWasmCorsMiddleware
from app.routers import auth, admin, admin_auth
from app.routers.features import summarize, professionalize, define, me, screen

# Register models with Base.metadata
from app.models import user, chat_session, admin as admin_model  # noqa: F401

_http_basic = HTTPBasic()


def _verify_docs_credentials(
    credentials: HTTPBasicCredentials = Depends(_http_basic),
) -> str:
    """HTTP Basic Auth guard for Swagger / ReDoc endpoints."""
    ok_user = _secrets.compare_digest(
        credentials.username.encode(), settings.SWAGGER_USERNAME.encode()
    )
    ok_pass = _secrets.compare_digest(
        credentials.password.encode(), settings.SWAGGER_PASSWORD.encode()
    )
    if not (ok_user and ok_pass):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid credentials",
            headers={"WWW-Authenticate": "Basic"},
        )
    return credentials.username


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
    # docs_url / redoc_url disabled here — custom password-protected routes below
    docs_url=None,
    redoc_url=None,
    openapi_url="/openapi.json",
    openapi_tags=tags_metadata,
    lifespan=lifespan,
)

# CORS — must be added BEFORE any route so Access-Control-* headers appear on
# every response (including OPTIONS preflights and the custom /docs, /redoc routes).
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=settings.CORS_ALLOW_CREDENTIALS,
    allow_methods=settings.cors_methods,
    allow_headers=settings.cors_headers,
    expose_headers=settings.cors_expose_headers,
    max_age=settings.CORS_MAX_AGE,
)

# Flutter WASM — add headers for multi-threaded rendering support
app.add_middleware(FlutterWasmCorsMiddleware)

if settings.SWAGGER_DOCS_ENABLED:

    @app.get("/docs", include_in_schema=False)
    async def swagger_ui(
        _username: str = Depends(_verify_docs_credentials),
    ):
        """Swagger UI — protected by HTTP Basic Auth."""
        return get_swagger_ui_html(
            openapi_url="/openapi.json",
            title=f"{app.title} – Swagger UI",
        )

    @app.get("/redoc", include_in_schema=False)
    async def redoc_ui(
        _username: str = Depends(_verify_docs_credentials),
    ):
        """ReDoc UI — protected by HTTP Basic Auth."""
        return get_redoc_html(
            openapi_url="/openapi.json",
            title=f"{app.title} – ReDoc",
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
