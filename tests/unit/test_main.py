"""Tests for the FastAPI application."""

import asyncio

import httpx

from cosmostest.main import app


async def _get_foo(auth: tuple[str, str] | None = None) -> httpx.Response:
    """Request the example endpoint through the ASGI application."""
    transport = httpx.ASGITransport(app=app)
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as client:
        return await client.get("/foo", auth=auth)


def test_get_foo_with_valid_credentials() -> None:
    """GET /foo returns the expected response for valid credentials."""
    response = asyncio.run(_get_foo(("test", "test")))

    assert response.status_code == 200
    assert response.json() == "bar"


def test_get_foo_without_credentials() -> None:
    """GET /foo challenges requests without credentials."""
    response = asyncio.run(_get_foo())

    assert response.status_code == 401
    assert response.headers["WWW-Authenticate"] == "Basic"


def test_get_foo_with_incorrect_username() -> None:
    """GET /foo rejects an incorrect username."""
    response = asyncio.run(_get_foo(("incorrect", "test")))

    assert response.status_code == 401
    assert response.headers["WWW-Authenticate"] == "Basic"


def test_get_foo_with_incorrect_password() -> None:
    """GET /foo rejects an incorrect password."""
    response = asyncio.run(_get_foo(("test", "incorrect")))

    assert response.status_code == 401
    assert response.headers["WWW-Authenticate"] == "Basic"
