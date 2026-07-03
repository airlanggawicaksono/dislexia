"""ARHQ post-processing package.

Layout mirrors the rest of the codebase:
    - scoring rubric constants live in `app/policies/ahrq.py`
    - status enum + response DTOs live in `app/dto/feature/screening/`
    - HTTP errors (ConflictError, ...) come from `app/exceptions/`

Local modules here are the service + its pure helpers:
    service.py  — PostProcessService (static methods, uses ChatHistoryService)
    parser.py   — PostProcessError + parse_llm_response (defensive)
    result.py   — metadata builders + resolve_status (pure)
"""

from app.services.screening.postprocess.parser import (
    PostProcessError,
    parse_llm_response,
)
from app.services.screening.postprocess.result import (
    build_failure_metadata,
    build_success_metadata,
    resolve_status,
)
from app.services.screening.postprocess.service import PostProcessService

__all__ = [
    "PostProcessService",
    "PostProcessError",
    "parse_llm_response",
    "build_failure_metadata",
    "build_success_metadata",
    "resolve_status",
]
