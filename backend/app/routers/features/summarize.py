from fastapi import APIRouter, Depends, status
from fastapi.responses import StreamingResponse
from sqlalchemy.ext.asyncio import AsyncSession

from app.config.database import get_db
from app.dependencies import get_current_user
from app.services.feature_service import FeatureService
from app.services.prompts import DYSLEXIA_OUTPUT_RULES
from app.dto.feature.chat.enums import FeatureType
from app.dto.feature.chat.base import FeatureHistoryListDTO
from app.dto.feature.process import FeatureRequestDTO, FeatureResponseDTO
from app.dto.auth.userdata import UserResponseDTO
from app.openapi import LLM_RESPONSES, SSE_RESPONSE

TAG = {
    "name": "Summarize",
    "description": "Summarize long text into clear, accessible bullet points for dyslexic readers.",
}

router = APIRouter(prefix="/api/v1/me/summarize", tags=[TAG["name"]])

_PROMPT = (
    "You are a reading assistant for people with dyslexia. "
    "Summarize the provided text into clear, concise prose using simple, accessible language. "
    "Do not use bullet points, numbered lists, or any list formatting. "
    "Write flowing sentences and short paragraphs only.\n\n"
    f"{DYSLEXIA_OUTPUT_RULES}"
)


@router.post(
    "/process",
    response_model=FeatureResponseDTO,
    status_code=status.HTTP_200_OK,
    summary="Summarize text",
    responses=LLM_RESPONSES,
)
async def process(
    request: FeatureRequestDTO,
    db: AsyncSession = Depends(get_db),
    user: UserResponseDTO = Depends(get_current_user),
):
    """
    Summarize the provided text into accessible bullet points.

    Pass `session_id` to continue a prior conversation; omit it to start fresh.
    Response includes the result, the session_id (save for continuation), and
    a history_id for later retrieval.
    """
    return await FeatureService.process(FeatureType.SUMMARIZE, _PROMPT, request.text, user.user_id, db, request.session_id)


@router.post(
    "/process-stream",
    summary="Summarize text (SSE stream)",
    responses={**SSE_RESPONSE, **LLM_RESPONSES},
)
async def process_stream(
    request: FeatureRequestDTO,
    db: AsyncSession = Depends(get_db),
    user: UserResponseDTO = Depends(get_current_user),
):
    """
    Streaming variant of `/process`. Returns Server-Sent Events.

    Each event payload is a JSON-encoded `LLMChunkDTO`. The full response is
    persisted to history after the stream completes.
    """
    async def sse():
        async for chunk in FeatureService.process_stream(FeatureType.SUMMARIZE, _PROMPT, request.text, user.user_id, db, request.session_id):
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
