"""Tests for the social media search router."""

import pytest
from unittest.mock import AsyncMock, patch
from fastapi.testclient import TestClient
from main import app

client = TestClient(app)


@pytest.fixture
def mock_aggregate_search():
    with patch("routers.search.aggregate_search") as mock:
        mock.return_value = []
        yield mock


def test_health():
    resp = client.get("/health")
    assert resp.status_code == 200
    assert resp.json()["status"] == "ok"


def test_search_empty_query(mock_aggregate_search):
    resp = client.get("/ai/search?q=")
    assert resp.status_code == 422  # validation error for empty query


def test_search_returns_results(mock_aggregate_search):
    from agents.social_search_agent import SearchResult
    mock_aggregate_search.return_value = [
        SearchResult(
            platform="youtube",
            item_type="video",
            external_id="abc123",
            title="Test Video",
            author_name="Test Author",
            thumbnail_url="https://example.com/thumb.jpg",
            media_url="https://youtube.com/watch?v=abc123",
            duration=120,
            view_count=5000,
            like_count=300,
            country="US",
            tags=["test"],
            metadata={},
        )
    ]
    resp = client.get("/ai/search?q=test&platforms=youtube&types=video&countries=US")
    assert resp.status_code == 200
    data = resp.json()
    assert data["total"] == 1
    assert data["results"][0]["platform"] == "youtube"
    assert data["results"][0]["title"] == "Test Video"


def test_search_multi_platform(mock_aggregate_search):
    mock_aggregate_search.return_value = []
    resp = client.get("/ai/search?q=lofi&platforms=youtube,spotify&types=music&countries=US,JP")
    assert resp.status_code == 200
    # Verify the correct platforms were forwarded
    call_kwargs = mock_aggregate_search.call_args.kwargs
    assert "youtube" in call_kwargs["platforms"]
    assert "spotify" in call_kwargs["platforms"]
    assert "US" in call_kwargs["countries"]
    assert "JP" in call_kwargs["countries"]
