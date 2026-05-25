from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.config.database import get_db
from app.services.user_service import UserService
from app.dto.auth.auth import GenerateResponseDTO, LoginRequestDTO
from app.dto.auth.userdata import TokenResponseDTO
from app.exceptions import AUTH_RESPONSES

router = APIRouter(prefix="/api/v1/auth", tags=["Authentication"])


def get_user_service(db: AsyncSession = Depends(get_db)) -> UserService:
    return UserService(db)


@router.post(
    "/generate",
    response_model=GenerateResponseDTO,
    status_code=status.HTTP_201_CREATED,
    summary="Generate new account",
    responses={
        201: {"description": "Account created. Save the account_number — it is the only way to log back in."},
    },
)
async def generate(user_service: UserService = Depends(get_user_service)):
    """
    Create a new account.

    Returns a randomly generated 16-digit `account_number` plus an access token.
    **No email or password is required.** Save the account number — it is the
    only credential for this account.
    """
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
    Log in using a 16-digit account number.

    Returns an access token and the current user profile.
    """
    return await user_service.login(request.account_number)
