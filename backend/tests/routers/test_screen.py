"""Tests for app/routers/features/screen.py"""

import pytest
from fastapi.testclient import TestClient

from tests.fixtures.payloads import SCREENING_REPLY_INVALID, AUTH_HEADER_INVALID

_BASE = "/api/v1/me/screen"


def test_start_requires_auth(client: TestClient):
    res = client.post(f"{_BASE}/start")
    assert res.status_code in (401, 403)


def test_reply_requires_auth(client: TestClient):
    res = client.post(f"{_BASE}/reply", json={"text": "hi", "session_id": "00000000-0000-0000-0000-000000000000"})
    assert res.status_code in (401, 403)


def test_history_requires_auth(client: TestClient):
    res = client.get(f"{_BASE}/history")
    assert res.status_code in (401, 403)


@pytest.mark.parametrize("payload, case", SCREENING_REPLY_INVALID, ids=[c[1] for c in SCREENING_REPLY_INVALID])
def test_reply_rejects_partial_input(client: TestClient, auth_headers: dict, payload: dict, case: str):
    res = client.post(f"{_BASE}/reply", json=payload, headers=auth_headers)
    assert res.status_code == 422, f"{case}: {res.status_code} → {res.text}"


@pytest.mark.parametrize("headers, case", AUTH_HEADER_INVALID, ids=[c[1] for c in AUTH_HEADER_INVALID])
def test_endpoints_reject_bad_auth(client: TestClient, headers: dict, case: str):
    res = client.post(f"{_BASE}/start", headers=headers)
    assert res.status_code in (401, 403), f"{case}: {res.status_code}"


_DUMMY_SESSION = "00000000-0000-0000-0000-000000000000"


def test_postprocess_requires_auth(client: TestClient):
    res = client.post(f"{_BASE}/{_DUMMY_SESSION}/postprocess")
    assert res.status_code in (401, 403)


def test_postprocess_status_requires_auth(client: TestClient):
    res = client.get(f"{_BASE}/{_DUMMY_SESSION}/postprocess/status")
    assert res.status_code in (401, 403)


def test_postprocess_unknown_session_404(client: TestClient, auth_headers: dict):
    res = client.post(f"{_BASE}/{_DUMMY_SESSION}/postprocess", headers=auth_headers)
    assert res.status_code == 404, res.text


def test_postprocess_status_unknown_session_404(client: TestClient, auth_headers: dict):
    res = client.get(f"{_BASE}/{_DUMMY_SESSION}/postprocess/status", headers=auth_headers)
    assert res.status_code == 404, res.text


def test_postprocess_bad_session_uuid_422(client: TestClient, auth_headers: dict):
    res = client.post(f"{_BASE}/not-a-uuid/postprocess", headers=auth_headers)
    assert res.status_code == 422, res.text
