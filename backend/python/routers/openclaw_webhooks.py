"""
Inbound webhook endpoints for OpenClaw agent callbacks.
Also exposes endpoints that the iOS app calls directly for OpenClaw tasks.
"""

import hashlib, hmac, os
from fastapi import APIRouter, BackgroundTasks, Header, HTTPException, Request
from pydantic import BaseModel
from agents.openclaw_agent import generate_music, edit_video_with_dub
from models.database import create_job, update_job

router = APIRouter()

OPENCLAW_WEBHOOK_SECRET = os.environ.get("OPENCLAW_WEBHOOK_SECRET", "")


# ── Inbound webhook from OpenClaw (job completion callbacks) ─────────────────

@router.post("/webhook")
async def openclaw_webhook(request: Request, x_openclaw_signature: str = Header(default="")):
    body = await request.body()

    if OPENCLAW_WEBHOOK_SECRET:
        expected = hmac.new(OPENCLAW_WEBHOOK_SECRET.encode(), body, hashlib.sha256).hexdigest()
        if not hmac.compare_digest(expected, x_openclaw_signature):
            raise HTTPException(status_code=401, detail="Invalid signature")

    payload = await request.json()
    job_id = payload.get("job_id")
    status = payload.get("status")
    result = payload.get("output", {}).get("audio_url") or payload.get("output", {}).get("video_url")
    error = payload.get("error")

    if job_id:
        await update_job(job_id, status, result=result, error=error)

    return {"ok": True}


# ── iOS-initiated OpenClaw tasks ─────────────────────────────────────────────

class VideoEditRequest(BaseModel):
    video_id: str
    dub_audio_url: str
    language: str


@router.post("/video-edit")
async def video_edit(req: VideoEditRequest, bg: BackgroundTasks):
    job_id = await create_job("video_edit", req.video_id)
    bg.add_task(_run_video_edit, job_id, req.video_id, req.dub_audio_url, req.language)
    return {"job_id": job_id, "status": "pending"}


async def _run_video_edit(job_id: str, video_id: str, dub_audio_url: str, language: str):
    await update_job(job_id, "running")
    try:
        import httpx
        supabase_url = os.environ["SUPABASE_URL"]
        anon_key = os.environ["SUPABASE_ANON_KEY"]
        async with httpx.AsyncClient() as client:
            resp = await client.get(
                f"{supabase_url}/rest/v1/videos?id=eq.{video_id}&select=url&limit=1",
                headers={"apikey": anon_key, "Authorization": f"Bearer {anon_key}"},
            )
            video_url = resp.json()[0]["url"]

        output_url = await edit_video_with_dub(video_url, dub_audio_url, language)
        await update_job(job_id, "completed", result=output_url)
    except Exception as e:
        await update_job(job_id, "failed", error=str(e))


class MusicRequest(BaseModel):
    video_id: str
    genre: str = "electronic"
    mood: str = "energetic"
    skill: str = "ace-music"


@router.post("/music")
async def openclaw_music(req: MusicRequest, bg: BackgroundTasks):
    job_id = await create_job("music", req.video_id)
    bg.add_task(_run_oc_music, job_id, req.video_id, req.genre, req.mood)
    return {"job_id": job_id, "status": "pending"}


async def _run_oc_music(job_id: str, video_id: str, genre: str, mood: str):
    await update_job(job_id, "running")
    try:
        audio_url = await generate_music(genre, mood)
        await update_job(job_id, "completed", result=audio_url)
    except Exception as e:
        await update_job(job_id, "failed", error=str(e))
