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

router = APIRouter(prefix="/api/v1/me/professionalize", tags=["Professionalize"])

_PROMPT = (
    "You are a professional writing assistant. "
    "Rewrite the provided text in a formal, professional tone while preserving the original meaning."
)


@router.post(
    "/process",
    response_model=FeatureResponseDTO,
    status_code=status.HTTP_200_OK,
    summary="Rewrite text in professional tone",
    responses=LLM_RESPONSES,
)
async def process(
    request: FeatureRequestDTO,
    db: AsyncSession = Depends(get_db),
    user: UserResponseDTO = Depends(get_current_user),
):
    """
    Rewrite the provided text in a formal, professional tone.

    Pass `session_id` to continue a prior conversation; omit to start fresh.
    Preserves the original meaning.
    """
    return await FeatureService.process(FeatureType.PROFESSIONALIZE, _PROMPT, request.text, user.user_id, db, request.session_id)


@router.post(
    "/process-stream",
    summary="Professionalize text (SSE stream)",
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
        async for chunk in FeatureService.process_stream(FeatureType.PROFESSIONALIZE, _PROMPT, request.text, user.user_id, db, request.session_id):
            yield f"data: {chunk.model_dump_json()}\n\n"
    return StreamingResponse(sse(), media_type="text/event-stream")


@router.get(
    "/history",
    response_model=FeatureHistoryListDTO,
    status_code=status.HTTP_200_OK,
    summary="List professionalize history",
    responses=LLM_RESPONSES,
)
async def history(
    db: AsyncSession = Depends(get_db),
    user: UserResponseDTO = Depends(get_current_user),
):
    """Return all professionalize history items for the current user, newest first."""
    return await FeatureService.get_history(FeatureType.PROFESSIONALIZE, user.user_id, db)
