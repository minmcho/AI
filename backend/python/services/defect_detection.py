"""
Defect detection service.

Supports two modes:
1. Image-based — sends image URL to Claude Vision for multimodal defect analysis
2. Sensor-based — analyses numeric/text sensor readings for anomalies

Results include:
- defect_type: damage | contamination | mislabel | missing | other
- severity:    low | medium | high | critical
- confidence:  0.0–1.0
- bounding_boxes: [{x, y, w, h, label, score}]
- reasoning:   Claude's extended-thinking analysis
"""
from __future__ import annotations

import base64
import os
from typing import Any

import anthropic
import httpx

from .reasoning_cache import ReasoningResult, _call_claude, CARGO_SYSTEM_PROMPT

_client = anthropic.AsyncAnthropic(api_key=os.environ.get("ANTHROPIC_API_KEY", ""))

MODEL = "claude-opus-4-6"


async def detect_defects_from_image(
    image_url: str,
    context: dict[str, Any] | None = None,
    budget_tokens: int = 6000,
) -> dict[str, Any]:
    """
    Send an image to Claude Vision and return a structured defect report.

    Args:
        image_url:    Publicly accessible image URL.
        context:      Optional dict with item description, SKU, location, etc.
        budget_tokens: Extended thinking depth.

    Returns:
        Dict with keys: defect_type, severity, confidence, bounding_boxes,
        reasoning, raw_output, model_version.
    """
    api_key = os.environ.get("ANTHROPIC_API_KEY", "")
    if not api_key:
        return _demo_defect_result(image_url)

    # Fetch image bytes so we can pass as base64 (avoids URL auth issues)
    image_bytes: bytes | None = None
    media_type = "image/jpeg"
    try:
        async with httpx.AsyncClient(timeout=15) as client:
            resp = await client.get(image_url)
            if resp.status_code == 200:
                image_bytes = resp.content
                ct = resp.headers.get("content-type", "image/jpeg")
                media_type = ct.split(";")[0].strip()
    except Exception:
        pass  # fall through to URL-based reference

    ctx_text = ""
    if context:
        import json
        ctx_text = f"\n\nItem context:\n{json.dumps(context, indent=2)}"

    system_blocks = [
        {
            "type": "text",
            "text": CARGO_SYSTEM_PROMPT,
            "cache_control": {"type": "ephemeral"},
        }
    ]

    user_content: list[dict[str, Any]] = []

    if image_bytes:
        user_content.append({
            "type": "image",
            "source": {
                "type": "base64",
                "media_type": media_type,
                "data": base64.b64encode(image_bytes).decode(),
            },
        })
    else:
        user_content.append({
            "type": "image",
            "source": {"type": "url", "url": image_url},
        })

    user_content.append({
        "type": "text",
        "text": (
            "Analyse this cargo/inventory image for defects.\n"
            "Return a JSON object with keys:\n"
            "  defect_found (bool),\n"
            "  defect_type (damage|contamination|mislabel|missing|other|none),\n"
            "  severity (low|medium|high|critical|none),\n"
            "  confidence (0.0-1.0),\n"
            "  bounding_boxes ([{x,y,w,h,label,score}] normalised 0-1),\n"
            "  description (string),\n"
            "  recommended_action (string)\n"
            + ctx_text
        ),
    })

    import json
    import time

    t0 = time.monotonic()
    response = await _client.messages.create(
        model=MODEL,
        max_tokens=budget_tokens + 2048,
        thinking={"type": "enabled", "budget_tokens": budget_tokens},
        system=system_blocks,
        messages=[{"role": "user", "content": user_content}],
    )
    latency_ms = int((time.monotonic() - t0) * 1000)

    thinking_text = None
    answer_text = ""
    for block in response.content:
        if block.type == "thinking":
            thinking_text = block.thinking
        elif block.type == "text":
            answer_text += block.text

    # Parse JSON from answer
    parsed: dict[str, Any] = {}
    try:
        # Strip markdown code fences if present
        clean = answer_text.strip()
        if clean.startswith("```"):
            clean = clean.split("\n", 1)[1].rsplit("```", 1)[0]
        parsed = json.loads(clean)
    except Exception:
        parsed = {
            "defect_found": True,
            "defect_type": "other",
            "severity": "low",
            "confidence": 0.5,
            "bounding_boxes": [],
            "description": answer_text[:500],
            "recommended_action": "Manual inspection required",
        }

    usage = response.usage
    return {
        "defect_found": parsed.get("defect_found", False),
        "defect_type": parsed.get("defect_type", "none"),
        "severity": parsed.get("severity", "none"),
        "confidence": parsed.get("confidence", 0.0),
        "bounding_boxes": parsed.get("bounding_boxes", []),
        "description": parsed.get("description", ""),
        "recommended_action": parsed.get("recommended_action", ""),
        "reasoning": thinking_text,
        "raw_output": answer_text,
        "model_version": response.model,
        "latency_ms": latency_ms,
        "cache_read_tokens": getattr(usage, "cache_read_input_tokens", 0) or 0,
        "cache_write_tokens": getattr(usage, "cache_creation_input_tokens", 0) or 0,
    }


async def detect_defects_from_sensors(
    readings: dict[str, Any],
    item_spec: dict[str, Any] | None = None,
    budget_tokens: int = 4000,
) -> dict[str, Any]:
    """
    Detect anomalies from sensor readings (temperature, humidity, shock, etc.).
    Uses Claude reasoning without vision.
    """
    import json

    user_message = json.dumps({
        "task": "sensor_anomaly_detection",
        "sensor_readings": readings,
        "item_specification": item_spec or {},
    }, indent=2)

    result: ReasoningResult = await _call_claude(
        system_prompt=CARGO_SYSTEM_PROMPT,
        user_message=user_message,
        budget_tokens=budget_tokens,
        query_type="sensor_defect",
    )

    # Parse structured response
    parsed: dict[str, Any] = {}
    try:
        clean = result.content.strip()
        if clean.startswith("```"):
            clean = clean.split("\n", 1)[1].rsplit("```", 1)[0]
        parsed = json.loads(clean)
    except Exception:
        parsed = {
            "defect_found": False,
            "defect_type": "none",
            "severity": "none",
            "confidence": 0.0,
            "description": result.content[:500],
        }

    return {
        **parsed,
        "reasoning": result.thinking,
        "model_version": result.model,
        "latency_ms": result.latency_ms,
        "cache_hit": result.cache_hit,
    }


def _demo_defect_result(image_url: str) -> dict[str, Any]:
    """Return synthetic result when no API key is configured."""
    return {
        "defect_found": False,
        "defect_type": "none",
        "severity": "none",
        "confidence": 0.0,
        "bounding_boxes": [],
        "description": "Demo mode — no ANTHROPIC_API_KEY set",
        "recommended_action": "Set ANTHROPIC_API_KEY to enable real detection",
        "reasoning": None,
        "raw_output": "",
        "model_version": "demo",
        "latency_ms": 0,
        "cache_read_tokens": 0,
        "cache_write_tokens": 0,
    }
