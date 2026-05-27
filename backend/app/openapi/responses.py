"""Reusable OpenAPI/Swagger response specs.

Compose into route decorators via `responses={**AUTH_RESPONSES, ...}` so error
contracts stay defined in one place and Swagger docs match the status codes
HTTPException subclasses in app.exceptions actually emit.
"""

AUTH_RESPONSES = {
    401: {"description": "Missing or invalid Bearer token."},
    403: {"description": "Account deactivated."},
}

LLM_RESPONSES = {
    **AUTH_RESPONSES,
    503: {"description": "LLM provider unavailable (retries exhausted)."},
}

NOT_FOUND_RESPONSE = {
    404: {"description": "Resource not found."},
}

SSE_RESPONSE = {
    200: {
        "description": "Server-Sent Events stream of LLMChunkDTO JSON payloads.",
        "content": {"text/event-stream": {}},
    },
}
