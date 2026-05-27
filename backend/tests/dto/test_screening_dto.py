"""DTO-level unit tests for app/dto/feature/screening/request.py."""

import pytest
from pydantic import ValidationError

from app.dto.feature.screening import ScreeningReplyRequestDTO
from app.policies import MIN_INPUT_CHARS, MAX_INPUT_CHARS
from tests.fixtures.payloads import SCREENING_REPLY_INVALID, SCREENING_REPLY_VALID


@pytest.mark.parametrize("payload, case", SCREENING_REPLY_INVALID, ids=[c[1] for c in SCREENING_REPLY_INVALID])
def test_screening_reply_dto_rejects(payload: dict, case: str):
    with pytest.raises(ValidationError):
        ScreeningReplyRequestDTO(**payload)


@pytest.mark.parametrize("payload, case", SCREENING_REPLY_VALID, ids=[c[1] for c in SCREENING_REPLY_VALID])
def test_screening_reply_dto_accepts(payload: dict, case: str):
    dto = ScreeningReplyRequestDTO(**payload)
    assert MIN_INPUT_CHARS <= len(dto.text) <= MAX_INPUT_CHARS
    assert dto.session_id is not None


def test_screening_reply_dto_strips_whitespace():
    from uuid import uuid4
    dto = ScreeningReplyRequestDTO(text="  yes  ", session_id=str(uuid4()))
    assert dto.text == "yes"
