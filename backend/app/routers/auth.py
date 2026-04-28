from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession
from app.services.user_service import UserService
from app.dto.auth.userdata import TokenResponseDTO
from app.dto.auth.auth import SignupRequestDTO, SignupResponseDTO, LoginRequestDTO
from app.config.database import get_db

router = APIRouter(prefix="/api/v1/auth", tags=["Authentication"])


def get_user_service(db: AsyncSession = Depends(get_db)) -> UserService:
    """Dependency injection for UserService with DB session"""
    return UserService(db)


@router.post(
    "/signup", response_model=SignupResponseDTO, status_code=status.HTTP_201_CREATED
)
async def signup(
    request: SignupRequestDTO, user_service: UserService = Depends(get_user_service)
):
    """
    User signup - Create new account with email

    Creates a new user account with an auto-generated username
    and a 7-digit access code. The access code is returned and should be used
    for login to get a JWT token.
    """
    return await user_service.signup(request.email)


@router.post("/login", response_model=TokenResponseDTO, status_code=status.HTTP_200_OK)
async def login(
    request: LoginRequestDTO, user_service: UserService = Depends(get_user_service)
):
    """
    User login with 7-digit access code

    Authenticates user using the 7-digit access code received during signup.
    Returns a JWT token that should be used for all subsequent API calls.
    """
    return await user_service.login(request.access_code)
