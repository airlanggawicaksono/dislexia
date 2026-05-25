"""DTO-level unit tests for app/dto/feature/process/request.py."""

import pytest
from pydantic import ValidationError

from app.dto.feature.process import FeatureRequestDTO
from app.policies import MIN_INPUT_CHARS, MAX_INPUT_CHARS
from tests.fixtures.payloads import FEATURE_PROCESS_INVALID, FEATURE_PROCESS_VALID


@pytest.mark.parametrize("payload, case", FEATURE_PROCESS_INVALID, ids=[c[1] for c in FEATURE_PROCESS_INVALID])
def test_feature_dto_rejects(payload: dict, case: str):
    with pytest.raises(ValidationError):
        FeatureRequestDTO(**payload)


@pytest.mark.parametrize("payload, case", FEATURE_PROCESS_VALID, ids=[c[1] for c in FEATURE_PROCESS_VALID])
def test_feature_dto_accepts(payload: dict, case: str):
    dto = FeatureRequestDTO(**payload)
    assert MIN_INPUT_CHARS <= len(dto.text) <= MAX_INPUT_CHARS


def test_feature_dto_strips_whitespace():
    dto = FeatureRequestDTO(text="  hello  ")
    assert dto.text == "hello"
