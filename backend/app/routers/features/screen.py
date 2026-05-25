from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.config.database import get_db
from app.dependencies import get_current_user
from app.dto.auth.userdata import UserResponseDTO
from app.dto.feature.chat.base import FeatureHistoryListDTO
from app.dto.feature.chat.enums import FeatureType
from app.dto.feature.screening import ScreeningResponseDTO, ScreeningReplyRequestDTO
from app.services.screening import ScreeningService
from app.services.feature_service import FeatureService
from app.exceptions import LLM_RESPONSES

router = APIRouter(prefix="/api/v1/me/screen", tags=["Screening"])


@router.post(
    "/start",
    response_model=ScreeningResponseDTO,
    status_code=status.HTTP_201_CREATED,
    summary="Begin a screening session",
    responses=LLM_RESPONSES,
)
async def start(
    db: AsyncSession = Depends(get_db),
    user: UserResponseDTO = Depends(get_current_user),
):
    """
    Open a new ARHQ screening session.

    No body required. The server creates a session and the LLM responds with a
    warm greeting plus the first question. Use the returned `session_id` for all
    subsequent `/reply` calls.
    """
    return await ScreeningService.start(user.user_id, db)


@router.post(
    "/reply",
    response_model=ScreeningResponseDTO,
    status_code=status.HTTP_200_OK,
    summary="Reply to current question",
    responses=LLM_RESPONSES,
)
async def reply(
    request: ScreeningReplyRequestDTO,
    db: AsyncSession = Depends(get_db),
    user: UserResponseDTO = Depends(get_current_user),
):
    """
    Submit the user's answer to the current screening question.

    Server tracks which ARHQ question is next based on conversation history.
    When all 23 topics have been covered, the response will set
    `is_complete: true` and include a warm summary in `result`.
    """
    return await ScreeningService.reply(request.text, request.session_id, user.user_id, db)


@router.get(
    "/history",
    response_model=FeatureHistoryListDTO,
    status_code=status.HTTP_200_OK,
    summary="List screening history",
    responses=LLM_RESPONSES,
)
async def history(
    db: AsyncSession = Depends(get_db),
    user: UserResponseDTO = Depends(get_current_user),
):
    """Return all screening history items for the current user, newest first."""
    return await FeatureService.get_history(FeatureType.SCREEN, user.user_id, db)
