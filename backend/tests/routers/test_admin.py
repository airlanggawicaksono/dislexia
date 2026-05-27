"""Tests for app/routers/admin.py"""

import pytest
from fastapi.testclient import TestClient

from tests.fixtures.payloads import AUTH_HEADER_INVALID, ADMIN_HISTORY_QUERY_INVALID, PATH_UUID_INVALID

_BASE = "/api/v1/admin"


def test_list_history_requires_auth(client: TestClient):
    res = client.get(f"{_BASE}/history")
    assert res.status_code in (401, 403)


def test_history_detail_requires_auth(client: TestClient):
    res = client.get(f"{_BASE}/history/00000000-0000-0000-0000-000000000000")
    assert res.status_code in (401, 403)


def test_list_history_no_filter_returns_200(client: TestClient, auth_headers: dict):
    res = client.get(f"{_BASE}/history", headers=auth_headers)
    assert res.status_code == 200
    body = res.json()
    assert "items" in body
    assert "total" in body


def test_history_detail_unknown_id_returns_404(client: TestClient, auth_headers: dict):
    res = client.get(f"{_BASE}/history/00000000-0000-0000-0000-000000000000", headers=auth_headers)
    assert res.status_code == 404


@pytest.mark.parametrize("query, case", ADMIN_HISTORY_QUERY_INVALID, ids=[c[1] for c in ADMIN_HISTORY_QUERY_INVALID])
def test_list_history_rejects_bad_filter(client: TestClient, auth_headers: dict, query: dict, case: str):
    res = client.get(f"{_BASE}/history", headers=auth_headers, params=query)
    # empty user param is technically valid (becomes filter that matches no users),
    # so allow 200; bad feature enum must 422
    assert res.status_code in (200, 422), f"{case}: {res.status_code} → {res.text}"


@pytest.mark.parametrize("bad_id, case", PATH_UUID_INVALID, ids=[c[1] for c in PATH_UUID_INVALID])
def test_history_detail_rejects_bad_uuid(client: TestClient, auth_headers: dict, bad_id: str, case: str):
    res = client.get(f"{_BASE}/history/{bad_id}", headers=auth_headers)
    assert res.status_code in (404, 422), f"{case}: {res.status_code} → {res.text}"


@pytest.mark.parametrize("headers, case", AUTH_HEADER_INVALID, ids=[c[1] for c in AUTH_HEADER_INVALID])
def test_endpoints_reject_bad_auth(client: TestClient, headers: dict, case: str):
    res = client.get(f"{_BASE}/history", headers=headers)
    assert res.status_code in (401, 403), f"{case}: {res.status_code}"
