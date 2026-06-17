from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.config.database import get_db
from app.services.user_service import UserService
from app.dto.auth.auth import GenerateResponseDTO, LoginRequestDTO
from app.dto.auth.userdata import TokenResponseDTO
from app.openapi import AUTH_RESPONSES

TAG = {
    "name": "Authentication",
    "description": (
        "Account login. Accounts are created by admins — contact your administrator to get your 6-digit code."
    ),
}

router = APIRouter(prefix="/api/v1/auth", tags=[TAG["name"]])


def get_user_service(db: AsyncSession = Depends(get_db)) -> UserService:
    return UserService(db)


@router.post(
    "/generate",
    response_model=GenerateResponseDTO,
    status_code=status.HTTP_201_CREATED,
    include_in_schema=False,
)
async def generate(user_service: UserService = Depends(get_user_service)):
    return await user_service.generate()


@router.post(
    "/login",
    response_model=TokenResponseDTO,
    status_code=status.HTTP_200_OK,
    summary="Log in with account number",
    responses={
        200: {"description": "Login successful. Use the returned access_token as Bearer credential."},
        **AUTH_RESPONSES,
        401: {"description": "Invalid account number."},
    },
)
async def login(request: LoginRequestDTO, user_service: UserService = Depends(get_user_service)):
    """
    Log in using your 6-digit account number.

    Account numbers are issued by an administrator — you cannot self-register.
    Returns an access token and your user profile.
    """
    return await user_service.login(request.account_number)
