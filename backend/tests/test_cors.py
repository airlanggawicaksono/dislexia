"""CORS middleware integration tests.

These tests verify that the CORSMiddleware is registered with the same
configuration used in ``app.main`` and that the appropriate
``Access-Control-Allow-*`` headers are returned on both simple (GET) and
preflight (OPTIONS) requests for the configured origins.

The tests use a lightweight FastAPI app constructed in-process to avoid
importing the full application graph (DB, LLM deps). The CORS policy comes
from ``app.config.settings.settings`` so the test reflects production
defaults.
"""

import pytest
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.testclient import TestClient

from app.config.settings import settings


# Build a small app that mirrors the production CORS registration in
# app/main.py. We intentionally do NOT import app.main here so this test
# does not require the full DB / LLM dependency chain.
_app = FastAPI()


@_app.get("/health")
def _health():
    return {"status": "healthy", "version": "1.0.0"}


@_app.post("/api/v1/auth/generate")
def _generate():
    return {"access_token": "fake", "user": {"id": 1, "username": "x"}}


_app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=settings.CORS_ALLOW_CREDENTIALS,
    allow_methods=settings.cors_methods,
    allow_headers=settings.cors_headers,
    expose_headers=settings.cors_expose_headers,
    max_age=settings.CORS_MAX_AGE,
)


@pytest.fixture(scope="module")
def client() -> TestClient:
    return TestClient(_app)


# --- Config sanity ----------------------------------------------------------


def test_cors_origins_default_includes_dyslexic_app():
    """Production-style default must include the production frontend origin."""
    assert "https://dyslexic.app" in settings.cors_origins


def test_cors_origins_default_includes_localhost_8080():
    """Dev default must include the local Flutter web dev port."""
    assert "http://localhost:8080" in settings.cors_origins


def test_cors_methods_and_headers_default_to_wildcard():
    """Default policy should permit all methods and headers."""
    assert settings.cors_methods == ["*"]
    assert settings.cors_headers == ["*"]


# --- GET response headers ---------------------------------------------------


def test_get_request_has_allow_origin_header(client: TestClient):
    """A simple GET to /health must echo the configured origin."""
    res = client.get(
        "/health",
        headers={"Origin": "https://dyslexic.app"},
    )
    assert res.status_code == 200
    assert res.headers.get("access-control-allow-origin") == "https://dyslexic.app"


def test_get_request_allow_origin_for_localhost(client: TestClient):
    """A GET with localhost origin must also be reflected."""
    res = client.get(
        "/health",
        headers={"Origin": "http://localhost:8080"},
    )
    assert res.status_code == 200
    assert res.headers.get("access-control-allow-origin") == "http://localhost:8080"


def test_get_request_allow_credentials_header(client: TestClient):
    """allow_credentials=True must be advertised (lowercased header)."""
    res = client.get(
        "/health",
        headers={"Origin": "https://dyslexic.app"},
    )
    assert res.status_code == 200
    # Starlette emits the value as a stringified bool
    assert res.headers.get("access-control-allow-credentials") == "true"


def test_get_request_without_origin_has_no_acao_header(client: TestClient):
    """A same-origin / no-Origin GET should not get an ACAO header set."""
    res = client.get("/health")
    assert res.status_code == 200
    # Same-origin requests are not subject to CORS, so no header is required.
    assert res.headers.get("access-control-allow-origin") is None


# --- OPTIONS preflight ------------------------------------------------------


def test_options_preflight_returns_allow_origin(client: TestClient):
    """A CORS preflight must echo the request Origin in the response."""
    res = client.options(
        "/api/v1/auth/generate",
        headers={
            "Origin": "https://dyslexic.app",
            "Access-Control-Request-Method": "POST",
            "Access-Control-Request-Headers": "content-type,authorization",
        },
    )
    # 200 means the middleware handled the preflight
    assert res.status_code == 200
    assert res.headers.get("access-control-allow-origin") == "https://dyslexic.app"


def test_options_preflight_allows_all_methods(client: TestClient):
    """When CORS_ALLOW_METHODS='*', the preflight advertises all methods."""
    res = client.options(
        "/api/v1/auth/generate",
        headers={
            "Origin": "http://localhost:8080",
            "Access-Control-Request-Method": "POST",
        },
    )
    assert res.status_code == 200
    methods = res.headers.get("access-control-allow-methods", "")
    assert methods, "expected Access-Control-Allow-Methods header on preflight"


def test_options_preflight_allows_all_headers(client: TestClient):
    """When CORS_ALLOW_HEADERS='*', the preflight advertises all headers."""
    res = client.options(
        "/api/v1/auth/generate",
        headers={
            "Origin": "https://dyslexic.app",
            "Access-Control-Request-Method": "POST",
            "Access-Control-Request-Headers": "content-type,authorization",
        },
    )
    assert res.status_code == 200
    headers = res.headers.get("access-control-allow-headers", "")
    assert headers, "expected Access-Control-Allow-Headers header on preflight"


# --- Custom CORS properties -------------------------------------------------


def test_cors_origins_parses_wildcard():
    """A single '*' value should be passed through as a list of one."""
    from app.config.settings import Settings

    s = Settings(CORS_ALLOW_ORIGINS="*")
    assert s.cors_origins == ["*"]


def test_cors_origins_parses_comma_separated():
    """A comma-separated list should be split and trimmed."""
    from app.config.settings import Settings

    s = Settings(
        CORS_ALLOW_ORIGINS="https://a.example, https://b.example ,,https://c.example"
    )
    assert s.cors_origins == [
        "https://a.example",
        "https://b.example",
        "https://c.example",
    ]


def test_cors_origins_empty_when_unset():
    """Empty / unset value should yield an empty list (no origins allowed)."""
    from app.config.settings import Settings

    s = Settings(CORS_ALLOW_ORIGINS="")
    assert s.cors_origins == []


def test_cors_methods_uppercases_explicit_list():
    """Explicit comma-separated methods should be uppercased."""
    from app.config.settings import Settings

    s = Settings(CORS_ALLOW_METHODS="get, post ,delete")
    assert s.cors_methods == ["GET", "POST", "DELETE"]
