"""OpenAPI / Swagger metadata. Pure dicts — no runtime behavior."""

from app.openapi.responses import (
    AUTH_RESPONSES,
    LLM_RESPONSES,
    NOT_FOUND_RESPONSE,
    SSE_RESPONSE,
)

__all__ = [
    "AUTH_RESPONSES",
    "LLM_RESPONSES",
    "NOT_FOUND_RESPONSE",
    "SSE_RESPONSE",
]
