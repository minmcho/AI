"""
Study Mode — Pomodoro sessions with lofi music from the feed.
Targeted at college students grinding through finals and assignments.
"""

from fastapi import APIRouter, Query
from pydantic import BaseModel
from models.database import get_pool
from routers.streaks import award_xp_internal

router = APIRouter()

LOFI_TAGS = ["lofi", "study", "ambient", "chill", "focus", "instrumental"]


class StudySessionCreate(BaseModel):
    profile_id:    str
    duration_min:  int
    pomodoros:     int = 0
    lofi_video_id: str | None = None
    subject:       str | None = None


@router.get("/study/lofi-feed")
async def lofi_feed(
    limit: int = Query(15, ge=1, le=30),
    campus: str | None = Query(None),
):
    """
    Returns lofi / ambient / study videos perfect for Study Mode.
    Uses mood_tags='study' + lofi music from favorites/social search.
    """
    pool = await get_pool()
    rows = await pool.fetch(
        """
        SELECT id, url, thumbnail, caption, duration, tags, mix_track_url, mood_tags
        FROM videos
        WHERE (
            'study' = ANY(mood_tags)
            OR tags && $1::text[]
        )
        AND ($2::TEXT IS NULL OR campus_tag ILIKE $2)
        ORDER BY likes DESC, created_at DESC
        LIMIT $3
        """,
        LOFI_TAGS, campus, limit,
    )
    return {"videos": [dict(r) for r in rows]}


@router.post("/study/session")
async def log_study_session(session: StudySessionCreate):
    """
    Log a completed study session and award XP per pomodoro.
    25-min pomodoro = 50 XP. Earns 'study_grind' badge after 10 sessions.
    """
    pool = await get_pool()
    row = await pool.fetchrow(
        """
        INSERT INTO study_sessions
            (profile_id, duration_min, pomodoros, lofi_video_id, subject)
        VALUES ($1, $2, $3, $4, $5)
        RETURNING id
        """,
        session.profile_id, session.duration_min,
        session.pomodoros, session.lofi_video_id, session.subject,
    )

    total_xp_earned = 0
    for _ in range(session.pomodoros):
        result = await award_xp_internal(
            session.profile_id, "study_session", 50,
            {"pomodoros": session.pomodoros, "subject": session.subject},
        )
        total_xp_earned += 50

    # Check for study_grind badge (10 sessions total)
    session_count = await pool.fetchval(
        "SELECT COUNT(*) FROM study_sessions WHERE profile_id = $1",
        session.profile_id,
    )
    badge_awarded = None
    if session_count >= 10:
        has_badge = await pool.fetchval(
            "SELECT badges @> '{study_grind}' FROM user_streaks WHERE profile_id = $1",
            session.profile_id,
        )
        if not has_badge:
            await pool.execute(
                "UPDATE user_streaks SET badges = badges || '{study_grind}' WHERE profile_id = $1",
                session.profile_id,
            )
            badge_awarded = "study_grind"

    return {
        "session_id":    str(row["id"]),
        "xp_earned":     total_xp_earned,
        "badge_awarded": badge_awarded,
        "total_sessions": session_count,
    }


@router.get("/study/stats/{profile_id}")
async def study_stats(profile_id: str):
    """Return a student's study stats — total minutes, subjects, streaks."""
    pool = await get_pool()
    row = await pool.fetchrow(
        """
        SELECT
            COUNT(*)                          AS total_sessions,
            COALESCE(SUM(duration_min), 0)    AS total_minutes,
            COALESCE(SUM(pomodoros), 0)       AS total_pomodoros,
            COALESCE(MAX(pomodoros), 0)        AS best_session_pomodoros,
            ARRAY_AGG(DISTINCT subject)
              FILTER (WHERE subject IS NOT NULL) AS subjects
        FROM study_sessions
        WHERE profile_id = $1
        """,
        profile_id,
    )
    return {
        "total_sessions":          int(row["total_sessions"]),
        "total_minutes":           int(row["total_minutes"]),
        "total_hours":             round(int(row["total_minutes"]) / 60, 1),
        "total_pomodoros":         int(row["total_pomodoros"]),
        "best_session_pomodoros":  int(row["best_session_pomodoros"]),
        "subjects":                list(row["subjects"] or []),
    }
