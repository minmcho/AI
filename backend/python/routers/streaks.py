"""
Streak & XP system — Duolingo-style engagement loop for teens/college students.
"""

from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel
from models.database import get_pool

router = APIRouter()

# XP values per action
XP_TABLE = {
    "watch":           10,
    "like":             5,
    "share":           15,
    "save":            10,
    "challenge_join":  50,
    "challenge_create":150,
    "challenge_win":   300,
    "daily_login":     25,
    "study_session":   50,    # per completed pomodoro
    "sound_identify":   5,
    "vibe_match_share": 20,
}

BADGE_DEFS = {
    "first_watch":     {"label": "First Watch",     "emoji": "👀", "xp": 0},
    "week_warrior":    {"label": "7-Day Streak",    "emoji": "🔥", "xp": 7},
    "monthly_legend":  {"label": "30-Day Legend",   "emoji": "👑", "xp": 30},
    "challenge_champ": {"label": "Challenge Champ", "emoji": "🏆", "xp": 0},
    "study_grind":     {"label": "Study Grinder",   "emoji": "📚", "xp": 0},
    "vibe_master":     {"label": "Vibe Master",     "emoji": "💫", "xp": 0},
    "lofi_lord":       {"label": "Lofi Lord",       "emoji": "🎧", "xp": 0},
}

LEVEL_TITLES = {
    1: "Newbie",    2: "Explorer",   3: "Viber",
    4: "Trendsetter", 5: "Influencer", 6: "Icon",
    7: "Legend",    8: "Superstar",  9: "GOD Mode",
}


class AwardXPRequest(BaseModel):
    profile_id: str
    action:     str
    metadata:   dict = {}


@router.get("/streak/{profile_id}")
async def get_streak(profile_id: str):
    pool = await get_pool()
    row = await pool.fetchrow(
        """
        SELECT streak_days, longest_streak, total_xp, level, badges, last_active
        FROM user_streaks WHERE profile_id = $1
        """,
        profile_id,
    )
    if not row:
        return {
            "streak_days": 0, "longest_streak": 0,
            "total_xp": 0, "level": 1, "level_title": "Newbie",
            "badges": [], "next_level_xp": 50, "xp_progress": 0,
        }

    level = row["level"]
    next_level_xp = (level ** 2) * 50
    current_level_xp = ((level - 1) ** 2) * 50
    xp_in_level = row["total_xp"] - current_level_xp
    progress = min(1.0, xp_in_level / max(1, next_level_xp - current_level_xp))

    return {
        "streak_days":   row["streak_days"],
        "longest_streak": row["longest_streak"],
        "total_xp":      row["total_xp"],
        "level":         level,
        "level_title":   LEVEL_TITLES.get(min(level, 9), "GOD Mode"),
        "badges":        list(row["badges"] or []),
        "next_level_xp": next_level_xp,
        "xp_progress":   round(progress, 3),
        "last_active":   str(row["last_active"]),
    }


@router.post("/streak/award")
async def award_xp(req: AwardXPRequest):
    if req.action not in XP_TABLE:
        raise HTTPException(status_code=422, detail=f"Unknown action: {req.action}")

    xp = XP_TABLE[req.action]
    result = await award_xp_internal(req.profile_id, req.action, xp, req.metadata)
    return {
        "xp_earned":    xp,
        "new_xp":       result["new_xp"],
        "new_level":    result["new_level"],
        "new_streak":   result["new_streak"],
        "badge_awarded": result["badge_awarded"],
        "level_title":  LEVEL_TITLES.get(min(result["new_level"], 9), "GOD Mode"),
    }


@router.get("/streak/{profile_id}/leaderboard")
async def global_leaderboard(limit: int = Query(20, ge=1, le=50)):
    """Top users by XP — shows up on the Challenge Hub leaderboard."""
    pool = await get_pool()
    rows = await pool.fetch(
        """
        SELECT p.username, p.avatar_url, us.total_xp, us.level,
               us.streak_days, us.badges,
               RANK() OVER (ORDER BY us.total_xp DESC) AS rank
        FROM user_streaks us
        JOIN profiles p ON p.id = us.profile_id
        ORDER BY us.total_xp DESC
        LIMIT $1
        """,
        limit,
    )
    return {"leaderboard": [dict(r) for r in rows]}


@router.get("/badges")
async def list_badges():
    return {"badges": BADGE_DEFS}


# ── Internal helper (called from other routers) ───────────────────────────────

async def award_xp_internal(
    profile_id: str,
    action: str,
    xp: int,
    metadata: dict = {},
) -> dict:
    pool = await get_pool()

    # Upsert streak row first
    await pool.execute(
        "INSERT INTO user_streaks (profile_id) VALUES ($1) ON CONFLICT DO NOTHING",
        profile_id,
    )

    rows = await pool.fetch(
        "SELECT * FROM award_xp($1, $2, $3, $4::jsonb)",
        profile_id, action, xp, str(metadata).replace("'", '"'),
    )
    if rows:
        r = rows[0]
        return {
            "new_xp":      r["new_xp"],
            "new_level":   r["new_level"],
            "new_streak":  r["new_streak"],
            "badge_awarded": r["badge_awarded"],
        }
    return {"new_xp": xp, "new_level": 1, "new_streak": 1, "badge_awarded": None}
