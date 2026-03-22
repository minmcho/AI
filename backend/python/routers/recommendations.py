from fastapi import APIRouter, Query
from models.database import get_pool

router = APIRouter()


@router.get("/recommendations/{profile_id}")
async def personalised_feed(
    profile_id: str,
    limit: int = Query(20, ge=1, le=50),
):
    """
    Returns a personalised video feed using pgvector cosine similarity
    between the user's preference embedding and video embeddings.
    Falls back to recency-ordered feed if no preference embedding exists.
    """
    pool = await get_pool()

    # Try personalised (pgvector RPC)
    rows = await pool.fetch(
        "SELECT * FROM personalised_feed($1, $2)",
        profile_id, limit,
    )

    if rows:
        return {"videos": [dict(r) for r in rows], "mode": "personalised"}

    # Fallback: recency feed
    rows = await pool.fetch(
        """
        SELECT id, url, thumbnail, caption, likes, comments, shares,
               duration, tags, mix_track_url, created_at,
               0.0 AS similarity
        FROM videos ORDER BY created_at DESC LIMIT $1
        """,
        limit,
    )
    return {"videos": [dict(r) for r in rows], "mode": "recency"}


@router.get("/recommendations/{profile_id}/music")
async def recommended_music(
    profile_id: str,
    limit: int = Query(20, ge=1, le=50),
):
    """Return music tracks matching the user's genre/mood preferences."""
    pool = await get_pool()
    prefs = await pool.fetchrow(
        "SELECT music_genres, music_moods, countries FROM user_preferences WHERE profile_id = $1",
        profile_id,
    )
    if not prefs:
        return {"tracks": [], "mode": "no_preferences"}

    genres   = list(prefs["music_genres"] or [])
    moods    = list(prefs["music_moods"] or [])
    countries = list(prefs["countries"] or [])

    # Query favorites that match genre/mood tags
    rows = await pool.fetch(
        """
        SELECT f.*, f.metadata->>'genre' AS genre
        FROM favorites f
        WHERE f.profile_id = $1
          AND f.item_type IN ('music', 'social_music')
          AND (
            f.metadata->>'genre' = ANY($2::text[])
            OR f.tags && $2::text[]
          )
        ORDER BY f.created_at DESC
        LIMIT $3
        """,
        profile_id, genres or moods, limit,
    )
    return {"tracks": [dict(r) for r in rows], "mode": "preference_matched"}
