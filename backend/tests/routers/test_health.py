from fastapi.testclient import TestClient


def test_health_check(client: TestClient):
    res = client.get("/health")
    assert res.status_code == 200
    data = res.json()
    assert data["status"] == "healthy"
    assert data["version"] == "1.0.0"


def test_root_endpoint(client: TestClient):
    res = client.get("/")
    assert res.status_code == 200
    data = res.json()
    assert data["status"] == "ok"
    assert "/docs" in data["docs"]


def test_docs_endpoint(client: TestClient):
    res = client.get("/docs")
    assert res.status_code == 200
    assert "text/html" in res.headers["content-type"]
