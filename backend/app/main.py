from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from contextlib import asynccontextmanager
from app.routers import auth
from app.routers.features import summarize, professionalize, define
from app.config.database import close_db, init_db
from app.policies.exceptions import LLMUnavailableError

# Import all models so they register with Base.metadata
from app.models import user, chat_session  # noqa: F401


@asynccontextmanager
async def lifespan(app: FastAPI):
    await init_db()
    yield
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


@app.exception_handler(LLMUnavailableError)
async def llm_unavailable_handler(request: Request, exc: LLMUnavailableError):
    return JSONResponse(status_code=503, content={"detail": str(exc)})


# Include routers
app.include_router(auth.router)
app.include_router(summarize.router)
app.include_router(professionalize.router)
app.include_router(define.router)


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
