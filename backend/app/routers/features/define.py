from fastapi import APIRouter, Depends, status
from fastapi.responses import StreamingResponse
from sqlalchemy.ext.asyncio import AsyncSession

from app.config.database import get_db
from app.dependencies import get_current_user
from app.services.feature_service import FeatureService
from app.services.prompts import DYSLEXIA_OUTPUT_RULES
from app.dto.feature.chat.enums import FeatureType
from app.dto.feature.chat.base import FeatureHistoryListDTO
from app.dto.feature.process import DefineRequestDTO, FeatureResponseDTO, DefineLevel
from app.dto.auth.userdata import UserResponseDTO
from app.openapi import LLM_RESPONSES, SSE_RESPONSE
from app.utils.lenient_json_route import LenientJSONRoute

TAG = {
    "name": "Define",
    "description": "Define a word or concept using simple vocabulary and short sentences.",
}

router = APIRouter(prefix="/api/v1/me/define", tags=[TAG["name"]], route_class=LenientJSONRoute)

# Which explanation layers to include, per level. Cumulative: higher tiers add
# depth. Ordered so lower tiers drop the deepest layers first (mirrors the
# importance-ordering used by summarize).
_LEVEL_LAYERS: dict[DefineLevel, str] = {
    DefineLevel.PCT_10: "ONLY the CORE MEANING — a single plain sentence saying what it is.",
    DefineLevel.PCT_30: "the CORE MEANING, then ONE simple real-world EXAMPLE.",
    DefineLevel.PCT_50: (
        "the CORE MEANING, an EXAMPLE, AND how/when it is USED "
        "(context and part of speech)."
    ),
    DefineLevel.PCT_70: (
        "the CORE MEANING, an EXAMPLE, its USAGE, AND RELATED WORDS "
        "(synonyms and what it is NOT — key distinctions)."
    ),
    DefineLevel.PCT_90: (
        "ALL layers — CORE MEANING, EXAMPLE, USAGE, RELATED WORDS, "
        "AND NUANCE (etymology and common confusions)."
    ),
}


def _build_prompt(level: DefineLevel) -> str:
    layers = _LEVEL_LAYERS[level]
    return (
        "You are a dictionary assistant for people with dyslexia. "
        "Provide a clear, simple definition of the given word or concept using "
        "short sentences and plain vocabulary.\n\n"
        f"For THIS definition include {layers} Stop after the last included layer.\n\n"
        f"{DYSLEXIA_OUTPUT_RULES}"
    )


@router.post(
    "/process",
    response_model=FeatureResponseDTO,
    status_code=status.HTTP_200_OK,
    summary="Define a word or concept",
    responses=LLM_RESPONSES,
)
async def process(
    request: DefineRequestDTO,
    db: AsyncSession = Depends(get_db),
    user: UserResponseDTO = Depends(get_current_user),
):
    """
    Return a clear, simple definition of the given word or concept.

    Use `level` to control explanation DEPTH (cumulative layers, not length):
    - `10pct` — core meaning only
    - `30pct` — + a simple example
    - `50pct` — + how/when it's used (default)
    - `70pct` — + related words and distinctions
    - `90pct` — + nuance and etymology

    Pass `session_id` to continue a prior conversation; omit to start fresh.
    Uses short sentences and plain vocabulary.
    """
    metadata = {"level": request.level.value}
    return await FeatureService.process(
        FeatureType.DEFINE, _build_prompt(request.level), request.text, user.user_id, db, request.session_id, metadata=metadata
    )


@router.post(
    "/process-stream",
    summary="Define (SSE stream)",
    responses={**SSE_RESPONSE, **LLM_RESPONSES},
)
async def process_stream(
    request: DefineRequestDTO,
    db: AsyncSession = Depends(get_db),
    user: UserResponseDTO = Depends(get_current_user),
):
    """
    Streaming variant of `/process`. Returns Server-Sent Events of `LLMChunkDTO`.
    Full response is persisted to history after the stream completes.
    """
    prompt = _build_prompt(request.level)
    metadata = {"level": request.level.value}

    async def sse():
        async for chunk in FeatureService.process_stream(FeatureType.DEFINE, prompt, request.text, user.user_id, db, request.session_id, metadata=metadata):
            yield f"data: {chunk.model_dump_json()}\n\n"
    return StreamingResponse(sse(), media_type="text/event-stream")


@router.get(
    "/history",
    response_model=FeatureHistoryListDTO,
    status_code=status.HTTP_200_OK,
    summary="List define history",
    responses=LLM_RESPONSES,
)
async def history(
    db: AsyncSession = Depends(get_db),
    user: UserResponseDTO = Depends(get_current_user),
):
    """Return all define history items for the current user, newest first."""
    return await FeatureService.get_history(FeatureType.DEFINE, user.user_id, db)
