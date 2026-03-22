"""
OpenClaw agent orchestrator.

Communicates with a locally running OpenClaw instance (or OpenClaw Cloud API)
to invoke skills:
  - ace-music   : AI music generation via ACE-Step 1.5
  - eachlabs-video-edit : lip-sync, translation overlay, subtitles
  - kokoro-tts  : high-quality open-source TTS for voice dubbing
"""

import os
import asyncio
import httpx
from typing import Optional

OPENCLAW_API = os.environ.get("OPENCLAW_API_URL", "http://localhost:3000")
OPENCLAW_TOKEN = os.environ.get("OPENCLAW_TOKEN", "")


async def run_skill(skill: str, prompt: str, context: dict = None) -> dict:
    """
    Dispatch a skill to the OpenClaw agent and return the result dict.
    OpenClaw processes the skill asynchronously; we poll until done.
    """
    headers = {}
    if OPENCLAW_TOKEN:
        headers["Authorization"] = f"Bearer {OPENCLAW_TOKEN}"

    payload = {
        "skill": skill,
        "prompt": prompt,
        "context": context or {},
    }

    async with httpx.AsyncClient(timeout=300) as client:
        # Submit job
        resp = await client.post(f"{OPENCLAW_API}/api/run", json=payload, headers=headers)
        resp.raise_for_status()
        job = resp.json()
        job_id = job["job_id"]

        # Poll for completion
        for _ in range(150):  # max 5 min (150 × 2s)
            await asyncio.sleep(2)
            status_resp = await client.get(f"{OPENCLAW_API}/api/jobs/{job_id}", headers=headers)
            status_resp.raise_for_status()
            status = status_resp.json()
            if status["status"] in ("completed", "failed"):
                return status
        raise TimeoutError(f"OpenClaw job {job_id} timed out")


async def generate_tts(text: str, persona: str, language: str) -> str:
    """
    Generate TTS audio using OpenClaw's kokoro-tts skill.
    Returns a URL to the generated audio file.
    """
    persona_map = {
        "energetic": "af_heart",   # Kokoro voice IDs
        "calm": "af_sky",
        "deep_bass": "am_adam",
        "high_pitch": "af_nova",
        "synthesizer": "af_aoede",
        "cloned": "af_heart",      # Fallback; real clone requires voice upload
    }
    voice_id = persona_map.get(persona, "af_heart")

    result = await run_skill(
        skill="kokoro-tts",
        prompt=text,
        context={"voice": voice_id, "language": language, "speed": 1.0},
    )
    if result["status"] == "failed":
        raise RuntimeError(result.get("error", "TTS generation failed"))
    return result["output"]["audio_url"]


async def generate_music(genre: str, mood: str, duration: int = 30) -> str:
    """
    Generate a background mix track via OpenClaw's ace-music skill.
    Returns a URL to the generated audio file.
    """
    prompt = f"Create a {duration}-second {genre} music track with a {mood} mood, suitable as a video background mix."
    result = await run_skill(
        skill="ace-music",
        prompt=prompt,
        context={"genre": genre, "mood": mood, "duration": duration},
    )
    if result["status"] == "failed":
        raise RuntimeError(result.get("error", "Music generation failed"))
    return result["output"]["audio_url"]


async def edit_video_with_dub(video_url: str, dub_audio_url: str, language: str) -> str:
    """
    Apply dubbed audio + subtitles to a video using OpenClaw's eachlabs-video-edit skill.
    Returns a URL to the processed video.
    """
    result = await run_skill(
        skill="eachlabs-video-edit",
        prompt=f"Replace the original audio with the dubbed audio track and add {language} subtitles.",
        context={
            "video_url": video_url,
            "audio_url": dub_audio_url,
            "subtitle_language": language,
            "lip_sync": True,
        },
    )
    if result["status"] == "failed":
        raise RuntimeError(result.get("error", "Video edit failed"))
    return result["output"]["video_url"]
