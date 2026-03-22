from fastapi import APIRouter, BackgroundTasks, HTTPException
from pydantic import BaseModel
from agents.gemini_agent import transcribe_video, embed_text
from models.database import create_job, update_job, get_job, store_embedding
import httpx, os

router = APIRouter()


class TranscribeRequest(BaseModel):
    video_id: str
    language_hint: str = "en"


@router.post("/transcribe")
async def transcribe(req: TranscribeRequest, bg: BackgroundTasks):
    job_id = await create_job("transcription", req.video_id)
    bg.add_task(_run_transcription, job_id, req.video_id, req.language_hint)
    return {"job_id": job_id, "status": "pending"}


async def _run_transcription(job_id: str, video_id: str, language_hint: str):
    await update_job(job_id, "running")
    try:
        video_url = await _get_video_url(video_id)
        transcript = await transcribe_video(video_url, language_hint)

        # Store pgvector embedding for semantic search
        embedding = await embed_text(transcript)
        await store_embedding(video_id, embedding)

        await update_job(job_id, "completed", result=transcript)
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
