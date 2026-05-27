"""DTO-level unit tests for app/dto/auth/auth.py.

Truth layer for partial input handling. No HTTP, no DB — instantiate Pydantic
model and assert ValidationError raised for every bad case.
"""

import pytest
from pydantic import ValidationError

from app.dto.auth.auth import LoginRequestDTO
from tests.fixtures.payloads import LOGIN_INVALID, LOGIN_VALID


@pytest.mark.parametrize("payload, case", LOGIN_INVALID, ids=[c[1] for c in LOGIN_INVALID])
def test_login_dto_rejects(payload: dict, case: str):
    with pytest.raises(ValidationError):
        LoginRequestDTO(**payload)


@pytest.mark.parametrize("payload, case", LOGIN_VALID, ids=[c[1] for c in LOGIN_VALID])
def test_login_dto_accepts(payload: dict, case: str):
    dto = LoginRequestDTO(**payload)
    assert dto.account_number.isdigit()
    assert len(dto.account_number) == 16
