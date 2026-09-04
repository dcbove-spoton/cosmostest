"""Tests for the FastAPI application."""

import asyncio

import httpx

from cosmostest.main import app


async def _get_foo(auth: httpx.BasicAuth | None = None) -> httpx.Response:
    """Request the example endpoint through the ASGI application."""
    transport = httpx.ASGITransport(app=app)
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as client:
        return await client.get("/foo", auth=auth)


def test_get_foo_requires_credentials() -> None:
    """GET /foo rejects requests without credentials."""
    response = asyncio.run(_get_foo())

    assert response.status_code == 401
    assert response.headers["www-authenticate"] == "Basic"


def test_get_foo_rejects_incorrect_username() -> None:
    """GET /foo rejects an incorrect username."""
    response = asyncio.run(_get_foo(httpx.BasicAuth("incorrect", "test")))

    assert response.status_code == 401
    assert response.headers["www-authenticate"] == "Basic"


def test_get_foo_rejects_incorrect_password() -> None:
    """GET /foo rejects an incorrect password."""
    response = asyncio.run(_get_foo(httpx.BasicAuth("test", "incorrect")))

    assert response.status_code == 401
    assert response.headers["www-authenticate"] == "Basic"


def test_get_foo_accepts_valid_credentials() -> None:
    """GET /foo returns the expected response for valid credentials."""
    response = asyncio.run(_get_foo(httpx.BasicAuth("test", "test")))

    assert response.status_code == 200
    assert response.json() == "bar"
