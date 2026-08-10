"""Tests for app/routers/features/summarize.py"""

import pytest
from fastapi.testclient import TestClient

from tests.fixtures.payloads import FEATURE_PROCESS_INVALID, AUTH_HEADER_INVALID

_BASE = "/api/v1/me/summarize"


def test_process_endpoint_registered():
    """Regression (c41be30): the non-streaming /process endpoint must not
    disappear — the Flutter frontend calls it and gets a 404 without it.
    DB-free: checks route registration only."""
    from app.main import app
    paths = {getattr(r, "path", "") for r in app.routes}
    assert "/api/v1/me/summarize/process" in paths, (
        "POST /summarize/process missing — frontend calls it (prod 404). "
        "Keep both /process and /process-stream, like define/professionalize."
    )


def test_process_requires_auth(client: TestClient):
    res = client.post(f"{_BASE}/process", json={"text": "hi"})
    assert res.status_code in (401, 403)


def test_history_requires_auth(client: TestClient):
    res = client.get(f"{_BASE}/history")
    assert res.status_code in (401, 403)


@pytest.mark.parametrize("payload, case", FEATURE_PROCESS_INVALID, ids=[c[1] for c in FEATURE_PROCESS_INVALID])
def test_process_rejects_partial_input(client: TestClient, auth_headers: dict, payload: dict, case: str):
    res = client.post(f"{_BASE}/process", json=payload, headers=auth_headers)
    assert res.status_code == 422, f"{case}: {res.status_code} → {res.text}"


@pytest.mark.parametrize("payload, case", FEATURE_PROCESS_INVALID, ids=[c[1] for c in FEATURE_PROCESS_INVALID])
def test_process_stream_rejects_partial_input(client: TestClient, auth_headers: dict, payload: dict, case: str):
    res = client.post(f"{_BASE}/process-stream", json=payload, headers=auth_headers)
    assert res.status_code == 422, f"{case}: {res.status_code} → {res.text}"


@pytest.mark.parametrize("headers, case", AUTH_HEADER_INVALID, ids=[c[1] for c in AUTH_HEADER_INVALID])
def test_endpoints_reject_bad_auth(client: TestClient, headers: dict, case: str):
    res = client.post(f"{_BASE}/process", json={"text": "hi"}, headers=headers)
    assert res.status_code in (401, 403), f"{case}: {res.status_code}"
