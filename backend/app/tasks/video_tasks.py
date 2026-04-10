"""
Celery tasks for video analysis pipeline.

Flow:
  1. Receive video URL (already in Supabase Storage)
  2. Extract key frames (FFmpeg via subprocess)
  3. Upload frames to temp storage / pass as data URIs
  4. Call Qwen 3.5 VL via AIOrchestrator
  5. Run safety post-check
  6. Persist result to WellnessSession
"""
from __future__ import annotations

import asyncio
import base64
import logging
import os
import subprocess
import tempfile
import uuid
from typing import Any

import httpx
from celery import shared_task

from app.config import get_settings
from app.tasks.celery_app import celery_app

logger = logging.getLogger(__name__)
settings = get_settings()


# ── Frame extraction ─────────────────────────────────────────

def extract_frames(video_path: str, n_frames: int = 6) -> list[str]:
    """
    Extract n_frames evenly-spaced frames from video using FFmpeg.
    Returns list of base64-encoded JPEG strings.
    """
    with tempfile.TemporaryDirectory() as tmpdir:
        pattern = os.path.join(tmpdir, "frame_%03d.jpg")
        cmd = [
            "ffmpeg", "-i", video_path,
            "-vf", f"select=not(mod(n\\,{max(1, 30 // n_frames)}))",
            "-vsync", "vfr",
            "-frames:v", str(n_frames),
            "-q:v", "5",
            pattern,
            "-y", "-loglevel", "error",
        ]
        subprocess.run(cmd, check=True, capture_output=True, timeout=60)

        frames: list[str] = []
        for i in range(1, n_frames + 1):
            frame_path = os.path.join(tmpdir, f"frame_{i:03d}.jpg")
            if os.path.exists(frame_path):
                with open(frame_path, "rb") as f:
                    b64 = base64.b64encode(f.read()).decode("utf-8")
                    frames.append(f"data:image/jpeg;base64,{b64}")
        return frames


async def download_video(video_url: str, dest_path: str) -> None:
    """Stream video from Supabase Storage to local temp file."""
    async with httpx.AsyncClient(timeout=120.0) as client:
        async with client.stream("GET", video_url) as resp:
            resp.raise_for_status()
            with open(dest_path, "wb") as f:
                async for chunk in resp.aiter_bytes(chunk_size=65536):
                    f.write(chunk)


# ── Main analysis task ───────────────────────────────────────

@celery_app.task(
    bind=True,
    name="app.tasks.video_tasks.analyze_video_task",
    max_retries=3,
    default_retry_delay=15,
    soft_time_limit=300,    # 5 min soft limit
    time_limit=360,         # 6 min hard limit
)
def analyze_video_task(
    self,
    session_id: str,
    user_id: str,
    video_url: str,
    analysis_type: str = "meal",
) -> dict[str, Any]:
    """
    Main Celery task: download → extract frames → analyze → persist.
    """
    self.update_state(state="STARTED", meta={"progress": 0, "status": "Downloading video"})
    logger.info("analyze_video_task started: session=%s type=%s", session_id, analysis_type)

    try:
        result = asyncio.get_event_loop().run_until_complete(
            _run_analysis(self, session_id, user_id, video_url, analysis_type)
        )
        return result
    except Exception as exc:
        logger.error("analyze_video_task failed: %s", exc, exc_info=True)
        raise self.retry(exc=exc)


async def _run_analysis(
    task,
    session_id: str,
    user_id: str,
    video_url: str,
    analysis_type: str,
) -> dict[str, Any]:
    from app.services.ai_orchestrator import get_orchestrator
    from app.models.database import get_session, WellnessSession

    orchestrator = get_orchestrator()

    with tempfile.NamedTemporaryFile(suffix=".mp4", delete=False) as tmp:
        tmp_path = tmp.name

    try:
        # Step 1: Download
        task.update_state(state="PROGRESS", meta={"progress": 10, "status": "Downloading video"})
        await download_video(video_url, tmp_path)

        # Step 2: Extract frames
        task.update_state(state="PROGRESS", meta={"progress": 35, "status": "Extracting frames"})
        frames = extract_frames(tmp_path, n_frames=6)

        if not frames:
            raise ValueError("No frames extracted from video")

        # Step 3: AI analysis
        task.update_state(state="PROGRESS", meta={"progress": 55, "status": "Analyzing with Qwen 3.5 VL"})
        analysis = await orchestrator.analyze_video_frames(frames, analysis_type=analysis_type)

        # Step 4: Persist result
        task.update_state(state="PROGRESS", meta={"progress": 85, "status": "Saving results"})
        async for db in get_session():
            import uuid as _uuid
            session = await db.get(WellnessSession, _uuid.UUID(session_id))
            if session:
                session.video_analysis_result = analysis
                session.completed_at = __import__("datetime").datetime.utcnow()
                await db.commit()

        task.update_state(state="PROGRESS", meta={"progress": 100, "status": "Complete"})
        logger.info("analyze_video_task completed: session=%s", session_id)
        return analysis

    finally:
        if os.path.exists(tmp_path):
            os.unlink(tmp_path)
