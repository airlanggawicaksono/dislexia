"""Service-level unit tests for PostProcessService.

DB access (ChatHistoryService) and the LLM boundary (_extract) are mocked.
Tests branch coverage: success, each failure path, conflict on incomplete
sessions, force override, and the cheap status snapshot.
"""

import json
from datetime import datetime, timezone
from unittest.mock import AsyncMock, MagicMock
from uuid import uuid4

import pytest

from app.exceptions import ConflictError
from app.dto.feature.chat.base import ChatMessageDTO, ChatSessionDTO
from app.dto.feature.chat.enums import ChatRoleType, FeatureType
from app.dto.feature.screening.enums import PostProcessStatus
from app.policies import score_total
from app.services.screening.prompts import QUESTIONS
from app.services.screening.postprocess.service import PostProcessService
from app.services.screening.postprocess import result as result_mod

_N = len(QUESTIONS)


def _session(assistant_turns: int) -> ChatSessionDTO:
    now = datetime.now(timezone.utc)
    history: list[ChatMessageDTO] = []
    for _ in range(assistant_turns):
        history.append(ChatMessageDTO(role=ChatRoleType.USER, content="answer", timestamp=now))
        history.append(ChatMessageDTO(role=ChatRoleType.ASSISTANT, content="question", timestamp=now))
    return ChatSessionDTO(
        session_id=uuid4(),
        user_id=uuid4(),
        feature=FeatureType.SCREEN,
        history=history,
        created_at=now,
        updated_at=now,
    )


def _history_item(metadata=None):
    item = MagicMock()
    item.id = uuid4()
    item.metadata = metadata
    return item


def _valid_json(score: int = 1) -> str:
    return json.dumps({"scores": [score] * _N, "comments": ["ok"] * _N})


def _patch_store(monkeypatch, *, session, last_item):
    """Mock the ChatHistoryService calls PostProcessService makes."""
    from app.services.screening.postprocess import service as svc

    monkeypatch.setattr(
        svc.ChatHistoryService, "get_session",
        AsyncMock(return_value=session),
    )
    monkeypatch.setattr(
        svc.ChatHistoryService, "get_last_feature_history_for_session",
        AsyncMock(return_value=last_item),
    )
    save = AsyncMock(return_value=last_item)
    monkeypatch.setattr(svc.ChatHistoryService, "set_feature_history_metadata", save)
    return save


def _patch_extract(monkeypatch, *, returns=None, raises=None):
    if raises is not None:
        monkeypatch.setattr(
            PostProcessService, "_extract",
            AsyncMock(side_effect=raises),
        )
    else:
        monkeypatch.setattr(
            PostProcessService, "_extract",
            AsyncMock(return_value=returns),
        )


# ─── run: success ───────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_run_success_persists_and_returns_scores(monkeypatch):
    session = _session(_N)
    last_item = _history_item()
    save = _patch_store(monkeypatch, session=session, last_item=last_item)
    _patch_extract(monkeypatch, returns=_valid_json(score=2))

    out = await PostProcessService.run(session.session_id, session.user_id, AsyncMock())

    assert out.status == PostProcessStatus.SUCCESS
    assert out.metadata["ahrq_scores"] == [2] * _N
    assert out.metadata["ahrq_total"] == score_total([2] * _N)  # weighted, not 2*_N
    assert out.history_id == last_item.id
    # metadata was written back to the latest history row
    save.assert_awaited_once()
    assert save.await_args.args[0] == last_item.id


@pytest.mark.asyncio
async def test_run_merges_existing_metadata(monkeypatch):
    # The final row carries the answer-gate progress; scoring must ADD its
    # keys, not replace the dict (resume relies on answered_count).
    session = _session(_N)
    last_item = _history_item(metadata={"answered_count": _N, "reask_count": 0})
    save = _patch_store(monkeypatch, session=session, last_item=last_item)
    _patch_extract(monkeypatch, returns=_valid_json())

    out = await PostProcessService.run(session.session_id, session.user_id, AsyncMock())

    persisted = save.await_args.args[1]
    assert persisted["answered_count"] == _N
    assert persisted["ahrq_status"] == PostProcessStatus.SUCCESS.value
    assert out.metadata["answered_count"] == _N


# ─── run: failure paths all persist failure metadata, never raise ───────────

