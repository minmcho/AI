"""Tests for preferences router."""

import pytest
from unittest.mock import AsyncMock, patch, MagicMock
from fastapi.testclient import TestClient
from main import app

client = TestClient(app)


def test_get_options():
    with patch("routers.preferences.get_pool") as mock_pool:
        resp = client.get("/ai/preferences/options")
    assert resp.status_code == 200
    data = resp.json()
    assert "music_genres" in data
    assert "countries" in data
    assert len(data["countries"]) >= 10
    assert any(c["code"] == "US" for c in data["countries"])
    assert any(c["code"] == "JP" for c in data["countries"])


@pytest.mark.asyncio
async def test_upsert_preferences():
    mock_conn = AsyncMock()
    mock_pool = AsyncMock()
    mock_pool.execute = AsyncMock(return_value=None)

    with patch("routers.preferences.get_pool", return_value=mock_pool), \
         patch("routers.preferences._recompute_embedding", return_value=None):
        resp = client.put("/ai/preferences/test-profile", json={
            "music_genres": ["electronic", "lofi"],
            "music_moods": ["chill"],
            "video_types": ["dance", "travel"],
            "countries": ["US", "JP"],
            "platforms": ["youtube", "spotify"],
            "prefer_dubbed": False,
            "prefer_subtitles": True,
            "autoplay_muted": False,
        })
    assert resp.status_code == 200
    assert resp.json()["ok"] is True
