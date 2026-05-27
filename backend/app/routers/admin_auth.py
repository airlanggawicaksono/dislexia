from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.config.database import get_db
from app.dependencies import get_current_admin_allow_pw_change
from app.services.admin_service import AdminService
from app.dto.auth.admin import (
    AdminLoginRequestDTO,
    AdminChangePasswordRequestDTO,
    AdminResponseDTO,
    AdminTokenResponseDTO,
)
from app.openapi import AUTH_RESPONSES


TAG = {
    "name": "Admin Auth",
    "description": "Admin login + password rotation. Separate auth flow from end users.",
}

router = APIRouter(prefix="/api/v1/admin", tags=[TAG["name"]])


def _service(db: AsyncSession = Depends(get_db)) -> AdminService:
    return AdminService(db)


@router.post(
    "/login",
    response_model=AdminTokenResponseDTO,
    status_code=status.HTTP_200_OK,
    summary="Admin login",
    responses={401: {"description": "Invalid username or password."}, **AUTH_RESPONSES},
)
async def login(request: AdminLoginRequestDTO, service: AdminService = Depends(_service)):
    """Log in with admin username + password. Returns an admin-scoped JWT."""
    return await service.login(request.username, request.password)


@router.post(
    "/me/password",
    response_model=AdminResponseDTO,
    status_code=status.HTTP_200_OK,
    summary="Change admin password",
    responses=AUTH_RESPONSES,
)
async def change_password(
    request: AdminChangePasswordRequestDTO,
    service: AdminService = Depends(_service),
    admin: AdminResponseDTO = Depends(get_current_admin_allow_pw_change),
):
    """
    Rotate the current admin's password. Must be called on first login when
    `must_change_password=True` — all other admin endpoints reject until done.
    """
    return await service.change_password(admin.admin_id, request.current_password, request.new_password)
