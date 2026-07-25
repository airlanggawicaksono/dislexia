"""LLMRetryPolicy.stream: retry only before the first chunk.

The streaming path used to have no retry (unlike the non-stream `execute`),
so a transient connect-time provider error killed summarize/reader outright.
These pin the two invariants of the fix: retry pre-first-chunk, never after.
"""

import pytest

from app.policies.retry import LLMRetryPolicy


async def _drain(agen):
    return [c async for c in agen]


@pytest.mark.asyncio
async def test_retries_transient_failure_before_first_chunk(monkeypatch):
    monkeypatch.setattr("asyncio.sleep", _no_sleep)  # skip backoff
    calls = {"n": 0}

    async def flaky(_req):
        calls["n"] += 1
        if calls["n"] < 3:
            raise ConnectionError("connection reset")
        for tok in ("a", "b", "c"):
            yield tok

    out = await _drain(LLMRetryPolicy.stream(flaky, "req"))

    assert out == ["a", "b", "c"]
    assert calls["n"] == 3  # failed twice, succeeded on the third attempt


@pytest.mark.asyncio
async def test_does_not_retry_after_a_chunk_is_yielded(monkeypatch):
    monkeypatch.setattr("asyncio.sleep", _no_sleep)
    calls = {"n": 0}

    async def dies_midstream(_req):
        calls["n"] += 1
        yield "partial"
        raise ConnectionError("dropped mid-stream")

    got = []
    with pytest.raises(ConnectionError):
        async for chunk in LLMRetryPolicy.stream(dies_midstream, "req"):
            got.append(chunk)

    assert got == ["partial"]  # no duplicate re-emission
    assert calls["n"] == 1  # not retried once streaming started


@pytest.mark.asyncio
async def test_raises_after_attempts_exhausted(monkeypatch):
    monkeypatch.setattr("asyncio.sleep", _no_sleep)
    calls = {"n": 0}

    async def always_fails(_req):
        calls["n"] += 1
        raise ConnectionError("still down")
        yield  # pragma: no cover — makes this an async generator

    with pytest.raises(ConnectionError):
        await _drain(LLMRetryPolicy.stream(always_fails, "req"))

    assert calls["n"] == 3


async def _no_sleep(_seconds):
    return None
