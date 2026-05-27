"""HTTP exception classes. Raise these in services/routers — FastAPI maps
each to its declared status_code automatically. No custom handler needed."""

from fastapi import HTTPException, status


class LLMUnavailableError(HTTPException):
    def __init__(self, detail: str = "LLM provider unavailable"):
        super().__init__(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail=detail)


class LLMEmptyResponseError(HTTPException):
    """Provider returned 2xx but no usable content (bad model id, content filter, etc.)."""
    def __init__(self, detail: str = "LLM returned an empty response"):
        super().__init__(status_code=status.HTTP_502_BAD_GATEWAY, detail=detail)


class NotFoundError(HTTPException):
    def __init__(self, detail: str = "Resource not found"):
        super().__init__(status_code=status.HTTP_404_NOT_FOUND, detail=detail)


class UnauthorizedError(HTTPException):
    def __init__(self, detail: str = "Not authenticated"):
        super().__init__(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=detail,
            headers={"WWW-Authenticate": "Bearer"},
        )


class ForbiddenError(HTTPException):
    def __init__(self, detail: str = "Forbidden"):
        super().__init__(status_code=status.HTTP_403_FORBIDDEN, detail=detail)
