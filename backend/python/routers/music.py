from fastapi import APIRouter, BackgroundTasks
from pydantic import BaseModel
from agents.openclaw_agent import generate_music
from models.database import create_job, update_job
import httpx, os

router = APIRouter()


class MusicRequest(BaseModel):
    video_id: str
    genre: str = "electronic"
    mood: str = "energetic"
    duration: int = 30


@router.post("/music")
async def generate_mix(req: MusicRequest, bg: BackgroundTasks):
    job_id = await create_job("music", req.video_id)
    bg.add_task(_run_music_generation, job_id, req.video_id, req.genre, req.mood, req.duration)
    return {"job_id": job_id, "status": "pending"}


async def _run_music_generation(job_id: str, video_id: str, genre: str, mood: str, duration: int):
    await update_job(job_id, "running")
    try:
        audio_url = await generate_music(genre, mood, duration)

        # Persist mix_track_url back to the video row
        supabase_url = os.environ["SUPABASE_URL"]
        anon_key = os.environ["SUPABASE_ANON_KEY"]
        async with httpx.AsyncClient() as client:
            await client.patch(
                f"{supabase_url}/rest/v1/videos?id=eq.{video_id}",
                json={"mix_track_url": audio_url},
                headers={
                    "apikey": anon_key,
                    "Authorization": f"Bearer {anon_key}",
                    "Content-Type": "application/json",
                    "Prefer": "return=minimal",
                },
            )

        await update_job(job_id, "completed", result=audio_url)
    except Exception as e:
        await update_job(job_id, "failed", error=str(e))
