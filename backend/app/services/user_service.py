from uuid import UUID
from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user import User
from app.utils.jwt_utils import JWTManager
from app.dto.auth.userdata import UserResponseDTO, TokenResponseDTO
from app.dto.auth.auth import GenerateResponseDTO


def _to_user_dto(user: User) -> UserResponseDTO:
    return UserResponseDTO(
        user_id=user.user_id,
        account_number=user.account_number,
        created_at=user.created_at,
        last_login=user.last_login,
        is_active=user.is_active,
    )


class UserService:
    def __init__(self, db: AsyncSession, jwt_manager: JWTManager | None = None):
        self.db = db
        self.jwt_manager = jwt_manager or JWTManager()

    async def generate(self) -> GenerateResponseDTO:
        user = User()
        self.db.add(user)
        await self.db.commit()
        await self.db.refresh(user)

        token = self.jwt_manager.create_access_token(user_id=user.user_id)
        return GenerateResponseDTO(
            account_number=user.account_number,
            access_token=token,
            expires_in=self.jwt_manager.get_token_expiration(),
        )

    async def login(self, account_number: str) -> TokenResponseDTO:
        result = await self.db.execute(select(User).where(User.account_number == account_number))
        user = result.scalar_one_or_none()

        if not user:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid account number")

        if not user.is_active:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Account deactivated")

        user.update_last_login()
        await self.db.commit()

        return TokenResponseDTO(
            access_token=self.jwt_manager.create_access_token(user_id=user.user_id),
            expires_in=self.jwt_manager.get_token_expiration(),
            user=_to_user_dto(user),
        )

    async def verify_token(self, token: str) -> UserResponseDTO:
        payload = self.jwt_manager.verify_token(token)
        if not payload:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid or expired token")

        result = await self.db.execute(select(User).where(User.user_id == UUID(payload["sub"])))
        user = result.scalar_one_or_none()

        if not user:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

        if not user.is_active:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Account deactivated")

        return _to_user_dto(user)

    async def deactivate(self, user_id: UUID) -> dict[str, str]:
        result = await self.db.execute(select(User).where(User.user_id == user_id))
        user = result.scalar_one_or_none()

        if not user:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

        user.deactivate()
        await self.db.commit()
        return {"message": "Account deactivated"}
