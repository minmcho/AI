"""Tests for favorites router."""

import pytest
from unittest.mock import AsyncMock, patch
from fastapi.testclient import TestClient
from main import app

client = TestClient(app)


@pytest.mark.asyncio
async def test_add_favorite():
    mock_pool = AsyncMock()
    mock_pool.fetchrow = AsyncMock(return_value={"id": "fav-uuid-1"})

    with patch("routers.favorites.get_pool", return_value=mock_pool):
        resp = client.post("/ai/favorites/test-profile", json={
            "item_type": "social_music",
            "external_id": "spotify_track_123",
            "platform": "spotify",
            "title": "Test Track",
            "author_name": "Test Artist",
            "duration": 210.0,
            "metadata": {"genre": "electronic"},
        })
    assert resp.status_code == 200
    assert resp.json()["ok"] is True


@pytest.mark.asyncio
async def test_remove_favorite():
    mock_pool = AsyncMock()
    mock_pool.execute = AsyncMock(return_value="DELETE 1")

    with patch("routers.favorites.get_pool", return_value=mock_pool):
        resp = client.delete("/ai/favorites/test-profile/fav-uuid-1")
    assert resp.status_code == 200
    assert resp.json()["ok"] is True


@pytest.mark.asyncio
async def test_remove_nonexistent_favorite():
    mock_pool = AsyncMock()
    mock_pool.execute = AsyncMock(return_value="DELETE 0")

    with patch("routers.favorites.get_pool", return_value=mock_pool):
        resp = client.delete("/ai/favorites/test-profile/nonexistent")
    assert resp.status_code == 404
