from typing import Optional
from uuid import UUID
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.config.database import get_db
from app.dependencies import get_current_admin
from app.dto.feature.chat.enums import FeatureType
from app.dto.feature.chat.base import FeatureHistoryItemDTO, FeatureHistoryListDTO
from app.dto.auth.admin import AdminResponseDTO, AdminCreateResponseDTO
from app.dto.admin import UserAdminListDTO
from app.services.chat_history_service import ChatHistoryService
from app.services.admin_service import AdminService
from app.openapi import AUTH_RESPONSES, NOT_FOUND_RESPONSE


TAG = {
    "name": "Admin",
    "description": "Admin-only endpoints. Requires an admin-scoped JWT.",
}

router = APIRouter(prefix="/api/v1/admin", tags=[TAG["name"]])


@router.post(
    "/admins",
    response_model=AdminCreateResponseDTO,
    status_code=status.HTTP_201_CREATED,
    summary="Invite a new admin",
    responses=AUTH_RESPONSES,
)
async def create_admin(
    db: AsyncSession = Depends(get_db),
    current: AdminResponseDTO = Depends(get_current_admin),
):
    """
    Provision a new admin account. Server generates a random petname username + a
    one-time temporary password. Returned ONCE in the response and cannot be
    recovered — record them now. The new admin must change the password on first login.
    """
    return await AdminService(db).create_admin(current.admin_id)


@router.get(
    "/users",
    response_model=UserAdminListDTO,
    status_code=status.HTTP_200_OK,
    summary="List all end users",
    responses=AUTH_RESPONSES,
)
async def list_users(
    db: AsyncSession = Depends(get_db),
    _admin: AdminResponseDTO = Depends(get_current_admin),
):
    """
    List every end user. Each row exposes display_name + MD5(account_number) — the raw
    account_number is intentionally redacted so admins can't see Mullvad credentials.
    Use the returned `account_md5` to filter history endpoints.
    """
    return await AdminService(db).list_users()


@router.get(
    "/history",
    response_model=FeatureHistoryListDTO,
    status_code=status.HTTP_200_OK,
    summary="List history across all users",
    responses=AUTH_RESPONSES,
)
async def list_history(
    user: Optional[str] = Query(None, description="MD5 hash of the target user's account_number. Omit to span all users."),
    feature: Optional[FeatureType] = Query(None, description="Filter by feature. Omit to span all features."),
    db: AsyncSession = Depends(get_db),
    _admin: AdminResponseDTO = Depends(get_current_admin),
):
    """
    List history across users with optional filters:
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
    summary="Get any history item by id",
    responses={**AUTH_RESPONSES, **NOT_FOUND_RESPONSE},
)
async def get_history_item(
    history_id: UUID,
    db: AsyncSession = Depends(get_db),
    _admin: AdminResponseDTO = Depends(get_current_admin),
):
    """Look up a single history item by id. No ownership check — admin reads any user's row."""
    return await ChatHistoryService.get_history_item_admin(history_id, db)
