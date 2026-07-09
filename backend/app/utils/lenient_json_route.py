"""Lenient JSON request parsing.

Pasted text (the whole point of this app) routinely contains raw control
characters — TABs, newlines, form feeds. Strict JSON (the default) forbids
unescaped control characters inside string literals, so a body like
`{"text": "line1<TAB>line2"}` is rejected with:

    json_invalid: "Invalid control character at ..."

before the request ever reaches the endpoint. That is hostile to users who
copy text out of PDFs / editors.

Python's `json.loads(..., strict=False)` accepts those control characters
inside strings. FastAPI validates a JSON body by calling `await request.json()`,
so we override that on a custom Request and wire it in via a custom APIRoute.
Attach with `APIRouter(..., route_class=LenientJSONRoute)`.
"""

import json
from typing import Any, Callable

from fastapi import Request, Response
from fastapi.routing import APIRoute


class LenientRequest(Request):
    async def json(self) -> Any:
        if not hasattr(self, "_json"):
            body = await self.body()
            # strict=False → allow raw \t, \n, etc. inside JSON strings.
            self._json = json.loads(body, strict=False) if body else {}
        return self._json


class LenientJSONRoute(APIRoute):
    def get_route_handler(self) -> Callable:
        original_route_handler = super().get_route_handler()

        async def custom_route_handler(request: Request) -> Response:
            return await original_route_handler(
                LenientRequest(request.scope, request.receive)
            )

        return custom_route_handler
