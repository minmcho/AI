"""
Demo mode — in-memory mock "pool" that returns realistic sample data
when no DATABASE_URL is configured.  Used for local development without Supabase.
"""
import json
from datetime import datetime, timezone

# ── Sample data ───────────────────────────────────────────────────────────────
DEMO_VIDEOS = [
    {
        "id": "10000000-0000-0000-0000-000000000001",
        "url": "https://storage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
        "thumbnail": "https://peach.blender.org/wp-content/uploads/bbb-splash.png",
        "caption": "Big Buck Bunny — open-source animation classic 🐰 #animation #fun",
        "likes": 1204, "comments": 88, "shares": 42, "duration": 596,
        "tags": ["animation", "fun", "classic"],
        "mood_tags": ["funny", "chill"],
        "mix_track_url": None,
        "campus_tag": None,
        "created_at": "2026-03-20T10:00:00Z",
    },
    {
        "id": "10000000-0000-0000-0000-000000000002",
        "url": "https://storage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
        "thumbnail": "https://upload.wikimedia.org/wikipedia/commons/thumb/e/e8/Elephants_Dream_s5_both.jpg/320px-Elephants_Dream_s5_both.jpg",
        "caption": "Elephants Dream — surreal sci-fi short 🤖 #scifi #art",
        "likes": 876, "comments": 53, "shares": 31, "duration": 654,
        "tags": ["scifi", "art", "animation"],
        "mood_tags": ["hype", "study"],
        "mix_track_url": None,
        "campus_tag": "MIT",
        "created_at": "2026-03-19T15:00:00Z",
    },
    {
        "id": "10000000-0000-0000-0000-000000000003",
        "url": "https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
        "thumbnail": "https://storage.googleapis.com/gtv-videos-bucket/sample/images/ForBiggerBlazes.jpg",
        "caption": "For Bigger Blazes 🔥 #hype #action",
        "likes": 2341, "comments": 140, "shares": 95, "duration": 15,
        "tags": ["action", "hype", "short"],
        "mood_tags": ["hype", "dance"],
        "mix_track_url": None,
        "campus_tag": "UCLA",
        "created_at": "2026-03-18T12:00:00Z",
    },
    {
        "id": "10000000-0000-0000-0000-000000000004",
        "url": "https://storage.googleapis.com/gtv-videos-bucket/sample/SubaruOutbackOnStreetAndDirt.mp4",
        "thumbnail": "https://storage.googleapis.com/gtv-videos-bucket/sample/images/SubaruOutbackOnStreetAndDirt.jpg",
        "caption": "Chill drive vibes 🚗 lofi beats #chill #travel",
        "likes": 543, "comments": 22, "shares": 11, "duration": 60,
        "tags": ["travel", "chill", "lofi"],
        "mood_tags": ["chill", "study", "asmr"],
        "mix_track_url": None,
        "campus_tag": None,
        "created_at": "2026-03-17T08:00:00Z",
    },
    {
        "id": "10000000-0000-0000-0000-000000000005",
        "url": "https://storage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4",
        "thumbnail": "https://storage.googleapis.com/gtv-videos-bucket/sample/images/TearsOfSteel.jpg",
        "caption": "Tears of Steel — Blender open movie 🎬 #cinematic #emotional",
        "likes": 1892, "comments": 203, "shares": 87, "duration": 734,
        "tags": ["cinematic", "emotional", "scifi"],
        "mood_tags": ["sad", "romantic"],
        "mix_track_url": None,
        "campus_tag": None,
        "created_at": "2026-03-16T20:00:00Z",
    },
]

DEMO_CHALLENGES = [
    {
        "id": "c0000000-0000-0000-0000-000000000001",
        "title": "Dorm Room DJ Battle",
        "description": "Show us your best bedroom DJ setup and mix! 🎧",
        "hashtag": "#DormRoomDJ",
        "category": "music",
        "thumbnail_url": None,
        "participant_count": 2341,
        "view_count": 98200,
        "is_featured": True,
        "ends_at": "2026-04-01T00:00:00Z",
        "creator_username": "demo_user",
        "creator_avatar": None,
    },
    {
        "id": "c0000000-0000-0000-0000-000000000002",
        "title": "Study With Me 25",
        "description": "Post your best 25-min study session! Pomodoro crew 📚",
        "hashtag": "#StudyWithMe25",
        "category": "study",
        "thumbnail_url": None,
        "participant_count": 5876,
        "view_count": 210400,
        "is_featured": True,
        "ends_at": "2026-04-15T00:00:00Z",
        "creator_username": "travel_benny",
        "creator_avatar": None,
    },
    {
        "id": "c0000000-0000-0000-0000-000000000003",
        "title": "Campus Glow Up",
        "description": "Show your university campus in its best light ✨",
        "hashtag": "#CampusGlowUp",
        "category": "travel",
        "thumbnail_url": None,
        "participant_count": 1123,
        "view_count": 44800,
        "is_featured": False,
        "ends_at": "2026-05-01T00:00:00Z",
        "creator_username": "demo_user",
        "creator_avatar": None,
    },
]

