from typing import Optional
from uuid import UUID
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.config.database import get_db
from app.dependencies import get_current_user
from app.dto.feature.chat.enums import FeatureType
from app.dto.feature.chat.base import FeatureHistoryItemDTO, FeatureHistoryListDTO
from app.services.chat_history_service import ChatHistoryService
from app.exceptions import AUTH_RESPONSES, NOT_FOUND_RESPONSE

router = APIRouter(prefix="/api/v1/admin", tags=["Admin"])


@router.get(
    "/history",
    response_model=FeatureHistoryListDTO,
    status_code=status.HTTP_200_OK,
    summary="Admin: list history with filters",
    responses=AUTH_RESPONSES,
)
async def list_history(
    user: Optional[str] = Query(None, description="MD5 hash of the target user's account_number. Omit to span all users."),
    feature: Optional[FeatureType] = Query(None, description="Filter by feature. Omit to span all features."),
    db: AsyncSession = Depends(get_db),
    _current_user=Depends(get_current_user),
):
    """
    List history across users with optional filters. Filters apply as WHERE clauses:
    - `user=<md5>` → one user's history (MD5 of their 16-digit account_number)
    - `feature=<name>` → one feature
    - both → intersection
    - neither → everything
    """
    return await ChatHistoryService.get_history_admin(user, feature, db)


@router.get(
    "/history/{history_id}",
    response_model=FeatureHistoryItemDTO,
    status_code=status.HTTP_200_OK,
    summary="Admin: get any history item",
    responses={**AUTH_RESPONSES, **NOT_FOUND_RESPONSE},
)
async def get_history_item(
    history_id: UUID,
    db: AsyncSession = Depends(get_db),
    _current_user=Depends(get_current_user),
):
    """Get a single history item by ID. No ownership check — admin can read any user's history."""
    return await ChatHistoryService.get_history_item_admin(history_id, db)
