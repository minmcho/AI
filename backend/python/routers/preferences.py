from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from models.database import get_pool
from agents.gemini_agent import embed_text

router = APIRouter()

MUSIC_GENRES  = ["electronic", "hiphop", "lofi", "pop", "ambient", "edm", "jazz", "classical", "rock", "rnb"]
MUSIC_MOODS   = ["energetic", "chill", "dramatic", "uplifting", "dark", "romantic", "focused"]
VIDEO_TYPES   = ["dance", "comedy", "travel", "food", "sports", "tech", "fashion", "gaming", "animation", "art", "fitness", "education"]
PLATFORMS     = ["youtube", "tiktok", "instagram", "spotify", "soundcloud"]
COUNTRIES     = [
    {"code": "US", "name": "United States", "flag": "🇺🇸"},
    {"code": "JP", "name": "Japan",         "flag": "🇯🇵"},
    {"code": "KR", "name": "South Korea",   "flag": "🇰🇷"},
    {"code": "BR", "name": "Brazil",        "flag": "🇧🇷"},
    {"code": "IN", "name": "India",         "flag": "🇮🇳"},
    {"code": "GB", "name": "United Kingdom","flag": "🇬🇧"},
    {"code": "DE", "name": "Germany",       "flag": "🇩🇪"},
    {"code": "FR", "name": "France",        "flag": "🇫🇷"},
    {"code": "MX", "name": "Mexico",        "flag": "🇲🇽"},
    {"code": "ID", "name": "Indonesia",     "flag": "🇮🇩"},
    {"code": "TH", "name": "Thailand",      "flag": "🇹🇭"},
    {"code": "PH", "name": "Philippines",   "flag": "🇵🇭"},
    {"code": "NG", "name": "Nigeria",       "flag": "🇳🇬"},
    {"code": "EG", "name": "Egypt",         "flag": "🇪🇬"},
    {"code": "AU", "name": "Australia",     "flag": "🇦🇺"},
    {"code": "CA", "name": "Canada",        "flag": "🇨🇦"},
    {"code": "AR", "name": "Argentina",     "flag": "🇦🇷"},
    {"code": "ZA", "name": "South Africa",  "flag": "🇿🇦"},
    {"code": "TR", "name": "Turkey",        "flag": "🇹🇷"},
    {"code": "ES", "name": "Spain",         "flag": "🇪🇸"},
]


class PreferenceUpdate(BaseModel):
    music_genres:     list[str] = []
    music_moods:      list[str] = []
    video_types:      list[str] = []
    countries:        list[str] = []
    platforms:        list[str] = []
    prefer_dubbed:    bool = False
    prefer_subtitles: bool = False
    autoplay_muted:   bool = False


@router.get("/preferences/options")
async def get_options():
    """Return all valid preference options for the iOS picker UI."""
    return {
        "music_genres": MUSIC_GENRES,
        "music_moods":  MUSIC_MOODS,
        "video_types":  VIDEO_TYPES,
        "platforms":    PLATFORMS,
        "countries":    COUNTRIES,
    }


@router.get("/preferences/{profile_id}")
async def get_preferences(profile_id: str):
    pool = await get_pool()
    row = await pool.fetchrow(
        """
        SELECT music_genres, music_moods, video_types, countries, platforms,
               prefer_dubbed, prefer_subtitles, autoplay_muted
        FROM user_preferences WHERE profile_id = $1
        """,
        profile_id,
    )
    if not row:
        return PreferenceUpdate()  # return defaults
    return dict(row)


@router.put("/preferences/{profile_id}")
async def upsert_preferences(profile_id: str, prefs: PreferenceUpdate):
    pool = await get_pool()
    await pool.execute(
        """
        INSERT INTO user_preferences
            (profile_id, music_genres, music_moods, video_types, countries, platforms,
             prefer_dubbed, prefer_subtitles, autoplay_muted, updated_at)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, NOW())
        ON CONFLICT (profile_id) DO UPDATE SET
            music_genres     = EXCLUDED.music_genres,
            music_moods      = EXCLUDED.music_moods,
            video_types      = EXCLUDED.video_types,
            countries        = EXCLUDED.countries,
            platforms        = EXCLUDED.platforms,
            prefer_dubbed    = EXCLUDED.prefer_dubbed,
            prefer_subtitles = EXCLUDED.prefer_subtitles,
            autoplay_muted   = EXCLUDED.autoplay_muted,
            updated_at       = NOW()
        """,
        profile_id,
        prefs.music_genres, prefs.music_moods, prefs.video_types,
        prefs.countries, prefs.platforms,
        prefs.prefer_dubbed, prefs.prefer_subtitles, prefs.autoplay_muted,
    )

    # Recompute preference embedding for personalised feed
    import asyncio
    asyncio.create_task(_recompute_embedding(profile_id, prefs))

    return {"ok": True}


async def _recompute_embedding(profile_id: str, prefs: PreferenceUpdate):
    """Build a text description of preferences → embed with Gemini → store in pgvector."""
    text = (
        f"Music genres: {', '.join(prefs.music_genres)}. "
        f"Moods: {', '.join(prefs.music_moods)}. "
        f"Video types: {', '.join(prefs.video_types)}. "
        f"Countries: {', '.join(prefs.countries)}."
    )
    try:
        embedding = await embed_text(text)
        pool = await get_pool()
        await pool.execute(
            "UPDATE user_preferences SET preference_embedding = $2 WHERE profile_id = $1",
            profile_id, embedding,
        )
    except Exception as e:
        import logging
        logging.getLogger(__name__).error("Embedding update failed: %s", e)
