from fastapi import APIRouter, Depends, status
from fastapi.responses import StreamingResponse
from sqlalchemy.ext.asyncio import AsyncSession

from app.config.database import get_db
from app.dependencies import get_current_user
from app.services.feature_service import FeatureService
from app.services.prompts import DYSLEXIA_OUTPUT_RULES
from app.dto.feature.chat.enums import FeatureType
from app.dto.feature.chat.base import FeatureHistoryListDTO
from app.dto.feature.process import SummarizeRequestDTO, FeatureResponseDTO, SummaryLevel
from app.dto.feature.llm import LLMGenerationConfigDTO
from app.dto.auth.userdata import UserResponseDTO
from app.openapi import LLM_RESPONSES, SSE_RESPONSE

TAG = {
    "name": "Summarize",
    "description": "Summarize long text into clear, accessible prose for dyslexic readers.",
}

router = APIRouter(prefix="/api/v1/me/summarize", tags=[TAG["name"]])

_BASE_PROMPT = (
    "You are a reading assistant for people with dyslexia. "
    "Summarize the provided text into clear, concise prose using simple, accessible language. "
    "Do not use bullet points, numbered lists, or any list formatting. "
    "Write flowing sentences and short paragraphs only.\n\n"
    f"{DYSLEXIA_OUTPUT_RULES}"
)

_LEVEL_CONFIG: dict[SummaryLevel, tuple[str, int]] = {
    SummaryLevel.SHORT: (
        "Write a very brief summary in 2-3 sentences maximum. Capture only the single most important idea.",
        200,
    ),
    SummaryLevel.MODERATE: (
        "Write a moderate-length summary covering the key points.",
        500,
    ),
    SummaryLevel.DETAILED: (
        "Write a comprehensive summary covering all important details and nuances.",
        1000,
    ),
}


def _build_prompt_and_config(level: SummaryLevel) -> tuple[str, LLMGenerationConfigDTO]:
    instruction, max_tokens = _LEVEL_CONFIG[level]
    prompt = (
        "You are a reading assistant for people with dyslexia. "
        f"{instruction} "
        "Use simple, accessible language. "
        "Do not use bullet points, numbered lists, or any list formatting. "
        "Write flowing sentences and short paragraphs only.\n\n"
        f"{DYSLEXIA_OUTPUT_RULES}"
    )
    return prompt, LLMGenerationConfigDTO(max_tokens=max_tokens)


@router.post(
    "/process",
    response_model=FeatureResponseDTO,
    status_code=status.HTTP_200_OK,
    summary="Summarize text",
    responses=LLM_RESPONSES,
)
async def process(
    request: SummarizeRequestDTO,
    db: AsyncSession = Depends(get_db),
    user: UserResponseDTO = Depends(get_current_user),
):
    """
    Summarize the provided text into accessible prose.

    Use `level` to control output length:
    - `short` — 2-3 sentences, single key idea
    - `moderate` — key points (default)
    - `detailed` — comprehensive coverage

    Pass `session_id` to continue a prior conversation; omit to start fresh.
    """
    prompt, config = _build_prompt_and_config(request.level)
    return await FeatureService.process(
        FeatureType.SUMMARIZE, prompt, request.text, user.user_id, db, request.session_id, config
    )


@router.post(
    "/process-stream",
    summary="Summarize text (SSE stream)",
    responses={**SSE_RESPONSE, **LLM_RESPONSES},
)
async def process_stream(
    request: SummarizeRequestDTO,
    db: AsyncSession = Depends(get_db),
    user: UserResponseDTO = Depends(get_current_user),
):
    """
    Streaming variant of `/process`. Returns Server-Sent Events.

    Each event payload is a JSON-encoded `LLMChunkDTO`. The full response is
    persisted to history after the stream completes.
    """
    prompt, config = _build_prompt_and_config(request.level)

    async def sse():
        async for chunk in FeatureService.process_stream(
            FeatureType.SUMMARIZE, prompt, request.text, user.user_id, db, request.session_id, config
        ):
            yield f"data: {chunk.model_dump_json()}\n\n"

    return StreamingResponse(sse(), media_type="text/event-stream")


@router.get(
    "/history",
    response_model=FeatureHistoryListDTO,
    status_code=status.HTTP_200_OK,
    summary="List summarize history",
    responses=LLM_RESPONSES,
)
async def history(
    db: AsyncSession = Depends(get_db),
    user: UserResponseDTO = Depends(get_current_user),
):
    """Return all summarize history items for the current user, newest first."""
    return await FeatureService.get_history(FeatureType.SUMMARIZE, user.user_id, db)
