"""
Mood Feed — returns videos tagged with the requested mood.
Moods: hype | chill | sad | funny | study | dance | romantic | gaming | asmr
"""

from fastapi import APIRouter, Query
from models.database import get_pool

router = APIRouter()

VALID_MOODS = ["hype", "chill", "sad", "funny", "study", "dance", "romantic", "gaming", "asmr"]

MOOD_META = {
    "hype":     {"emoji": "🔥", "label": "Hype",     "color": "#FF4500"},
    "chill":    {"emoji": "😌", "label": "Chill",    "color": "#5AC8FA"},
    "sad":      {"emoji": "😭", "label": "Sad",      "color": "#5856D6"},
    "funny":    {"emoji": "😂", "label": "Funny",    "color": "#FFD60A"},
    "study":    {"emoji": "📚", "label": "Study",    "color": "#34C759"},
    "dance":    {"emoji": "💃", "label": "Dance",    "color": "#FF2D92"},
    "romantic": {"emoji": "💕", "label": "Romantic", "color": "#FF6B6B"},
    "gaming":   {"emoji": "🎮", "label": "Gaming",   "color": "#BF5AF2"},
    "asmr":     {"emoji": "🎧", "label": "ASMR",     "color": "#30D158"},
}


@router.get("/moods")
async def list_moods():
    """Return all available moods with metadata for the iOS mood selector."""
    return {
        "moods": [
            {"id": mood, **MOOD_META[mood]} for mood in VALID_MOODS
        ]
    }


@router.get("/feed/mood")
async def mood_feed(
    mood: str = Query(..., description="One of: hype, chill, sad, funny, study, dance, romantic, gaming, asmr"),
    campus: str | None = Query(None, description="Optional campus filter e.g. UCLA"),
    limit: int = Query(20, ge=1, le=50),
):
    """Fetch videos matching a mood. Uses the mood_feed() Supabase RPC."""
    if mood not in VALID_MOODS:
        from fastapi import HTTPException
        raise HTTPException(status_code=422, detail=f"Invalid mood. Choose from: {', '.join(VALID_MOODS)}")

    pool = await get_pool()
    rows = await pool.fetch(
        "SELECT * FROM mood_feed($1, $2, $3)",
        mood, limit, campus,
    )
    return {
        "mood": mood,
        "meta": MOOD_META[mood],
        "videos": [dict(r) for r in rows],
        "total": len(rows),
    }


@router.post("/feed/mood/tag")
async def tag_video_mood(video_id: str, moods: list[str]):
    """Add mood tags to a video (service-level, called by AI tagging pipeline)."""
    valid = [m for m in moods if m in VALID_MOODS]
    if not valid:
        return {"ok": False, "reason": "no valid moods"}
    pool = await get_pool()
    await pool.execute(
        "UPDATE videos SET mood_tags = array_distinct(mood_tags || $2::text[]) WHERE id = $1",
        video_id, valid,
    )
    return {"ok": True, "tagged": valid}
