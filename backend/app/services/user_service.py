from uuid import UUID
from fastapi import HTTPException, status
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.user import User
from app.utils.jwt_utils import JWTManager
from app.utils.username_generator import UsernameGenerator
from app.utils.access_code_generator import AccessCodeGenerator
from app.dto.auth.userdata import UserResponseDTO, TokenResponseDTO
from app.dto.auth.auth import SignupResponseDTO


class UserService:
    """User service for 7-digit access code authentication"""

    def __init__(
        self,
        db: AsyncSession,
        jwt_manager: JWTManager | None = None,
        username_generator: UsernameGenerator | None = None,
        access_code_generator: AccessCodeGenerator | None = None,
    ):
        self.db = db
        self.jwt_manager = jwt_manager or JWTManager()
        self.username_generator = username_generator or UsernameGenerator()
        self.access_code_generator = access_code_generator or AccessCodeGenerator()

    async def signup(self, email: str) -> SignupResponseDTO:
        """User signup - creates new user with email"""
        result = await self.db.execute(select(User).where(User.email == email))
        existing_user = result.scalar_one_or_none()

        if existing_user:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Email {email} is already registered",
            )

        user = User(
            email=email,
            username_generator=self.username_generator,
            access_code_generator=self.access_code_generator,
        )

        self.db.add(user)
        await self.db.commit()
        await self.db.refresh(user)

        return SignupResponseDTO(
            access_code=user.access_code,
            email=user.email,
            username=user.username,
            message="Signup successful! Use your 7-digit access code to login.",
        )

    async def login(self, access_code: str) -> TokenResponseDTO:
        """User login with 7-digit access code"""
        result = await self.db.execute(
            select(User).where(User.access_code == access_code)
        )
        user = result.scalar_one_or_none()

        if not user:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid access code"
            )

        if not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="User account is deactivated",
            )

        user.update_last_login()
        await self.db.commit()

        jwt_token = self.jwt_manager.create_access_token(
            user_id=user.user_id, username=user.username
        )

        user_dto = UserResponseDTO(
            user_id=user.user_id,
            email=user.email,
            username=user.username,
            created_at=user.created_at,
            last_login=user.last_login,
            is_active=user.is_active,
        )

        return TokenResponseDTO(
            access_token=jwt_token,
            token_type="bearer",
            expires_in=self.jwt_manager.get_token_expiration(),
            user=user_dto,
        )

    async def verify_token(self, token: str) -> UserResponseDTO:
        """Verify JWT token and return user info"""
        payload = self.jwt_manager.verify_token(token)
        if not payload:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid or expired token",
            )

        user_id = UUID(payload["sub"])

        result = await self.db.execute(select(User).where(User.user_id == user_id))
        user = result.scalar_one_or_none()

        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail="User not found"
            )

        if not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="User account is deactivated",
            )

        return UserResponseDTO(
            user_id=user.user_id,
            email=user.email,
            username=user.username,
            created_at=user.created_at,
            last_login=user.last_login,
            is_active=user.is_active,
        )

    async def get_user_by_id(self, user_id: UUID) -> UserResponseDTO:
        """Get user by ID"""
        result = await self.db.execute(select(User).where(User.user_id == user_id))
        user = result.scalar_one_or_none()

        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"User with ID {user_id} not found",
            )

        return UserResponseDTO(
            user_id=user.user_id,
            email=user.email,
            username=user.username,
            created_at=user.created_at,
            last_login=user.last_login,
            is_active=user.is_active,
        )

    async def deactivate_user(self, user_id: UUID) -> dict[str, str]:
        """Deactivate user account"""
        result = await self.db.execute(select(User).where(User.user_id == user_id))
        user = result.scalar_one_or_none()

        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"User with ID {user_id} not found",
            )

        user.deactivate()
        await self.db.commit()

        return {"message": "User deactivated successfully"}

    async def get_total_users(self) -> int:
        """Get total number of users"""
        result = await self.db.execute(select(func.count(User.user_id)))
        return result.scalar_one()
