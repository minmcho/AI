from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
from routers import transcribe, dub, music, jobs, openclaw_webhooks, search, preferences, favorites, recommendations
from models.database import init_db


@asynccontextmanager
async def lifespan(app: FastAPI):
    await init_db()
    yield


app = FastAPI(
    title="VideoFeed AI Service",
    description="OpenClaw agents + Gemini for transcription, dubbing, and music generation",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(transcribe.router, prefix="/ai", tags=["Transcription"])
app.include_router(dub.router, prefix="/ai", tags=["Dubbing"])
app.include_router(music.router, prefix="/ai", tags=["Music"])
app.include_router(jobs.router, prefix="/ai", tags=["Jobs"])
app.include_router(openclaw_webhooks.router, prefix="/ai/openclaw",  tags=["OpenClaw"])
app.include_router(search.router,           prefix="/ai",           tags=["Search"])
app.include_router(preferences.router,      prefix="/ai",           tags=["Preferences"])
app.include_router(favorites.router,        prefix="/ai",           tags=["Favorites"])
app.include_router(recommendations.router,  prefix="/ai",           tags=["Recommendations"])


@app.get("/health")
async def health():
    return {"status": "ok"}
