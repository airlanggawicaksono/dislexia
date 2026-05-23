from typing import Optional
from uuid import UUID
from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.config.database import get_db
from app.dependencies import get_current_user
from app.dto.feature.chat.enums import FeatureType
from app.dto.feature.chat.base import FeatureHistoryItemDTO, FeatureHistoryListDTO
from app.services.chat_history_service import ChatHistoryService

router = APIRouter(prefix="/api/v1/admin", tags=["Admin"])


@router.get("/history", response_model=FeatureHistoryListDTO, status_code=status.HTTP_200_OK)
async def list_history(
    user: Optional[str] = None,
    feature: Optional[FeatureType] = None,
    db: AsyncSession = Depends(get_db),
    _current_user=Depends(get_current_user),
):
    return await ChatHistoryService.get_history_admin(user, feature, db)


@router.get("/history/{history_id}", response_model=FeatureHistoryItemDTO, status_code=status.HTTP_200_OK)
async def get_history_item(
    history_id: UUID,
    db: AsyncSession = Depends(get_db),
    _current_user=Depends(get_current_user),
):
    return await ChatHistoryService.get_history_item_admin(history_id, db)
