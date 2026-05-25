"""Tests for app/routers/auth.py"""

import pytest
from fastapi.testclient import TestClient

from tests.fixtures.payloads import LOGIN_INVALID, LOGIN_VALID


def test_generate_creates_account(client: TestClient):
    res = client.post("/api/v1/auth/generate")
    assert res.status_code == 201
    body = res.json()
    assert "account_number" in body
    assert len(body["account_number"]) == 16
    assert body["account_number"].isdigit()
    assert "access_token" in body
    assert body["token_type"] == "bearer"


def test_login_with_generated_account(client: TestClient, account: dict):
    res = client.post("/api/v1/auth/login", json={"account_number": account["account_number"]})
    assert res.status_code == 200
    body = res.json()
    assert "access_token" in body
    assert body["user"]["account_number"] == account["account_number"]


def test_login_unknown_account_returns_401(client: TestClient):
    res = client.post("/api/v1/auth/login", json={"account_number": "0000000000000001"})
    assert res.status_code == 401


@pytest.mark.parametrize("payload, case", LOGIN_INVALID, ids=[c[1] for c in LOGIN_INVALID])
def test_login_rejects_partial_input(client: TestClient, payload: dict, case: str):
    res = client.post("/api/v1/auth/login", json=payload)
    assert res.status_code in (401, 422), f"{case}: {res.status_code} → {res.text}"


@pytest.mark.parametrize("payload, case", LOGIN_VALID, ids=[c[1] for c in LOGIN_VALID])
def test_login_valid_shape_accepted_by_validator(client: TestClient, payload: dict, case: str):
    # Validator accepts; lookup will 401 since these accounts don't exist
    res = client.post("/api/v1/auth/login", json=payload)
    assert res.status_code in (200, 401), f"{case}: {res.status_code} → {res.text}"
