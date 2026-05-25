from typing import Optional
from uuid import UUID
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.config.database import get_db
from app.dependencies import get_current_user
from app.dto.auth.userdata import UserResponseDTO
from app.dto.feature.chat.enums import FeatureType
from app.dto.feature.chat.base import FeatureHistoryItemDTO, FeatureHistoryListDTO
from app.services.chat_history_service import ChatHistoryService
from app.exceptions import AUTH_RESPONSES, NOT_FOUND_RESPONSE

router = APIRouter(prefix="/api/v1/me", tags=["Me"])


@router.get(
    "/history",
    response_model=FeatureHistoryListDTO,
    status_code=status.HTTP_200_OK,
    summary="List current user's history",
    responses=AUTH_RESPONSES,
)
async def list_history(
    feature: Optional[FeatureType] = Query(None, description="Filter by feature. Omit to return all features."),
    db: AsyncSession = Depends(get_db),
    user: UserResponseDTO = Depends(get_current_user),
):
    """Return history items for the authenticated user, newest first. Optional `feature` query param filters by feature."""
    return await ChatHistoryService.get_history_filtered(user.user_id, feature, db)


@router.get(
    "/history/{history_id}",
    response_model=FeatureHistoryItemDTO,
    status_code=status.HTTP_200_OK,
    summary="Get a history item",
    responses={**AUTH_RESPONSES, **NOT_FOUND_RESPONSE},
)
async def get_history_item(
    history_id: UUID,
    db: AsyncSession = Depends(get_db),
    user: UserResponseDTO = Depends(get_current_user),
):
    """Get a single history item by ID. Returns 403 if the item belongs to another user."""
    return await ChatHistoryService.get_history_item_owned(history_id, user.user_id, db)
