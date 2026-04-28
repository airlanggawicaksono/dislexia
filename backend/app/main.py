from fastapi import FastAPI
from contextlib import asynccontextmanager
from app.routers import auth
from app.routers import summarize, professionalize
from app.config.database import close_db, init_db

# Import all models so they register with Base.metadata
from app.models import user  # noqa: F401


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Lifespan context manager for startup/shutdown events
    """
    # Startup: create tables
    await init_db()
    yield

    # Shutdown
    await close_db()


app = FastAPI(
    title="Dislexia API",
    description="FastAPI backend for Dislexia Reader",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json",
    lifespan=lifespan,
)

# Include routers
app.include_router(auth.router)
app.include_router(summarize.router)
app.include_router(professionalize.router)


@app.get("/", tags=["Health"])
async def root():
    """Health check endpoint"""
    return {
        "status": "ok",
        "message": "Dislexia API is running",
        "docs": "/docs",
        "redoc": "/redoc",
    }


@app.get("/health", tags=["Health"])
async def health():
    """Detailed health check"""
    return {"status": "healthy", "version": "1.0.0"}
