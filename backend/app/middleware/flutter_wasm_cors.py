from fastapi import Request
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.responses import Response


class FlutterWasmCorsMiddleware(BaseHTTPMiddleware):
    """Add Flutter WebAssembly CORS headers for multi-threaded rendering."""

    async def dispatch(self, request: Request, call_next):
        response: Response = await call_next(request)

        response.headers["Cross-Origin-Embedder-Policy"] = "credentialless"
        response.headers["Cross-Origin-Opener-Policy"] = "same-origin"

        return response