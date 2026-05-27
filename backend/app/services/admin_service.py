import hashlib
import secrets
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.exceptions import UnauthorizedError, ForbiddenError, NotFoundError
from app.models.admin import Admin
from app.models.user import User
from app.utils.jwt_utils import JWTManager
from app.utils.password_utils import hash_password, verify_password, generate_temp_password
from app.dto.auth.admin import (
    AdminResponseDTO,
    AdminTokenResponseDTO,
    AdminCreateResponseDTO,
)
from app.dto.admin.users import UserAdminItemDTO, UserAdminListDTO


_ROLE = "admin"


def _to_admin_dto(admin: Admin) -> AdminResponseDTO:
    return AdminResponseDTO(
        admin_id=admin.admin_id,
        username=admin.username,
        must_change_password=admin.must_change_password,
        is_active=admin.is_active,
        created_at=admin.created_at,
        last_login=admin.last_login,
    )


async def _username_taken(username: str, db: AsyncSession) -> bool:
    result = await db.execute(select(Admin).where(Admin.username == username))
    return result.scalar_one_or_none() is not None


def _make_admin_username() -> str:
    return f"admin-{secrets.token_hex(4)}"


async def _unique_admin_username(db: AsyncSession) -> str:
    for _ in range(8):
        candidate = _make_admin_username()
        if not await _username_taken(candidate, db):
            return candidate
    raise RuntimeError("Could not generate unique admin username after 8 attempts")


class AdminService:
    def __init__(self, db: AsyncSession, jwt_manager: JWTManager | None = None):
        self.db = db
        self.jwt_manager = jwt_manager or JWTManager()

    async def login(self, username: str, password: str) -> AdminTokenResponseDTO:
        result = await self.db.execute(select(Admin).where(Admin.username == username))
        admin = result.scalar_one_or_none()
        if admin is None or not verify_password(password, admin.password_hash):
            raise UnauthorizedError("Invalid username or password")
        if not admin.is_active:
            raise ForbiddenError("Admin account deactivated")

        admin.update_last_login()
        await self.db.commit()

        token = self.jwt_manager.create_access_token(subject_id=admin.admin_id, role=_ROLE)
        return AdminTokenResponseDTO(
            access_token=token,
            expires_in=self.jwt_manager.get_token_expiration(),
            admin=_to_admin_dto(admin),
        )

    async def verify_token(self, token: str) -> AdminResponseDTO:
        payload = self.jwt_manager.verify_token(token)
        if not payload or payload.get("role") != _ROLE:
            raise UnauthorizedError("Invalid or non-admin token")

        result = await self.db.execute(select(Admin).where(Admin.admin_id == UUID(payload["sub"])))
        admin = result.scalar_one_or_none()
        if admin is None:
            raise NotFoundError("Admin not found")
        if not admin.is_active:
            raise ForbiddenError("Admin account deactivated")

        return _to_admin_dto(admin)

    async def create_admin(self, creator_id: UUID) -> AdminCreateResponseDTO:
        username = await _unique_admin_username(self.db)
        temp_password = generate_temp_password()
        admin = Admin(
            username=username,
            password_hash=hash_password(temp_password),
            must_change_password=True,
            created_by=creator_id,
        )
        self.db.add(admin)
        await self.db.commit()
        await self.db.refresh(admin)
        return AdminCreateResponseDTO(
            admin_id=admin.admin_id,
            username=admin.username,
            temporary_password=temp_password,
        )

    async def list_users(self) -> UserAdminListDTO:
        result = await self.db.execute(select(User).order_by(User.created_at.desc()))
        users = result.scalars().all()
        items = [
            UserAdminItemDTO(
                user_id=u.user_id,
                display_name=u.display_name,
                account_md5=hashlib.md5(u.account_number.encode()).hexdigest(),
                is_active=u.is_active,
                created_at=u.created_at,
                last_login=u.last_login,
            )
            for u in users
        ]
        return UserAdminListDTO(items=items, total=len(items))

    async def change_password(self, admin_id: UUID, current_password: str, new_password: str) -> AdminResponseDTO:
        result = await self.db.execute(select(Admin).where(Admin.admin_id == admin_id))
        admin = result.scalar_one_or_none()
        if admin is None:
            raise NotFoundError("Admin not found")
        if not verify_password(current_password, admin.password_hash):
            raise UnauthorizedError("Current password is incorrect")

        admin.password_hash = hash_password(new_password)
        admin.must_change_password = False
        await self.db.commit()
        await self.db.refresh(admin)
        return _to_admin_dto(admin)
