"""
Vibe Match — find users with similar taste profiles using pgvector cosine similarity.
Perfect for teens and college students discovering their "vibe twin".
"""

from fastapi import APIRouter, Query, HTTPException
from models.database import get_pool

router = APIRouter()


@router.get("/vibe-match/{profile_id}")
async def find_vibe_matches(
    profile_id: str,
    limit: int = Query(10, ge=1, le=30),
):
    """
    Returns users whose preference_embedding is closest to yours.
    Uses the vibe_match() Supabase RPC (pgvector HNSW cosine similarity).
    """
    pool = await get_pool()

    # Check if the user has a preference embedding
    has_embedding = await pool.fetchval(
        "SELECT preference_embedding IS NOT NULL FROM user_preferences WHERE profile_id = $1",
        profile_id,
    )
    if not has_embedding:
        return {
            "matches": [],
            "message": "Save your preferences first to find vibe matches!",
            "has_embedding": False,
        }

    rows = await pool.fetch(
        "SELECT * FROM vibe_match($1, $2)",
        profile_id, limit,
    )
    return {
        "matches": [
            {
                "profile_id":   str(r["profile_id"]),
                "username":     r["username"],
                "avatar_url":   r["avatar_url"],
                "similarity":   round(float(r["similarity"]), 3),
                "similarity_pct": int(float(r["similarity"]) * 100),
                "shared_genres": list(r["shared_genres"] or []),
                "total_xp":     r["total_xp"],
                "badges":       list(r["badges"] or []),
            }
            for r in rows
        ],
        "has_embedding": True,
    }


@router.get("/vibe-match/{profile_id}/shared-favorites")
async def shared_favorites(
    profile_id: str,
    other_profile_id: str = Query(...),
    limit: int = Query(10, ge=1, le=20),
):
    """
    Returns favorites that both users have saved.
    Great for "you and @username both love..." social discovery.
    """
    pool = await get_pool()
    rows = await pool.fetch(
        """
        SELECT f1.external_id, f1.platform, f1.title, f1.thumbnail_url,
               f1.author_name, f1.item_type
        FROM favorites f1
        JOIN favorites f2 ON f2.external_id = f1.external_id
                          AND f2.profile_id = $2
        WHERE f1.profile_id = $1
          AND f1.external_id IS NOT NULL
        LIMIT $3
        """,
        profile_id, other_profile_id, limit,
    )
    return {"shared": [dict(r) for r in rows], "count": len(rows)}


@router.get("/vibe-match/{profile_id}/campus")
async def campus_vibe_match(
    profile_id: str,
    campus: str = Query(..., description="University name, e.g. UCLA"),
    limit: int = Query(10, ge=1, le=20),
):
    """Find vibe matches specifically within your campus."""
    pool = await get_pool()

    # Get the calling user's embedding
    emb = await pool.fetchval(
        "SELECT preference_embedding FROM user_preferences WHERE profile_id = $1",
        profile_id,
    )
    if not emb:
        raise HTTPException(status_code=400, detail="No preference embedding found.")

    rows = await pool.fetch(
        """
        SELECT p.id AS profile_id, p.username, p.avatar_url,
               1 - (up.preference_embedding <=> $2::vector) AS similarity
        FROM user_preferences up
        JOIN profiles p ON p.id = up.profile_id
        WHERE up.profile_id != $1
          AND up.preference_embedding IS NOT NULL
          AND EXISTS (
              SELECT 1 FROM videos v
              WHERE v.profile_id = p.id
                AND v.campus_tag ILIKE $3
          )
        ORDER BY up.preference_embedding <=> $2::vector
        LIMIT $4
        """,
        profile_id, emb, campus, limit,
    )
    return {
        "campus": campus,
        "matches": [dict(r) for r in rows],
    }
