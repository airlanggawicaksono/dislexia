"""HTTP exception classes only. For OpenAPI response specs see app.openapi."""

from app.exceptions.http import (
    LLMUnavailableError,
    LLMEmptyResponseError,
    NotFoundError,
    UnauthorizedError,
    ForbiddenError,
    ConflictError,
)

__all__ = [
    "LLMUnavailableError",
    "LLMEmptyResponseError",
    "NotFoundError",
    "UnauthorizedError",
    "ForbiddenError",
    "ConflictError",
]
