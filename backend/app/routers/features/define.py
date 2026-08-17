from fastapi import APIRouter, Depends, status
from fastapi.responses import StreamingResponse
from sqlalchemy.ext.asyncio import AsyncSession

from app.config.database import get_db
from app.dependencies import get_current_user
from app.services.feature_service import FeatureService
from app.services.prompts import DYSLEXIA_OUTPUT_RULES, language_directive
from app.dto.feature.chat.enums import FeatureType
from app.dto.feature.chat.base import FeatureHistoryListDTO
from app.dto.feature.process import DefineRequestDTO, DefineLevel
from app.dto.auth.userdata import UserResponseDTO
from app.openapi import LLM_RESPONSES, SSE_RESPONSE
from app.utils.lenient_json_route import LenientJSONRoute

TAG = {
    "name": "Define",
    "description": "Define a word or concept using simple vocabulary and short sentences.",
}

router = APIRouter(prefix="/api/v1/me/define", tags=[TAG["name"]], route_class=LenientJSONRoute)

# Which explanation layers to include, per level. Cumulative: higher tiers add
# depth. Ordered so lower tiers drop the deepest layers first.
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
        "WORD ORIGIN (etymology), AND COMMON CONFUSIONS (words often mixed up with it)."
    ),
}


def _build_prompt(level: DefineLevel, output_language: str) -> str:
    layers = _LEVEL_LAYERS[level]
    return (
        "You are a dictionary assistant for people with dyslexia. "
        "Provide a clear, simple definition of the given word or concept using "
        "short sentences and plain vocabulary.\n\n"
        f"{language_directive(output_language)}\n"
        f"If the input word is a foreign word (not in {output_language}), provide its direct translation first.\n\n"
        "PRONUNCIATION: Always start your response by showing the word broken into syllables in parentheses "
        "(e.g., ap-ple or in-for-ma-tion) to demonstrate pronunciation.\n\n"
        f"For THIS definition include {layers} Stop immediately after the last included layer.\n\n"
        f"{DYSLEXIA_OUTPUT_RULES}"
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
    """
    output_lang = request.output_language.value
    prompt = _build_prompt(request.level, output_lang)
    metadata = {"level": request.level.value, "language": output_lang}

    async def sse():
        async for chunk in FeatureService.process_stream(
            FeatureType.DEFINE, prompt, request.text, user.user_id, db, request.session_id, metadata=metadata
        ):
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