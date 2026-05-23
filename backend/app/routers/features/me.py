from typing import Optional
from uuid import UUID
from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.config.database import get_db
from app.dependencies import get_current_user
from app.dto.auth.userdata import UserResponseDTO
from app.dto.feature.chat.enums import FeatureType
from app.dto.feature.chat.base import FeatureHistoryItemDTO, FeatureHistoryListDTO
from app.services.chat_history_service import ChatHistoryService

router = APIRouter(prefix="/api/v1/me", tags=["Me"])


@router.get("/history", response_model=FeatureHistoryListDTO, status_code=status.HTTP_200_OK)
async def list_history(
    feature: Optional[FeatureType] = None,
    db: AsyncSession = Depends(get_db),
    user: UserResponseDTO = Depends(get_current_user),
):
    return await ChatHistoryService.get_history_filtered(user.user_id, feature, db)


@router.get("/history/{history_id}", response_model=FeatureHistoryItemDTO, status_code=status.HTTP_200_OK)
async def get_history_item(
    history_id: UUID,
    db: AsyncSession = Depends(get_db),
    user: UserResponseDTO = Depends(get_current_user),
):
    return await ChatHistoryService.get_history_item_owned(history_id, user.user_id, db)
