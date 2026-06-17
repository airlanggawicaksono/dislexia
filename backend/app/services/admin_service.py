import hashlib
import secrets
from uuid import UUID

from sqlalchemy import select, delete
from sqlalchemy.ext.asyncio import AsyncSession

from app.exceptions import UnauthorizedError, ForbiddenError, NotFoundError
from app.models.admin import Admin
from app.models.user import User
from app.models.chat_session import ChatSession, FeatureHistory
from app.utils.jwt_utils import JWTManager
from app.utils.password_utils import hash_password, verify_password, generate_temp_password
from app.dto.auth.admin import (
    AdminResponseDTO,
    AdminTokenResponseDTO,
    AdminCreateResponseDTO,
    AdminListItemDTO,
    AdminListDTO,
)
from app.dto.admin.users import UserAdminItemDTO, UserAdminListDTO, AdminCreateUserResponseDTO


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

    async def create_user(self) -> AdminCreateUserResponseDTO:
        user = User()
        self.db.add(user)
        await self.db.commit()
        await self.db.refresh(user)
        return AdminCreateUserResponseDTO(
            user_id=user.user_id,
            account_number=user.account_number,
            display_name=user.display_name,
        )

    async def delete_user(self, user_id: UUID) -> None:
        result = await self.db.execute(select(User).where(User.user_id == user_id))
        user = result.scalar_one_or_none()
        if user is None:
            raise NotFoundError("User not found")

        # Delete child records in FK order before removing the user row.
        sessions = await self.db.execute(
            select(ChatSession.session_id).where(ChatSession.user_id == user_id)
        )
        session_ids = [r[0] for r in sessions.fetchall()]

        await self.db.execute(delete(FeatureHistory).where(FeatureHistory.user_id == user_id))
        if session_ids:
            await self.db.execute(delete(ChatSession).where(ChatSession.session_id.in_(session_ids)))
        await self.db.delete(user)
        await self.db.commit()

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

    async def list_admins(self) -> AdminListDTO:
        result = await self.db.execute(select(Admin).order_by(Admin.created_at.desc()))
        admins = result.scalars().all()
        items = [
            AdminListItemDTO(
                admin_id=a.admin_id,
                username=a.username,
                is_active=a.is_active,
                must_change_password=a.must_change_password,
                created_at=a.created_at,
                last_login=a.last_login,
            )
            for a in admins
        ]
        return AdminListDTO(items=items, total=len(items))

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
