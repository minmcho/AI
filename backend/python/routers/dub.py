from fastapi import APIRouter, BackgroundTasks
from pydantic import BaseModel
from agents.gemini_agent import transcribe_video, translate_text
from agents.openclaw_agent import generate_tts
from models.database import create_job, update_job
import httpx, os

router = APIRouter()


class DubRequest(BaseModel):
    video_id: str
    target_language: str = "es"
    voice_persona: str = "energetic"


@router.post("/dub")
async def dub_video(req: DubRequest, bg: BackgroundTasks):
    job_id = await create_job("tts", req.video_id)
    bg.add_task(_run_dub_pipeline, job_id, req.video_id, req.target_language, req.voice_persona)
    return {"job_id": job_id, "status": "pending"}


async def _run_dub_pipeline(job_id: str, video_id: str, language: str, persona: str):
    await update_job(job_id, "running")
    try:
        video_url = await _get_video_url(video_id)

        # 1. Transcribe
        transcript = await transcribe_video(video_url)

        # 2. Translate via Gemini
        translated = await translate_text(transcript, language)

        # 3. Generate TTS via OpenClaw kokoro-tts skill
        audio_url = await generate_tts(translated, persona, language)

        # Store translated text as result; audio URL in result JSON
        import json
        await update_job(job_id, "completed", result=json.dumps({
            "transcript": transcript,
            "translated": translated,
            "audio_url": audio_url,
        }))
    except Exception as e:
        await update_job(job_id, "failed", error=str(e))


async def _get_video_url(video_id: str) -> str:
    supabase_url = os.environ["SUPABASE_URL"]
    anon_key = os.environ["SUPABASE_ANON_KEY"]
    async with httpx.AsyncClient() as client:
        resp = await client.get(
            f"{supabase_url}/rest/v1/videos?id=eq.{video_id}&select=url&limit=1",
            headers={"apikey": anon_key, "Authorization": f"Bearer {anon_key}"},
        )
        resp.raise_for_status()
        rows = resp.json()
        if not rows:
            raise ValueError(f"Video {video_id} not found")
        return rows[0]["url"]
