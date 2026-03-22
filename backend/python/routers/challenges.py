"""
Challenge Hub — viral video challenges for teens and college students.
"""

from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel
from models.database import get_pool
from routers.streaks import award_xp_internal

router = APIRouter()

CATEGORIES = ["dance", "comedy", "study", "music", "sports", "fashion", "gaming", "food", "travel", "general"]


class ChallengeCreate(BaseModel):
    creator_id:   str
    title:        str
    description:  str | None = None
    hashtag:      str
    category:     str = "general"
    target_mood:  str | None = None
    thumbnail_url: str | None = None
    ends_at:      str | None = None  # ISO 8601


class EntryCreate(BaseModel):
    profile_id: str
    video_id:   str | None = None


@router.get("/challenges")
async def list_challenges(
    category:  str | None = Query(None),
    featured:  bool       = Query(False),
    limit:     int        = Query(20, ge=1, le=50),
    offset:    int        = Query(0, ge=0),
):
    """Return active challenges. Teens see featured challenges first."""
    pool = await get_pool()

    filters = ["(ends_at IS NULL OR ends_at > NOW())"]
    params: list = []
    if category:
        params.append(category)
        filters.append(f"category = ${len(params)}")
    if featured:
        filters.append("is_featured = true")

    where = " AND ".join(filters)
    params += [limit, offset]
    rows = await pool.fetch(
        f"""
        SELECT c.*, p.username AS creator_username, p.avatar_url AS creator_avatar
        FROM challenges c
        LEFT JOIN profiles p ON p.id = c.creator_id
        WHERE {where}
        ORDER BY is_featured DESC, participant_count DESC, created_at DESC
        LIMIT ${len(params)-1} OFFSET ${len(params)}
        """,
        *params,
    )
    return {"challenges": [dict(r) for r in rows], "total": len(rows)}


@router.get("/challenges/{challenge_id}")
async def get_challenge(challenge_id: str):
    pool = await get_pool()
    row = await pool.fetchrow(
        """
        SELECT c.*, p.username AS creator_username, p.avatar_url AS creator_avatar
        FROM challenges c
        LEFT JOIN profiles p ON p.id = c.creator_id
        WHERE c.id = $1
        """,
        challenge_id,
    )
    if not row:
        raise HTTPException(status_code=404, detail="Challenge not found")
    return dict(row)


@router.post("/challenges")
async def create_challenge(data: ChallengeCreate):
    pool = await get_pool()

    # Ensure hashtag starts with #
    hashtag = data.hashtag if data.hashtag.startswith("#") else f"#{data.hashtag}"

    try:
        row = await pool.fetchrow(
            """
            INSERT INTO challenges
                (creator_id, title, description, hashtag, category, target_mood,
                 thumbnail_url, ends_at)
            VALUES ($1,$2,$3,$4,$5,$6,$7,$8::TIMESTAMPTZ)
            RETURNING id
            """,
            data.creator_id, data.title, data.description, hashtag,
            data.category, data.target_mood, data.thumbnail_url, data.ends_at,
        )
        # Award XP for creating a challenge
        await award_xp_internal(data.creator_id, "challenge_create", 150,
                                 {"challenge_id": str(row["id"])})
        return {"id": str(row["id"]), "ok": True}
    except Exception as e:
        if "unique" in str(e).lower():
            raise HTTPException(status_code=409, detail="Hashtag already taken")
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/challenges/{challenge_id}/join")
async def join_challenge(challenge_id: str, entry: EntryCreate):
    pool = await get_pool()
    try:
        row = await pool.fetchrow(
            """
            INSERT INTO challenge_entries (challenge_id, profile_id, video_id)
            VALUES ($1, $2, $3)
            ON CONFLICT (challenge_id, profile_id) DO NOTHING
            RETURNING id
            """,
            challenge_id, entry.profile_id, entry.video_id,
        )
        if row:
            # Increment participant count
            await pool.execute(
                "UPDATE challenges SET participant_count = participant_count + 1 WHERE id = $1",
                challenge_id,
            )
            # Award XP
            await award_xp_internal(entry.profile_id, "challenge_join", 50,
                                     {"challenge_id": challenge_id})
        return {"ok": True, "already_joined": row is None}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/challenges/{challenge_id}/leaderboard")
async def challenge_leaderboard(
    challenge_id: str,
    limit: int = Query(20, ge=1, le=50),
):
    pool = await get_pool()
    rows = await pool.fetch(
        "SELECT * FROM challenge_leaderboard($1, $2)",
        challenge_id, limit,
    )
    return {"leaderboard": [dict(r) for r in rows]}
