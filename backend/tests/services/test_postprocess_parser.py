"""Unit tests for the ARHQ post-process pure helpers.

Covers the defensive parser (`parse_llm_response`), the metadata builders +
status derivation (`result.py`), and the scoring policy (`policies/ahrq.py`).
All pure — no async, no DB, no LLM.
"""

import json
from datetime import datetime, timezone

import pytest

from app.policies import (
    SCORE_MIN,
    SCORE_MAX,
    MIN_TOTAL,
    MAX_TOTAL,
    OPTION_WEIGHTS,
    classify_severity,
    score_option,
    score_total,
)
from app.services.screening.prompts import QUESTIONS
from app.services.screening.postprocess.parser import (
    PostProcessError,
    parse_llm_response,
)
from app.services.screening.postprocess.result import (
    build_failure_metadata,
    build_success_metadata,
    resolve_status,
)
from app.dto.feature.screening.enums import PostProcessStatus

_N = len(QUESTIONS)


def _valid_payload(score: int = 1, comment: str = "ok") -> dict:
    return {"scores": [score] * _N, "comments": [comment] * _N}


def _valid_json(score: int = 1, comment: str = "ok") -> str:
    return json.dumps(_valid_payload(score, comment))


# ─── parser: happy paths + salvage ──────────────────────────────────────────

def test_parses_clean_json():
    scores, comments = parse_llm_response(_valid_json())
    assert scores == [1] * _N
    assert comments == ["ok"] * _N


def test_salvages_markdown_fenced_json():
    raw = f"```json\n{_valid_json()}\n```"
    scores, comments = parse_llm_response(raw)
    assert len(scores) == _N


def test_salvages_prose_wrapped_json():
    raw = f"Sure! Here is the result:\n{_valid_json()}\nHope that helps."
    scores, _ = parse_llm_response(raw)
    assert len(scores) == _N


def test_tolerates_trailing_commas():
    body = json.dumps(_valid_payload())
    raw = body[:-1] + ",}"  # inject trailing comma before final brace
    scores, _ = parse_llm_response(raw)
    assert len(scores) == _N


def test_tolerates_single_quotes():
    raw = _valid_json().replace('"', "'")
    scores, _ = parse_llm_response(raw)
    assert len(scores) == _N


def test_coerces_string_ints():
    payload = {"scores": ["2"] * _N, "comments": ["ok"] * _N}
    scores, _ = parse_llm_response(json.dumps(payload))
    assert scores == [2] * _N


def test_sanitizes_comma_in_comment_instead_of_failing():
    payload = {"scores": [1] * _N, "comments": ["slow, careful reader"] * _N}
    scores, comments = parse_llm_response(json.dumps(payload))
    assert len(scores) == _N
    assert "," not in comments[0]
    assert ";" in comments[0]


def test_collapses_whitespace_in_comments():
    payload = {"scores": [1] * _N, "comments": ["multi   line\n\tcomment"] * _N}
    _, comments = parse_llm_response(json.dumps(payload))
    assert comments[0] == "multi line comment"


# ─── parser: failure reasons ────────────────────────────────────────────────

@pytest.mark.parametrize(
    "raw, expected_reason",
    [
        ("", "empty_response"),
        ("   \n\t ", "empty_response"),
        ("Error: rate limit exceeded", "llm_refused_or_api_error"),
        ("I cannot help with that request.", "llm_refused_or_api_error"),
        ("I'm unable to score this.", "llm_refused_or_api_error"),
        ('{"error": "context_length_exceeded"}', "llm_refused_or_api_error"),
        ("just some prose with no json", "malformed_json"),
        ("{ this is not : valid json ]", "malformed_json"),
    ],
)
def test_failure_reasons(raw: str, expected_reason: str):
    with pytest.raises(PostProcessError) as exc:
        parse_llm_response(raw)
    assert exc.value.reason == expected_reason


def test_wrong_length_scores():
    payload = {"scores": [1, 2, 3], "comments": ["ok"] * _N}
    with pytest.raises(PostProcessError) as exc:
        parse_llm_response(json.dumps(payload))
    assert exc.value.reason == "wrong_length"


def test_score_out_of_range_high():
    payload = {"scores": [SCORE_MAX + 1] * _N, "comments": ["ok"] * _N}
    with pytest.raises(PostProcessError) as exc:
        parse_llm_response(json.dumps(payload))
    assert exc.value.reason == "score_out_of_range"


def test_score_out_of_range_negative():
    payload = {"scores": [SCORE_MIN - 1] * _N, "comments": ["ok"] * _N}
    with pytest.raises(PostProcessError) as exc:
        parse_llm_response(json.dumps(payload))
    assert exc.value.reason == "score_out_of_range"


def test_scores_not_array():
    payload = {"scores": "nope", "comments": ["ok"] * _N}
    with pytest.raises(PostProcessError) as exc:
        parse_llm_response(json.dumps(payload))
    assert exc.value.reason == "schema_mismatch"


