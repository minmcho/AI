"""
Social media search aggregator.
Searches YouTube, TikTok, Spotify, SoundCloud, and Instagram
via their public/authenticated APIs and normalises results.
"""

import os
import asyncio
import httpx
from dataclasses import dataclass
from typing import Literal

Platform = Literal["youtube", "tiktok", "spotify", "soundcloud", "instagram"]

YOUTUBE_API_KEY   = os.environ.get("YOUTUBE_API_KEY", "")
SPOTIFY_CLIENT_ID = os.environ.get("SPOTIFY_CLIENT_ID", "")
SPOTIFY_CLIENT_SECRET = os.environ.get("SPOTIFY_CLIENT_SECRET", "")
SOUNDCLOUD_CLIENT_ID  = os.environ.get("SOUNDCLOUD_CLIENT_ID", "")


@dataclass
class SearchResult:
    platform: str
    item_type: str          # "video" | "music"
    external_id: str
    title: str
    author_name: str
    thumbnail_url: str
    media_url: str
    duration: float         # seconds
    view_count: int
    like_count: int
    country: str            # ISO 3166-1 alpha-2
    tags: list[str]
    metadata: dict


# ── YouTube ───────────────────────────────────────────────────────────────────

async def search_youtube(query: str, country: str = "US", max_results: int = 10) -> list[SearchResult]:
    if not YOUTUBE_API_KEY:
        return []
    params = {
        "part": "snippet",
        "q": query,
        "type": "video",
        "regionCode": country,
        "maxResults": max_results,
        "key": YOUTUBE_API_KEY,
        "videoCategoryId": "10",  # Music category
    }
    async with httpx.AsyncClient(timeout=15) as client:
        resp = await client.get("https://www.googleapis.com/youtube/v3/search", params=params)
        resp.raise_for_status()
        items = resp.json().get("items", [])

    results = []
    for item in items:
        vid_id = item["id"].get("videoId", "")
        snip   = item["snippet"]
        results.append(SearchResult(
            platform="youtube",
            item_type="video",
            external_id=vid_id,
            title=snip.get("title", ""),
            author_name=snip.get("channelTitle", ""),
            thumbnail_url=snip.get("thumbnails", {}).get("high", {}).get("url", ""),
            media_url=f"https://www.youtube.com/watch?v={vid_id}",
            duration=0,
            view_count=0,
            like_count=0,
            country=country,
            tags=snip.get("tags", []),
            metadata={"published_at": snip.get("publishedAt")},
        ))
    return results


# ── Spotify ───────────────────────────────────────────────────────────────────

_spotify_token: str | None = None

async def _get_spotify_token() -> str:
    global _spotify_token
    if _spotify_token:
        return _spotify_token
    async with httpx.AsyncClient(timeout=10) as client:
        resp = await client.post(
            "https://accounts.spotify.com/api/token",
            data={"grant_type": "client_credentials"},
            auth=(SPOTIFY_CLIENT_ID, SPOTIFY_CLIENT_SECRET),
        )
        resp.raise_for_status()
        _spotify_token = resp.json()["access_token"]
    return _spotify_token


async def search_spotify(query: str, market: str = "US", max_results: int = 10) -> list[SearchResult]:
    if not SPOTIFY_CLIENT_ID:
        return []
    token = await _get_spotify_token()
    params = {"q": query, "type": "track", "market": market, "limit": max_results}
    async with httpx.AsyncClient(timeout=15) as client:
        resp = await client.get(
            "https://api.spotify.com/v1/search",
            params=params,
            headers={"Authorization": f"Bearer {token}"},
        )
        resp.raise_for_status()
        tracks = resp.json().get("tracks", {}).get("items", [])

    results = []
    for t in tracks:
        album = t.get("album", {})
        artists = ", ".join(a["name"] for a in t.get("artists", []))
        images = album.get("images", [{}])
        results.append(SearchResult(
            platform="spotify",
            item_type="music",
            external_id=t["id"],
            title=t["name"],
            author_name=artists,
            thumbnail_url=images[0].get("url", "") if images else "",
            media_url=t.get("external_urls", {}).get("spotify", ""),
            duration=t.get("duration_ms", 0) / 1000,
            view_count=t.get("popularity", 0) * 1000,
            like_count=0,
            country=market,
            tags=[album.get("name", "")],
            metadata={
                "preview_url": t.get("preview_url"),
                "isrc": t.get("external_ids", {}).get("isrc"),
                "explicit": t.get("explicit", False),
            },
        ))
    return results


# ── SoundCloud ────────────────────────────────────────────────────────────────

async def search_soundcloud(query: str, max_results: int = 10) -> list[SearchResult]:
    if not SOUNDCLOUD_CLIENT_ID:
        return []
    params = {"q": query, "limit": max_results, "client_id": SOUNDCLOUD_CLIENT_ID}
    async with httpx.AsyncClient(timeout=15) as client:
        resp = await client.get("https://api.soundcloud.com/tracks", params=params)
        resp.raise_for_status()
        tracks = resp.json()

    results = []
    for t in tracks:
        results.append(SearchResult(
            platform="soundcloud",
            item_type="music",
            external_id=str(t["id"]),
            title=t.get("title", ""),
            author_name=t.get("user", {}).get("username", ""),
            thumbnail_url=t.get("artwork_url", "").replace("large", "t500x500"),
            media_url=t.get("permalink_url", ""),
            duration=t.get("duration", 0) / 1000,
            view_count=t.get("playback_count", 0),
            like_count=t.get("likes_count", 0),
            country=t.get("user", {}).get("country_code", ""),
            tags=t.get("tag_list", "").split(),
            metadata={"genre": t.get("genre"), "bpm": t.get("bpm")},
        ))
    return results


# ── Aggregator ────────────────────────────────────────────────────────────────

async def aggregate_search(
    query: str,
    platforms: list[Platform],
    countries: list[str],
    item_types: list[str],  # ["video", "music"]
    max_per_platform: int = 10,
) -> list[SearchResult]:
    """Fan out search across requested platforms and countries, return merged results."""
    tasks = []
    country = countries[0] if countries else "US"

    for platform in platforms:
        if platform == "youtube" and "video" in item_types:
            for c in countries[:3]:  # cap at 3 countries to avoid rate limits
                tasks.append(search_youtube(query, country=c, max_results=max_per_platform))
        elif platform == "spotify" and "music" in item_types:
            tasks.append(search_spotify(query, market=country, max_results=max_per_platform))
        elif platform == "soundcloud" and "music" in item_types:
            tasks.append(search_soundcloud(query, max_results=max_per_platform))

    nested = await asyncio.gather(*tasks, return_exceptions=True)
    results: list[SearchResult] = []
    for batch in nested:
        if isinstance(batch, list):
            results.extend(batch)
    return results
