from typing import Optional
from uuid import UUID
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.config.database import get_db
from app.dependencies import get_current_admin
from app.dto.feature.chat.enums import FeatureType
from app.dto.feature.chat.base import FeatureHistoryItemDTO, FeatureHistoryListDTO
from app.dto.auth.admin import AdminResponseDTO, AdminCreateResponseDTO, AdminListDTO
from app.dto.admin import UserAdminListDTO
from app.dto.admin.users import AdminCreateUserResponseDTO
from app.services.chat_history_service import ChatHistoryService
from app.services.admin_service import AdminService
from app.openapi import AUTH_RESPONSES, NOT_FOUND_RESPONSE


TAG = {
    "name": "Admin",
    "description": "Admin-only endpoints. Requires an admin-scoped JWT.",
}

router = APIRouter(prefix="/api/v1/admin", tags=[TAG["name"]])


@router.get(
    "/admins",
    response_model=AdminListDTO,
    status_code=status.HTTP_200_OK,
    summary="List all admins",
    responses=AUTH_RESPONSES,
)
async def list_admins(
    db: AsyncSession = Depends(get_db),
    _admin: AdminResponseDTO = Depends(get_current_admin),
):
    """List all admin accounts, newest first."""
    return await AdminService(db).list_admins()


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


@router.post(
    "/users",
    response_model=AdminCreateUserResponseDTO,
    status_code=status.HTTP_201_CREATED,
    summary="Create a user account",
    responses=AUTH_RESPONSES,
)
async def create_user(
    db: AsyncSession = Depends(get_db),
    _admin: AdminResponseDTO = Depends(get_current_admin),
):
    """
    Create a new end-user account. Returns the 6-digit `account_number` — this is the
    user's only login credential. Share it with them out-of-band. It cannot be retrieved again.
    """
    return await AdminService(db).create_user()


@router.delete(
    "/users/{user_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete a user account",
    responses={**AUTH_RESPONSES, **NOT_FOUND_RESPONSE},
)
async def delete_user(
    user_id: UUID,
    db: AsyncSession = Depends(get_db),
    _admin: AdminResponseDTO = Depends(get_current_admin),
):
    """
    Permanently delete a user account and all their history/sessions.
    This action is irreversible.
    """
    await AdminService(db).delete_user(user_id)


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
    account_number is intentionally redacted. Use `account_md5` to filter history endpoints.
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
    - `user=<md5>` → one user's history (MD5 of their 6-digit account_number)
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
