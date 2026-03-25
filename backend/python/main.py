from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
from routers import (
    transcribe, dub, music, jobs, openclaw_webhooks,
    search, preferences, favorites, recommendations,
    mood_feed, challenges, streaks, vibe_match, study,
    cargo, defects, ml,
)
from models.database import init_db


@asynccontextmanager
async def lifespan(app: FastAPI):
    await init_db()
    yield


app = FastAPI(
    title="CargoTrack AI Service",
    description=(
        "Real-time cargo tracking + logistics platform — "
        "defect detection, clustering, classification, "
        "semantic vector search (pgvector), and Claude reasoning "
        "with content caching."
    ),
    version="2.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Legacy video feed routes (kept for backwards-compat) ──────────────────────
app.include_router(transcribe.router,       prefix="/ai",          tags=["Transcription"])
app.include_router(dub.router,              prefix="/ai",          tags=["Dubbing"])
app.include_router(music.router,            prefix="/ai",          tags=["Music"])
app.include_router(jobs.router,             prefix="/ai",          tags=["Jobs"])
app.include_router(openclaw_webhooks.router,prefix="/ai/openclaw", tags=["OpenClaw"])
app.include_router(search.router,           prefix="/ai",          tags=["Search"])
app.include_router(preferences.router,      prefix="/ai",          tags=["Preferences"])
app.include_router(favorites.router,        prefix="/ai",          tags=["Favorites"])
app.include_router(recommendations.router,  prefix="/ai",          tags=["Recommendations"])
app.include_router(mood_feed.router,        prefix="/ai",          tags=["Mood Feed"])
app.include_router(challenges.router,       prefix="/ai",          tags=["Challenges"])
app.include_router(streaks.router,          prefix="/ai",          tags=["Streaks & XP"])
app.include_router(vibe_match.router,       prefix="/ai",          tags=["Vibe Match"])
app.include_router(study.router,            prefix="/ai",          tags=["Study Mode"])

# ── CargoTrack routes ─────────────────────────────────────────────────────────
app.include_router(cargo.router,            tags=["Cargo & Org"])
app.include_router(defects.router,          tags=["Defect Detection"])
app.include_router(ml.router,               tags=["ML — Clustering, Classification, Reasoning"])


@app.get("/health")
async def health():
    return {"status": "ok", "service": "cargotrack-ai"}
