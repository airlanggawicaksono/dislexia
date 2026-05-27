"""Service-level unit tests for AdminService.

Pure unit tests: AsyncSession mocked, bcrypt + JWT real (cheap, deterministic).
Tests business logic, branch coverage, error paths — no DB, no FastAPI.
"""

from datetime import datetime, timezone
from unittest.mock import AsyncMock, MagicMock
from uuid import uuid4

import pytest

from app.exceptions import UnauthorizedError, ForbiddenError, NotFoundError
from app.models.admin import Admin
from app.models.user import User
from app.services.admin_service import AdminService
from app.utils.password_utils import hash_password


def _make_admin(
    username: str = "admin",
    password: str = "12345678",
    must_change_password: bool = False,
    is_active: bool = True,
) -> Admin:
    admin = Admin(
        username=username,
        password_hash=hash_password(password),
        must_change_password=must_change_password,
    )
    admin.admin_id = uuid4()
    admin.is_active = is_active
    admin.created_at = datetime.now(timezone.utc)
    admin.last_login = None
    admin.created_by = None
    return admin


def _scalar_returning(value):
    result = MagicMock()
    result.scalar_one_or_none.return_value = value
    return result


def _mock_db_returning(value) -> AsyncMock:
    db = AsyncMock()
    db.execute.return_value = _scalar_returning(value)
    return db


# ─── login ────────────────────────────────────────────────────────────────────
@pytest.mark.asyncio
async def test_login_success_returns_token_and_role():
    admin = _make_admin()
    db = _mock_db_returning(admin)
    service = AdminService(db)

    res = await service.login("admin", "12345678")

    assert res.access_token
    assert res.admin.username == "admin"
    assert res.admin.admin_id == admin.admin_id


@pytest.mark.asyncio
async def test_login_wrong_password_raises_401():
    admin = _make_admin()
    db = _mock_db_returning(admin)
    service = AdminService(db)

    with pytest.raises(UnauthorizedError):
        await service.login("admin", "wrong-password")


@pytest.mark.asyncio
async def test_login_unknown_user_raises_401():
    db = _mock_db_returning(None)
    service = AdminService(db)

    with pytest.raises(UnauthorizedError):
        await service.login("ghost", "anything-strong-enough")


@pytest.mark.asyncio
async def test_login_inactive_admin_raises_403():
    admin = _make_admin(is_active=False)
    db = _mock_db_returning(admin)
    service = AdminService(db)

    with pytest.raises(ForbiddenError):
        await service.login("admin", "12345678")


# ─── verify_token ─────────────────────────────────────────────────────────────
@pytest.mark.asyncio
async def test_verify_token_rejects_user_role():
    admin = _make_admin()
    db = _mock_db_returning(admin)
    service = AdminService(db)
    user_token = service.jwt_manager.create_access_token(subject_id=uuid4(), role="user")

    with pytest.raises(UnauthorizedError):
        await service.verify_token(user_token)


@pytest.mark.asyncio
async def test_verify_token_rejects_malformed():
    db = _mock_db_returning(None)
    service = AdminService(db)

    with pytest.raises(UnauthorizedError):
        await service.verify_token("not.a.real.jwt")


@pytest.mark.asyncio
async def test_verify_token_404_when_admin_deleted():
    db = _mock_db_returning(None)
    service = AdminService(db)
    orphan_token = service.jwt_manager.create_access_token(subject_id=uuid4(), role="admin")

    with pytest.raises(NotFoundError):
        await service.verify_token(orphan_token)


# ─── change_password ──────────────────────────────────────────────────────────
@pytest.mark.asyncio
async def test_change_password_success_clears_force_flag():
    admin = _make_admin(must_change_password=True)
    db = _mock_db_returning(admin)
    service = AdminService(db)

    res = await service.change_password(admin.admin_id, "12345678", "NewPasswordOk1")

    assert res.must_change_password is False
    assert admin.password_hash != hash_password("12345678")


@pytest.mark.asyncio
async def test_change_password_wrong_current_raises_401():
    admin = _make_admin()
    db = _mock_db_returning(admin)
    service = AdminService(db)

    with pytest.raises(UnauthorizedError):
        await service.change_password(admin.admin_id, "wrong-current", "NewPasswordOk1")


@pytest.mark.asyncio
async def test_change_password_unknown_admin_raises_404():
    db = _mock_db_returning(None)
    service = AdminService(db)

    with pytest.raises(NotFoundError):
        await service.change_password(uuid4(), "old", "NewPasswordOk1")


# ─── list_users ───────────────────────────────────────────────────────────────
@pytest.mark.asyncio
async def test_list_users_returns_md5_not_raw_account_number():
    users = [
        User(account_number="1" * 16, display_name="amusing-bee"),
        User(account_number="9" * 16, display_name="quiet-otter"),
    ]
    for u in users:
        u.user_id = uuid4()
        u.is_active = True
        u.created_at = datetime.now(timezone.utc)
        u.last_login = None

    db = AsyncMock()
    scalars = MagicMock()
    scalars.all.return_value = users
    result = MagicMock()
    result.scalars.return_value = scalars
    db.execute.return_value = result
    service = AdminService(db)

    res = await service.list_users()

    assert res.total == 2
    assert {item.display_name for item in res.items} == {"amusing-bee", "quiet-otter"}
    for item in res.items:
        assert len(item.account_md5) == 32  # MD5 hex digest
        assert "1" * 16 not in item.account_md5
        assert "9" * 16 not in item.account_md5


# ─── create_admin ─────────────────────────────────────────────────────────────
@pytest.mark.asyncio
async def test_create_admin_returns_username_and_temp_password():
    """Username collision check returns 'no existing' for every candidate → first attempt wins."""
    db = AsyncMock()
    db.execute.return_value = _scalar_returning(None)
    service = AdminService(db)

    res = await service.create_admin(creator_id=uuid4())

    assert res.username.startswith("admin-")
    assert len(res.username) == len("admin-") + 8  # 8 hex chars
    assert len(res.temporary_password) >= 12
    assert db.add.called
    assert db.commit.called