@pytest.mark.asyncio
async def test_run_llm_refusal_marks_failed(monkeypatch):
    session = _session(_N)
    save = _patch_store(monkeypatch, session=session, last_item=_history_item())
    _patch_extract(monkeypatch, returns="Error: rate limit exceeded")

    out = await PostProcessService.run(session.session_id, session.user_id, AsyncMock())

    assert out.status == PostProcessStatus.FAILED
    assert out.metadata["ahrq_error"]["reason"] == "llm_refused_or_api_error"
    assert out.metadata["ahrq_scores"] is None
    save.assert_awaited_once()


@pytest.mark.asyncio
async def test_run_malformed_json_marks_failed(monkeypatch):
    session = _session(_N)
    _patch_store(monkeypatch, session=session, last_item=_history_item())
    _patch_extract(monkeypatch, returns="totally not json")

    out = await PostProcessService.run(session.session_id, session.user_id, AsyncMock())

    assert out.status == PostProcessStatus.FAILED
    assert out.metadata["ahrq_error"]["reason"] == "malformed_json"


@pytest.mark.asyncio
async def test_run_extract_transport_error_marks_failed(monkeypatch):
    session = _session(_N)
    _patch_store(monkeypatch, session=session, last_item=_history_item())
    _patch_extract(monkeypatch, raises=RuntimeError("connection reset"))

    out = await PostProcessService.run(session.session_id, session.user_id, AsyncMock())

    assert out.status == PostProcessStatus.FAILED
    assert out.metadata["ahrq_error"]["reason"] == "llm_call_failed"
    assert "connection reset" in out.metadata["ahrq_error"]["message"]


# ─── run: completeness gating ───────────────────────────────────────────────

@pytest.mark.asyncio
async def test_run_incomplete_without_force_raises_conflict(monkeypatch):
    session = _session(3)  # only 3 of N answered
    _patch_store(monkeypatch, session=session, last_item=_history_item())
    _patch_extract(monkeypatch, returns=_valid_json())

    with pytest.raises(ConflictError):
        await PostProcessService.run(session.session_id, session.user_id, AsyncMock())


@pytest.mark.asyncio
async def test_run_incomplete_with_force_runs(monkeypatch):
    session = _session(3)
    _patch_store(monkeypatch, session=session, last_item=_history_item())
    _patch_extract(monkeypatch, returns=_valid_json())

    out = await PostProcessService.run(
        session.session_id, session.user_id, AsyncMock(), force=True
    )
    assert out.status == PostProcessStatus.SUCCESS


# ─── get_status: cheap DB-only snapshot, no LLM ─────────────────────────────

@pytest.mark.asyncio
async def test_get_status_success(monkeypatch):
    started = datetime(2026, 7, 3, tzinfo=timezone.utc)
    md = result_mod.build_success_metadata(
        [1] * _N, ["ok"] * _N, started_at=started, finished_at=started,
    )
    session_id, user_id = uuid4(), uuid4()
    last_item = _history_item(metadata=md)
    _patch_store(monkeypatch, session=_session(_N), last_item=last_item)
    # ensure no LLM call happens for status
    _patch_extract(monkeypatch, raises=AssertionError("status must not call LLM"))

    report = await PostProcessService.get_status(session_id, user_id, AsyncMock())

    assert report.status == PostProcessStatus.SUCCESS
    assert report.metadata == md
    assert report.history_id == last_item.id


@pytest.mark.asyncio
async def test_get_status_not_started_when_metadata_none(monkeypatch):
    last_item = _history_item(metadata=None)
    _patch_store(monkeypatch, session=_session(_N), last_item=last_item)

    report = await PostProcessService.get_status(uuid4(), uuid4(), AsyncMock())

    assert report.status == PostProcessStatus.NOT_STARTED
    assert report.metadata is None


@pytest.mark.asyncio
async def test_get_status_failed(monkeypatch):
    started = datetime(2026, 7, 3, tzinfo=timezone.utc)
    md = result_mod.build_failure_metadata(
        "malformed_json", "boom", started_at=started, finished_at=started,
    )
    last_item = _history_item(metadata=md)
    _patch_store(monkeypatch, session=_session(_N), last_item=last_item)

    report = await PostProcessService.get_status(uuid4(), uuid4(), AsyncMock())

    assert report.status == PostProcessStatus.FAILED
    assert report.metadata["ahrq_error"]["reason"] == "malformed_json"
