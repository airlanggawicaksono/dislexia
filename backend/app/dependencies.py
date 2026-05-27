from fastapi import Depends, Security
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.ext.asyncio import AsyncSession

from app.config.database import get_db
from app.exceptions import ForbiddenError
from app.services.user_service import UserService
from app.services.admin_service import AdminService
from app.dto.auth.userdata import UserResponseDTO
from app.dto.auth.admin import AdminResponseDTO

security = HTTPBearer()


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Security(security),
    db: AsyncSession = Depends(get_db),
) -> UserResponseDTO:
    return await UserService(db).verify_token(credentials.credentials)


async def get_current_admin(
    credentials: HTTPAuthorizationCredentials = Security(security),
    db: AsyncSession = Depends(get_db),
) -> AdminResponseDTO:
    admin = await AdminService(db).verify_token(credentials.credentials)
    if admin.must_change_password:
        raise ForbiddenError(
            "Password change required before using admin endpoints. "
            "Call POST /api/v1/admin/me/password first."
        )
    return admin


async def get_current_admin_allow_pw_change(
    credentials: HTTPAuthorizationCredentials = Security(security),
    db: AsyncSession = Depends(get_db),
) -> AdminResponseDTO:
    """Same as get_current_admin but tolerates must_change_password.
    Used ONLY by the password-change endpoint itself."""
    return await AdminService(db).verify_token(credentials.credentials)
