from pydantic_settings import BaseSettings, SettingsConfigDict
from typing import List, Optional


class Settings(BaseSettings):
    """
    Application settings loaded from environment variables

    Reads from .env file automatically
    All configuration should be set in .env file, no hardcoded values
    """

    # Local dev reads .env.dev (gitignored, hand-edited values).
    # On the VPS, the container gets env vars from docker-compose directly
    # so the file lookup is just a no-op fallback.
    model_config = SettingsConfigDict(
        env_file=(".env.dev", ".env"),
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    # Application Configuration
    ENVIRONMENT: str = "development"
    APP_HOST: str = "0.0.0.0"
    APP_PORT: int = 8000
    APP_WORKERS: int = 4
    APP_RELOAD: bool = True

    # Database Configuration
    DB_USER: str = "dislexia"
    DB_PASSWORD: str = "dislexia_dev_password"
    DB_NAME: str = "dislexia_db"
    DB_HOST: str = "localhost"
    DB_PORT: int = 5432

    # Optional: Direct DATABASE_URL override (takes precedence if set)
    DATABASE_URL: Optional[str] = None

    # Database Connection Pool Settings
    DB_ECHO: bool = False
    DB_POOL_SIZE: int = 10
    DB_MAX_OVERFLOW: int = 20

    # Seed admin (auto-created on first boot if missing)
    SEED_ADMIN_USERNAME: str = "admin"
    SEED_ADMIN_PASSWORD: str = "12345678"

    # JWT Configuration
    JWT_SECRET_KEY: str = "your-secret-key-change-this-in-production"
    JWT_ALGORITHM: str = "HS256"
    JWT_ACCESS_TOKEN_EXPIRE_MINUTES: int = 30

    # Swagger / Docs Protection
    SWAGGER_DOCS_ENABLED: bool = True
    SWAGGER_USERNAME: str = "admin"
    SWAGGER_PASSWORD: str = "changeme"

    # CORS Configuration
    # Comma-separated list of allowed origins. Use ["*"] for development.
    CORS_ALLOW_ORIGINS: str = "https://reader.dyslexic.app,http://localhost:8083"
    CORS_ALLOW_CREDENTIALS: bool = True
    CORS_ALLOW_METHODS: str = "*"
    CORS_ALLOW_HEADERS: str = "*"
    CORS_EXPOSE_HEADERS: str = ""
    CORS_MAX_AGE: int = 600

    @property
    def cors_origins(self) -> List[str]:
        """Parse CORS_ALLOW_ORIGINS into a list (handles "*" sentinel)."""
        raw = (self.CORS_ALLOW_ORIGINS or "").strip()
        if not raw:
            return []
        if raw == "*":
            return ["*"]
        return [o.strip() for o in raw.split(",") if o.strip()]

    @property
    def cors_methods(self) -> List[str]:
        """Parse CORS_ALLOW_METHODS into a list (handles "*" sentinel)."""
        raw = (self.CORS_ALLOW_METHODS or "").strip()
        if not raw or raw == "*":
            return ["*"]
        return [m.strip().upper() for m in raw.split(",") if m.strip()]

    @property
    def cors_headers(self) -> List[str]:
        """Parse CORS_ALLOW_HEADERS into a list (handles "*" sentinel)."""
        raw = (self.CORS_ALLOW_HEADERS or "").strip()
        if not raw or raw == "*":
            return ["*"]
        return [h.strip() for h in raw.split(",") if h.strip()]

    @property
    def cors_expose_headers(self) -> List[str]:
        """Parse CORS_EXPOSE_HEADERS into a list."""
        raw = (self.CORS_EXPOSE_HEADERS or "").strip()
        if not raw:
            return []
        return [h.strip() for h in raw.split(",") if h.strip()]

    # LLM defaults
    LLM_PROVIDER: str = "together"

    # LLM API Keys + models
    OPENAI_API_KEY: Optional[str] = None
    OPENAI_MODEL: Optional[str] = None
    TOGETHER_API_KEY: Optional[str] = None
    TOGETHER_MODEL: Optional[str] = None
    ANTHROPIC_API_KEY: Optional[str] = None
    ANTHROPIC_MODEL: Optional[str] = None

    @property
    def database_url(self) -> str:
        """
        Construct async PostgreSQL database URL
        Uses DATABASE_URL if set, otherwise constructs from components
        """
        if self.DATABASE_URL:
            return self.DATABASE_URL
        return f"postgresql+asyncpg://{self.DB_USER}:{self.DB_PASSWORD}@{self.DB_HOST}:{self.DB_PORT}/{self.DB_NAME}"


# Singleton instance
settings = Settings()
