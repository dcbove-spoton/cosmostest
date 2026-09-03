"""Tests for the FastAPI application."""

import asyncio

import httpx

from cosmostest.main import app


async def _get_foo() -> httpx.Response:
    """Request the example endpoint through the ASGI application."""
    transport = httpx.ASGITransport(app=app)
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as client:
        return await client.get("/foo")


def test_get_foo() -> None:
    """GET /foo returns the expected response."""
    response = asyncio.run(_get_foo())

    assert response.status_code == 200
    assert response.json() == "bar"
