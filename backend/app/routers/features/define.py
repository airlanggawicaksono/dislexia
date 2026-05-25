from fastapi import APIRouter, Depends, status
from fastapi.responses import StreamingResponse
from sqlalchemy.ext.asyncio import AsyncSession

from app.config.database import get_db
from app.dependencies import get_current_user
from app.services.feature_service import FeatureService
from app.dto.feature.chat.enums import FeatureType
from app.dto.feature.chat.base import FeatureHistoryListDTO
from app.dto.feature.process import FeatureRequestDTO, FeatureResponseDTO
from app.dto.auth.userdata import UserResponseDTO
from app.exceptions import LLM_RESPONSES, SSE_RESPONSE

router = APIRouter(prefix="/api/v1/me/define", tags=["Define"])

_PROMPT = (
    "You are a dictionary assistant for people with dyslexia. "
    "Provide a clear, simple definition of the given word or concept using short sentences and plain vocabulary."
)


@router.post(
    "/process",
    response_model=FeatureResponseDTO,
    status_code=status.HTTP_200_OK,
    summary="Define a word or concept",
    responses=LLM_RESPONSES,
)
async def process(
    request: FeatureRequestDTO,
    db: AsyncSession = Depends(get_db),
    user: UserResponseDTO = Depends(get_current_user),
):
    """
    Return a clear, simple definition of the given word or concept.

    Pass `session_id` to continue a prior conversation; omit to start fresh.
    Uses short sentences and plain vocabulary.
    """
    return await FeatureService.process(FeatureType.DEFINE, _PROMPT, request.text, user.user_id, db, request.session_id)


@router.post(
    "/process-stream",
    summary="Define (SSE stream)",
    responses={**SSE_RESPONSE, **LLM_RESPONSES},
)
async def process_stream(
    request: FeatureRequestDTO,
    db: AsyncSession = Depends(get_db),
    user: UserResponseDTO = Depends(get_current_user),
):
    """
    Streaming variant of `/process`. Returns Server-Sent Events of `LLMChunkDTO`.
    Full response is persisted to history after the stream completes.
    """
    async def sse():
        async for chunk in FeatureService.process_stream(FeatureType.DEFINE, _PROMPT, request.text, user.user_id, db, request.session_id):
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