def test_bool_score_rejected():
    # bool is an int subclass — must NOT be accepted as a score.
    payload = {"scores": [True] * _N, "comments": ["ok"] * _N}
    with pytest.raises(PostProcessError) as exc:
        parse_llm_response(json.dumps(payload))
    assert exc.value.reason == "schema_mismatch"


def test_non_string_comment_rejected():
    payload = {"scores": [1] * _N, "comments": [123] * _N}
    with pytest.raises(PostProcessError) as exc:
        parse_llm_response(json.dumps(payload))
    assert exc.value.reason == "schema_mismatch"


def test_error_message_is_truncated():
    raw = "Error: " + "x" * 500
    with pytest.raises(PostProcessError) as exc:
        parse_llm_response(raw)
    assert len(exc.value.message) <= 200


# ─── result: metadata builders ──────────────────────────────────────────────

def _ts() -> tuple[datetime, datetime]:
    a = datetime(2026, 7, 3, 12, 0, 0, tzinfo=timezone.utc)
    b = datetime(2026, 7, 3, 12, 0, 12, tzinfo=timezone.utc)
    return a, b


def test_build_success_metadata_shape():
    started, finished = _ts()
    scores = [2] * _N  # column-2 chosen for every question
    comments = ["ok"] * _N
    md = build_success_metadata(scores, comments, started_at=started, finished_at=finished)

    assert md["ahrq_status"] == "success"
    assert md["ahrq_scores"] == scores
    assert md["ahrq_comments"] == ",".join(comments)
    # Total is WEIGHTED (from OPTION_WEIGHTS), not a plain sum of column indices.
    assert md["ahrq_total"] == score_total(scores)
    assert md["ahrq_total"] != sum(scores)  # weights actually applied
    assert md["ahrq_max_total"] == MAX_TOTAL
    assert md["ahrq_severity"] == classify_severity(score_total(scores))
    assert md["ahrq_disclaimer"] and md["ahrq_attribution"]  # always present
    assert md["ahrq_error"] is None
    assert md["ahrq_started_at"] == started.isoformat()
    assert md["ahrq_finished_at"] == finished.isoformat()


def test_build_failure_metadata_shape():
    started, finished = _ts()
    md = build_failure_metadata("malformed_json", "boom", started_at=started, finished_at=finished)

    assert md["ahrq_status"] == "failed"
    assert md["ahrq_error"] == {"reason": "malformed_json", "message": "boom"}
    assert md["ahrq_scores"] is None
    assert md["ahrq_total"] is None
    assert md["ahrq_severity"] is None


def test_build_failure_metadata_without_message():
    started, finished = _ts()
    md = build_failure_metadata("empty_response", started_at=started, finished_at=finished)
    assert md["ahrq_error"] == {"reason": "empty_response"}


# ─── result: status derivation ──────────────────────────────────────────────

@pytest.mark.parametrize(
    "metadata, expected",
    [
        (None, PostProcessStatus.NOT_STARTED),
        ({}, PostProcessStatus.NOT_STARTED),
        ({"foo": "bar"}, PostProcessStatus.NOT_STARTED),
        ({"ahrq_status": "success"}, PostProcessStatus.SUCCESS),
        ({"ahrq_status": "failed"}, PostProcessStatus.FAILED),
        ({"ahrq_status": "weird"}, PostProcessStatus.NOT_STARTED),
    ],
)
def test_resolve_status(metadata, expected):
    assert resolve_status(metadata) == expected


# ─── policy: weighted scoring ───────────────────────────────────────────────

def test_score_option_no_answer_is_zero():
    # 0 = unanswered → contributes nothing, for every question.
    assert all(score_option(i, 0) == 0 for i in range(_N))


def test_score_option_matches_weight_table():
    # Column c (1..4) for question i must return OPTION_WEIGHTS[i][c-1].
    for i in range(_N):
        for col in (1, 2, 3, 4):
            assert score_option(i, col) == OPTION_WEIGHTS[i][col - 1]


def test_score_total_all_column_one_is_min():
    assert score_total([1] * _N) == MIN_TOTAL == 22


def test_score_total_all_column_four_is_max():
    assert score_total([4] * _N) == MAX_TOTAL == 88


def test_score_total_ignores_unanswered():
    options = [4] * _N
    options[0] = 0  # drop Q1 (weights 3/6/9/12 → column 4 worth 12)
    assert score_total(options) == MAX_TOTAL - 12


# ─── policy: severity banding (Smythe & Everatt 2001) ───────────────────────

@pytest.mark.parametrize(
    "total, expected",
    [
        (0, "unlikely"),
        (22, "unlikely"),
        (44, "unlikely"),
        (45, "mild"),
        (60, "mild"),
        (61, "moderate_severe"),
        (88, "moderate_severe"),
        (999, "moderate_severe"),
    ],
)
def test_classify_severity_bands(total: int, expected: str):
    assert classify_severity(total) == expected
