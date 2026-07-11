"""Unit tests for ScreeningService.list_sessions — the conversation-set view.

Verifies grouping: one item per session with full messages, progress derived
from the latest history row's metadata, and completion/status/result rules.
DB access (ChatHistoryService) is mocked.
"""

from datetime import datetime, timezone
from unittest.mock import AsyncMock, MagicMock
from uuid import uuid4

import pytest

from app.dto.feature.chat.base import ChatMessageDTO, ChatSessionDTO
from app.dto.feature.chat.enums import ChatRoleType, FeatureType
from app.dto.feature.screening.enums import PostProcessStatus
from app.services.screening import service as svc
from app.services.screening.prompts import QUESTIONS

_N = len(QUESTIONS)
_NOW = datetime.now(timezone.utc)


def _session(n_msgs: int = 2) -> ChatSessionDTO:
    history = [
        ChatMessageDTO(
            role=ChatRoleType.USER if i % 2 else ChatRoleType.ASSISTANT,
            content=f"msg {i}",
            timestamp=_NOW,
        )
        for i in range(n_msgs)
    ]
    return ChatSessionDTO(
        session_id=uuid4(), user_id=uuid4(), feature=FeatureType.SCREEN,
        history=history, created_at=_NOW, updated_at=_NOW,
    )


def _row(session_id, metadata, created_at=_NOW):
    row = MagicMock()
    row.session_id = session_id
    row.metadata = metadata
    row.created_at = created_at
    return row


def _patch(monkeypatch, sessions, rows):
    monkeypatch.setattr(
        svc.ChatHistoryService, "get_user_sessions_full",
        AsyncMock(return_value=sessions),
    )
    history = MagicMock()
    history.items = rows
    monkeypatch.setattr(
        svc.ChatHistoryService, "get_feature_history",
        AsyncMock(return_value=history),
    )


@pytest.mark.asyncio
async def test_incomplete_session_set(monkeypatch):
    s = _session(4)
    _patch(monkeypatch, [s], [
        _row(s.session_id, {"answered_count": 2, "reask_count": 0}),
    ])
    out = await svc.ScreeningService.list_sessions(s.user_id, AsyncMock())
    assert out.total == 1
    item = out.items[0]
    assert item.session_id == s.session_id
    assert item.is_complete is False
    assert item.answered_count == 2
    assert item.total_topics == _N
    assert item.status == PostProcessStatus.NOT_STARTED
    assert item.result is None
    assert len(item.messages) == 4  # whole conversation, not flat rows


@pytest.mark.asyncio
async def test_completed_scored_session_carries_result(monkeypatch):
    s = _session(2)
    meta = {
        "answered_count": _N,
        "ahrq_status": "success",
        "ahrq_severity": "mild",
        "ahrq_total": 30,
    }
    _patch(monkeypatch, [s], [_row(s.session_id, meta)])
    out = await svc.ScreeningService.list_sessions(s.user_id, AsyncMock())
    item = out.items[0]
    assert item.is_complete is True
    assert item.status == PostProcessStatus.SUCCESS
    assert item.result["ahrq_severity"] == "mild"


@pytest.mark.asyncio
async def test_latest_row_wins_per_session(monkeypatch):
    # get_feature_history returns rows newest-first; older rows must not
    # override the newest metadata for the same session.
    s = _session(2)
    _patch(monkeypatch, [s], [
        _row(s.session_id, {"answered_count": 5}),   # newest
        _row(s.session_id, {"answered_count": 1}),   # older
    ])
    out = await svc.ScreeningService.list_sessions(s.user_id, AsyncMock())
    assert out.items[0].answered_count == 5


@pytest.mark.asyncio
async def test_failed_scoring_is_complete_but_no_result(monkeypatch):
    # All topics answered, scoring failed → complete, retryable, result=failure meta.
    s = _session(2)
    meta = {"answered_count": _N, "ahrq_status": "failed",
            "ahrq_error": {"reason": "malformed_json"}}
    _patch(monkeypatch, [s], [_row(s.session_id, meta)])
    out = await svc.ScreeningService.list_sessions(s.user_id, AsyncMock())
    item = out.items[0]
    assert item.is_complete is True
    assert item.status == PostProcessStatus.FAILED
    assert item.result["ahrq_error"]["reason"] == "malformed_json"


@pytest.mark.asyncio
async def test_session_without_history_rows_defaults(monkeypatch):
    # A session created by /start that never got a /reply has no metadata rows.
    s = _session(1)
    _patch(monkeypatch, [s], [])
    out = await svc.ScreeningService.list_sessions(s.user_id, AsyncMock())
    item = out.items[0]
    assert item.is_complete is False
    assert item.answered_count == 0
    assert item.status == PostProcessStatus.NOT_STARTED
