"""DTO-level unit tests for app/dto/auth/admin.py."""

import pytest
from pydantic import ValidationError

from app.dto.auth.admin import AdminLoginRequestDTO, AdminChangePasswordRequestDTO
from tests.fixtures.payloads import (
    ADMIN_LOGIN_INVALID,
    ADMIN_LOGIN_VALID,
    ADMIN_CHANGE_PASSWORD_INVALID,
    ADMIN_CHANGE_PASSWORD_VALID,
)


@pytest.mark.parametrize("payload, case", ADMIN_LOGIN_INVALID, ids=[c[1] for c in ADMIN_LOGIN_INVALID])
def test_admin_login_dto_rejects(payload: dict, case: str):
    with pytest.raises(ValidationError):
        AdminLoginRequestDTO(**payload)


@pytest.mark.parametrize("payload, case", ADMIN_LOGIN_VALID, ids=[c[1] for c in ADMIN_LOGIN_VALID])
def test_admin_login_dto_accepts(payload: dict, case: str):
    dto = AdminLoginRequestDTO(**payload)
    assert 3 <= len(dto.username) <= 64
    assert 8 <= len(dto.password) <= 128


def test_admin_login_dto_strips_whitespace():
    dto = AdminLoginRequestDTO(username="  admin  ", password="  12345678  ")
    assert dto.username == "admin"
    assert dto.password == "12345678"


@pytest.mark.parametrize("payload, case", ADMIN_CHANGE_PASSWORD_INVALID, ids=[c[1] for c in ADMIN_CHANGE_PASSWORD_INVALID])
def test_admin_change_password_dto_rejects(payload: dict, case: str):
    with pytest.raises(ValidationError):
        AdminChangePasswordRequestDTO(**payload)


@pytest.mark.parametrize("payload, case", ADMIN_CHANGE_PASSWORD_VALID, ids=[c[1] for c in ADMIN_CHANGE_PASSWORD_VALID])
def test_admin_change_password_dto_accepts(payload: dict, case: str):
    dto = AdminChangePasswordRequestDTO(**payload)
    assert len(dto.current_password) >= 1
    assert 8 <= len(dto.new_password) <= 128