DEMO_LEADERBOARD = [
    {"rank": 1, "username": "vibemaster99",  "avatar_url": "https://i.pravatar.cc/150?u=1", "video_id": None, "likes": 4201},
    {"rank": 2, "username": "lofi_queen",    "avatar_url": "https://i.pravatar.cc/150?u=2", "video_id": None, "likes": 3540},
    {"rank": 3, "username": "studygrinder",  "avatar_url": "https://i.pravatar.cc/150?u=3", "video_id": None, "likes": 2988},
    {"rank": 4, "username": "campus_kid",    "avatar_url": "https://i.pravatar.cc/150?u=4", "video_id": None, "likes": 1740},
    {"rank": 5, "username": "dj_dormlife",   "avatar_url": "https://i.pravatar.cc/150?u=5", "video_id": None, "likes": 1202},
]

DEMO_STREAK = {
    "streak_days": 7, "longest_streak": 14, "total_xp": 2450,
    "level": 7, "level_title": "Legend",
    "badges": ["first_watch", "week_warrior"],
    "next_level_xp": 3200, "xp_progress": 0.72,
    "last_active": str(datetime.now(timezone.utc).date()),
}

DEMO_VIBE_MATCHES = [
    {
        "profile_id": "00000000-0000-0000-0000-000000000099",
        "username": "lofi_queen",
        "avatar_url": "https://i.pravatar.cc/150?u=lofi",
        "similarity": 0.94, "similarity_pct": 94,
        "shared_genres": ["lofi", "electronic"],
        "total_xp": 5200,
        "badges": ["week_warrior", "study_grind"],
    },
    {
        "profile_id": "00000000-0000-0000-0000-000000000098",
        "username": "kpop_dan",
        "avatar_url": "https://i.pravatar.cc/150?u=kpop",
        "similarity": 0.88, "similarity_pct": 88,
        "shared_genres": ["kpop", "pop"],
        "total_xp": 3100,
        "badges": ["first_watch"],
    },
    {
        "profile_id": "00000000-0000-0000-0000-000000000097",
        "username": "studygrinder",
        "avatar_url": "https://i.pravatar.cc/150?u=study",
        "similarity": 0.81, "similarity_pct": 81,
        "shared_genres": ["lofi", "ambient"],
        "total_xp": 7800,
        "badges": ["study_grind", "week_warrior", "monthly_legend"],
    },
]


class MockRecord(dict):
    """Dict that also supports attribute-style access like asyncpg records."""
    def __getattr__(self, k):
        try:
            return self[k]
        except KeyError:
            raise AttributeError(k)


class MockPool:
    """Fake asyncpg pool that returns demo data for all queries."""

    async def fetch(self, query: str, *args) -> list:
        q = query.lower()
        if "from videos" in q or "mood_feed" in q:
            mood = args[0] if args and isinstance(args[0], str) else None
            vids = DEMO_VIDEOS
            if mood:
                vids = [v for v in DEMO_VIDEOS if mood in v.get("mood_tags", [])]
            return [MockRecord(v) for v in vids[:int(args[1]) if len(args) > 1 and isinstance(args[1], int) else 20]]
        if "from challenges" in q:
            return [MockRecord(c) for c in DEMO_CHALLENGES]
        if "challenge_leaderboard" in q or "leaderboard" in q:
            return [MockRecord(e) for e in DEMO_LEADERBOARD]
        if "user_streaks" in q:
            return []
        if "from favorites" in q:
            return []
        if "search_history" in q:
            return []
        if "vibe_match" in q:
            return [MockRecord(m) for m in DEMO_VIBE_MATCHES]
        if "from study_sessions" in q:
            return [MockRecord({"total_sessions": 5, "total_minutes": 125,
                                "total_hours": 2.1, "total_pomodoros": 5,
                                "best_session_pomodoros": 2, "subjects": ["CS", "Math"]})]
        return []

    async def fetchrow(self, query: str, *args):
        q = query.lower()
        if "from challenges" in q and args:
            for c in DEMO_CHALLENGES:
                if str(args[0]) == c["id"]:
                    return MockRecord(c)
        if "user_preferences" in q:
            return MockRecord({
                "music_genres": ["electronic", "lofi"],
                "music_moods": ["chill", "energetic"],
                "video_types": ["animation", "travel"],
                "countries": ["US", "JP"],
                "platforms": ["youtube", "spotify"],
                "prefer_dubbed": False,
                "prefer_subtitles": False,
                "autoplay_muted": False,
            })
        if "user_streaks" in q:
            return MockRecord(DEMO_STREAK)
        if "from videos" in q:
            return MockRecord(DEMO_VIDEOS[0]) if DEMO_VIDEOS else None
        return None

    async def fetchval(self, query: str, *args):
        return None

    async def execute(self, query: str, *args):
        return "OK"

    async def acquire(self):
        return self

    async def __aenter__(self):
        return self

    async def __aexit__(self, *_):
        pass
