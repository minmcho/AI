"""Gemini Vision agent for video transcription."""

import os
import httpx
from typing import Optional

GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY", "")
GEMINI_MODEL = "gemini-2.0-flash-preview"
GEMINI_BASE = "https://generativelanguage.googleapis.com/v1beta"


async def transcribe_video(video_url: str, language_hint: str = "en") -> str:
    """
    Send a video URL to Gemini Vision and extract the spoken transcript.
    Uses the Files API for videos longer than 1 minute.
    """
    async with httpx.AsyncClient(timeout=120) as client:
        payload = {
            "contents": [
                {
                    "parts": [
                        {
                            "file_data": {
                                "mime_type": "video/mp4",
                                "file_uri": video_url,
                            }
                        },
                        {
                            "text": (
                                f"Transcribe all spoken words in this video verbatim. "
                                f"Return only the plain transcript text, no timestamps or labels. "
                                f"Primary language hint: {language_hint}."
                            )
                        },
                    ]
                }
            ],
            "generationConfig": {"temperature": 0.1, "maxOutputTokens": 4096},
        }

        resp = await client.post(
            f"{GEMINI_BASE}/models/{GEMINI_MODEL}:generateContent?key={GEMINI_API_KEY}",
            json=payload,
        )
        resp.raise_for_status()
        data = resp.json()
        return data["candidates"][0]["content"]["parts"][0]["text"].strip()


async def translate_text(text: str, target_language: str) -> str:
    """Translate text to the target language using Gemini."""
    async with httpx.AsyncClient(timeout=60) as client:
        payload = {
            "contents": [
                {
                    "parts": [
                        {
                            "text": (
                                f"Translate the following text to {target_language}. "
                                f"Return only the translated text, no explanations.\n\n{text}"
                            )
                        }
                    ]
                }
            ],
            "generationConfig": {"temperature": 0.2, "maxOutputTokens": 4096},
        }
        resp = await client.post(
            f"{GEMINI_BASE}/models/{GEMINI_MODEL}:generateContent?key={GEMINI_API_KEY}",
            json=payload,
        )
        resp.raise_for_status()
        data = resp.json()
        return data["candidates"][0]["content"]["parts"][0]["text"].strip()


async def embed_text(text: str) -> list[float]:
    """Generate text embedding for pgvector storage (semantic search)."""
    async with httpx.AsyncClient(timeout=30) as client:
        payload = {"model": f"models/text-embedding-004", "content": {"parts": [{"text": text}]}}
        resp = await client.post(
            f"{GEMINI_BASE}/models/text-embedding-004:embedContent?key={GEMINI_API_KEY}",
            json=payload,
        )
        resp.raise_for_status()
        return resp.json()["embedding"]["values"]
