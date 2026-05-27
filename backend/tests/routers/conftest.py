"""Router-scoped fixtures. Requires FastAPI app + DB.

DTO unit tests do NOT pull this — they live under tests/dto/ with no conftest.
"""

import pytest
from fastapi.testclient import TestClient

from app.main import app


@pytest.fixture(scope="module")
def client() -> TestClient:
    return TestClient(app)


@pytest.fixture
def account(client: TestClient) -> dict:
    res = client.post("/api/v1/auth/generate")
    assert res.status_code == 201, res.text
    return res.json()


@pytest.fixture
def auth_headers(account: dict) -> dict:
    return {"Authorization": f"Bearer {account['access_token']}"}


@pytest.fixture
def session_id(client: TestClient, auth_headers: dict) -> str:
    res = client.post("/api/v1/me/screen/start", headers=auth_headers)
    assert res.status_code == 201, res.text
    return res.json()["session_id"]
