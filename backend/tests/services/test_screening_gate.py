"""Unit tests for the pre-screening answer-gate.

Covers the pure parse/prompt helpers and the ScreeningService.reply flow:
advance-on-answered, hold-on-unanswered, the re-ask loop cap, and completion.
The DB (ChatHistoryService), the LLM boundary (LLMRetryPolicy.execute) and the
post-process callback are mocked.
"""

from datetime import datetime, timezone
from unittest.mock import AsyncMock, MagicMock
from uuid import uuid4

import pytest

from app.dto.feature.chat.base import ChatSessionDTO
from app.dto.feature.chat.enums import FeatureType
from app.services.screening import service as svc
from app.services.screening.service import _parse_gate, _clean_json, _MAX_REASK
from app.services.screening.prompts import build_gate_prompt, QUESTIONS

_N = len(QUESTIONS)


# ─── pure helpers ────────────────────────────────────────────────────────────

def test_parse_gate_answered_true():
    assert _parse_gate('{"answered": true, "message": "Great, next..."}') == (
        True, "Great, next...")


def test_parse_gate_answered_false():
    assert _parse_gate('{"answered": false, "message": "Say more?"}') == (
        False, "Say more?")


def test_parse_gate_strips_code_fences():
    raw = '```json\n{"answered": true, "message": "ok"}\n```'
    assert _parse_gate(raw) == (True, "ok")


def test_parse_gate_garbage_falls_back_to_advance():
    # Malformed → must advance (answered=True) so the flow never wedges.
    answered, msg = _parse_gate("not json at all")
    assert answered is True
    assert msg == "not json at all"


def test_parse_gate_empty_message_falls_back():
    answered, _ = _parse_gate('{"answered": false, "message": ""}')
    assert answered is True  # empty message → fallback → advance


def test_clean_json_removes_fences():
    assert _clean_json('```json\n{"a":1}\n```') == '{"a":1}'


def test_build_gate_prompt_includes_current_and_next():
    p = build_gate_prompt("Do you read slowly?", "How much do you read?")
    assert "Do you read slowly?" in p
    assert "How much do you read?" in p
    assert '"answered"' in p


def test_build_gate_prompt_last_topic_asks_for_summary():
    p = build_gate_prompt("Final topic?", None)
    assert "closing summary" in p
    assert "final topic" in p.lower()


def test_build_gate_prompt_all_covered_branch():
    p = build_gate_prompt(None, None)
    assert "All topics" in p
    assert '"answered": true' in p


# ─── reply flow ──────────────────────────────────────────────────────────────

def _session() -> ChatSessionDTO:
    now = datetime.now(timezone.utc)
    return ChatSessionDTO(
        session_id=uuid4(), user_id=uuid4(), feature=FeatureType.SCREEN,
        history=[], created_at=now, updated_at=now,
    )


def _patch(monkeypatch, *, gate_json: str, last_metadata: dict):
    session = _session()
    last = MagicMock()
    last.metadata = last_metadata
    saved = MagicMock()
    saved.id = uuid4()

    monkeypatch.setattr(svc.ChatHistoryService, "get_session",
                        AsyncMock(return_value=session))
    monkeypatch.setattr(svc.ChatHistoryService,
                        "get_last_feature_history_for_session",
                        AsyncMock(return_value=last))
    monkeypatch.setattr(svc.ChatHistoryService, "append_message", AsyncMock())
    save = AsyncMock(return_value=saved)
    monkeypatch.setattr(svc.ChatHistoryService, "save_feature_history", save)

    llm_res = MagicMock()
    llm_res.content = gate_json
    monkeypatch.setattr(svc.LLMRetryPolicy, "execute",
                        AsyncMock(return_value=llm_res))

    pp = AsyncMock(return_value=MagicMock(metadata={"ahrq_severity": "mild"}))
    monkeypatch.setattr(svc.PostProcessService, "run", pp)
    return session, save, pp


def _saved_meta(save):
    return save.await_args.kwargs["metadata"]


@pytest.mark.asyncio
async def test_reply_answered_advances_topic(monkeypatch):
    session, save, pp = _patch(
        monkeypatch,
        gate_json='{"answered": true, "message": "Next question..."}',
        last_metadata={"answered_count": 2, "reask_count": 0},
    )
    res = await svc.ScreeningService.reply("my answer", session.session_id,
                                           session.user_id, AsyncMock())
    assert res.is_complete is False
    assert res.answered is True
    assert res.answered_count == 3
    assert res.total_topics == _N
    assert _saved_meta(save) == {"answered_count": 3, "reask_count": 0}
    pp.assert_not_awaited()


@pytest.mark.asyncio
async def test_reply_unanswered_holds_topic(monkeypatch):
    session, save, pp = _patch(
        monkeypatch,
        gate_json='{"answered": false, "message": "Can you clarify?"}',
        last_metadata={"answered_count": 2, "reask_count": 0},
    )
    res = await svc.ScreeningService.reply("uh", session.session_id,
                                           session.user_id, AsyncMock())
    assert res.is_complete is False
    assert res.answered is False
    assert res.answered_count == 2
    # Topic held; re-ask counter bumped.
    assert _saved_meta(save) == {"answered_count": 2, "reask_count": 1}


@pytest.mark.asyncio
async def test_reply_loop_cap_forces_advance(monkeypatch):
    # Already re-asked _MAX_REASK-1 times; another 'not answered' must advance.
    session, save, _ = _patch(
        monkeypatch,
        gate_json='{"answered": false, "message": "still vague"}',
        last_metadata={"answered_count": 2, "reask_count": _MAX_REASK - 1},
    )
    res = await svc.ScreeningService.reply("uh", session.session_id,
                                           session.user_id, AsyncMock())
    # Force-advanced by the loop cap → reported as answered.
    assert res.answered is True
    assert _saved_meta(save) == {"answered_count": 3, "reask_count": 0}


@pytest.mark.asyncio
async def test_reply_completes_and_runs_postprocess(monkeypatch):
    session, save, pp = _patch(
        monkeypatch,
        gate_json='{"answered": true, "message": "That is everything, thanks."}',
        last_metadata={"answered_count": _N - 1, "reask_count": 0},
    )
    res = await svc.ScreeningService.reply("last answer", session.session_id,
                                           session.user_id, AsyncMock())
    assert res.is_complete is True
    assert res.answered is True
    assert res.answered_count == _N
    assert _saved_meta(save)["answered_count"] == _N
    pp.assert_awaited_once()
    assert res.ahrq_result == {"ahrq_severity": "mild"}
