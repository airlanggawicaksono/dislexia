from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.config.database import get_db
from app.services.user_service import UserService
from app.dto.auth.auth import GenerateResponseDTO, LoginRequestDTO
from app.dto.auth.userdata import TokenResponseDTO

router = APIRouter(prefix="/api/v1/auth", tags=["Authentication"])


def get_user_service(db: AsyncSession = Depends(get_db)) -> UserService:
    return UserService(db)


@router.post("/generate", response_model=GenerateResponseDTO, status_code=status.HTTP_201_CREATED)
async def generate(user_service: UserService = Depends(get_user_service)):
    return await user_service.generate()


@router.post("/login", response_model=TokenResponseDTO, status_code=status.HTTP_200_OK)
async def login(request: LoginRequestDTO, user_service: UserService = Depends(get_user_service)):
    return await user_service.login(request.account_number)
