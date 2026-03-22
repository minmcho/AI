from fastapi import APIRouter, Query, Depends
from pydantic import BaseModel
from typing import Literal
from agents.social_search_agent import aggregate_search, SearchResult
from models.database import get_pool
import asyncpg

router = APIRouter()

Platform = Literal["youtube", "tiktok", "spotify", "soundcloud", "instagram"]
ItemType = Literal["video", "music"]


class SearchResponse(BaseModel):
    results: list[dict]
    total: int
    query: str
    platforms: list[str]


@router.get("/search")
async def search(
    q: str = Query(..., min_length=1, max_length=200),
    platforms: str = Query("youtube,spotify,soundcloud"),
    countries: str = Query("US"),
    types: str = Query("video,music"),
    limit: int = Query(20, ge=1, le=50),
    profile_id: str | None = Query(None),
):
    """
    Search videos and music across social media platforms.

    - **q**: search query
    - **platforms**: comma-separated: youtube, tiktok, spotify, soundcloud, instagram
    - **countries**: comma-separated ISO 3166-1 alpha-2 codes (US, JP, KR, BR...)
    - **types**: comma-separated: video, music
    - **limit**: max results per platform
    - **profile_id**: optional — saves to search_history and applies user preferences
    """
    platform_list = [p.strip() for p in platforms.split(",")]
    country_list  = [c.strip().upper() for c in countries.split(",")]
    type_list     = [t.strip() for t in types.split(",")]

    # If profile provided, merge with their saved preferences
    if profile_id:
        prefs = await _get_user_prefs(profile_id)
        if prefs:
            if not country_list or country_list == ["US"]:
                country_list = prefs.get("countries") or country_list
            if not platform_list:
                platform_list = prefs.get("platforms") or platform_list

    results = await aggregate_search(
        query=q,
        platforms=platform_list,
        countries=country_list,
        item_types=type_list,
        max_per_platform=limit,
    )

    # Persist search history (fire and forget)
    if profile_id:
        import asyncio
        asyncio.create_task(_save_search_history(profile_id, q, platform_list, len(results)))

    return SearchResponse(
        results=[_result_to_dict(r) for r in results],
        total=len(results),
        query=q,
        platforms=platform_list,
    )


@router.get("/search/similar")
async def similar_videos(video_id: str, limit: int = Query(10, ge=1, le=30)):
    """Find videos similar to a given video using pgvector cosine similarity."""
    pool = await get_pool()
    rows = await pool.fetch(
        """
        SELECT v.id, v.url, v.thumbnail, v.caption, v.tags,
               1 - (v.embedding <=> src.embedding) AS similarity
        FROM videos v
        JOIN videos src ON src.id = $1
        WHERE v.id != $1
          AND v.embedding IS NOT NULL
          AND src.embedding IS NOT NULL
        ORDER BY v.embedding <=> src.embedding
        LIMIT $2
        """,
        video_id, limit,
    )
    return {"results": [dict(r) for r in rows]}


def _result_to_dict(r: SearchResult) -> dict:
    return {
        "platform": r.platform,
        "item_type": r.item_type,
        "external_id": r.external_id,
        "title": r.title,
        "author_name": r.author_name,
        "thumbnail_url": r.thumbnail_url,
        "media_url": r.media_url,
        "duration": r.duration,
        "view_count": r.view_count,
        "like_count": r.like_count,
        "country": r.country,
        "tags": r.tags,
        "metadata": r.metadata,
    }


async def _get_user_prefs(profile_id: str) -> dict | None:
    pool = await get_pool()
    row = await pool.fetchrow(
        "SELECT countries, platforms, music_genres, video_types FROM user_preferences WHERE profile_id = $1",
        profile_id,
    )
    return dict(row) if row else None


async def _save_search_history(profile_id: str, query: str, platforms: list[str], count: int):
    pool = await get_pool()
    await pool.execute(
        "INSERT INTO search_history (profile_id, query, platforms, result_count) VALUES ($1, $2, $3, $4)",
        profile_id, query, platforms, count,
    )
