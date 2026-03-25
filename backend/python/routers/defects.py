"""
Defect detection endpoints.

POST /ml/defect-detect         — detect defects from image URL or sensor data
GET  /ml/defects               — list recent defect detections
GET  /ml/defects/{id}          — get single defect
POST /ml/defects/{id}/resolve  — mark resolved + action taken
"""
from __future__ import annotations

import uuid
from typing import Any

from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel

from models.database import get_pool
from services.defect_detection import detect_defects_from_image, detect_defects_from_sensors
from services.reasoning_cache import reason_about_defect

router = APIRouter()


class DefectDetectRequest(BaseModel):
    # Image-based detection
    image_url: str | None = None
    # Sensor-based detection
    sensor_readings: dict[str, Any] | None = None
    # Context
    cargo_item_id: str | None = None
    inventory_id: str | None = None
    location_id: str | None = None
    item_context: dict[str, Any] | None = None
    # Options
    budget_tokens: int = 6000
    persist: bool = True          # save result to DB


class ResolveRequest(BaseModel):
    action_taken: str


@router.post("/ml/defect-detect")
async def detect_defect(req: DefectDetectRequest):
    """
    Detect defects in cargo or inventory items.

    Supports:
    - Image analysis (image_url) — Claude Vision + extended thinking
    - Sensor anomaly (sensor_readings) — Claude text reasoning
    - Post-detection re-analysis via reason endpoint
    """
    if req.image_url:
        result = await detect_defects_from_image(
            image_url=req.image_url,
            context=req.item_context,
            budget_tokens=req.budget_tokens,
        )
    elif req.sensor_readings:
        result = await detect_defects_from_sensors(
            readings=req.sensor_readings,
            item_spec=req.item_context,
            budget_tokens=req.budget_tokens,
        )
    else:
        raise HTTPException(400, "provide either image_url or sensor_readings")

    # Persist to DB if requested and item references provided
    if req.persist and (req.cargo_item_id or req.inventory_id):
        pool = await get_pool()
        defect_id = str(uuid.uuid4())
        import json
        await pool.execute(
            """
            INSERT INTO defect_detections
              (id, cargo_item_id, inventory_id, location_id, image_url,
               defect_type, severity, confidence, bounding_boxes,
               model_version, reasoning, raw_output)
            VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12)
            """,
            defect_id,
            req.cargo_item_id,
            req.inventory_id,
            req.location_id,
            req.image_url,
            result.get("defect_type"),
            result.get("severity"),
            result.get("confidence"),
            json.dumps(result.get("bounding_boxes", [])),
            result.get("model_version"),
            result.get("reasoning"),
            result.get("raw_output", ""),
        )
        # Update defect_score on cargo item
        if req.cargo_item_id and result.get("confidence") is not None:
            await pool.execute(
                "UPDATE cargo_items SET defect_score = $2 WHERE id = $1",
                req.cargo_item_id, result["confidence"],
            )
        result["defect_id"] = defect_id

    return result


@router.get("/ml/defects")
async def list_defects(
    location_id: str | None = Query(None),
    severity: str | None = Query(None),
    unresolved_only: bool = Query(False),
    limit: int = Query(50),
):
    pool = await get_pool()
    rows = await pool.fetch(
        """
        SELECT id, cargo_item_id, inventory_id, location_id, image_url,
               defect_type, severity, confidence, model_version,
               reasoning, action_taken, resolved_at, created_at
        FROM defect_detections
        WHERE ($1::text IS NULL OR location_id::text = $1)
          AND ($2::text IS NULL OR severity = $2)
          AND (NOT $3 OR resolved_at IS NULL)
        ORDER BY created_at DESC
        LIMIT $4
        """,
        location_id, severity, unresolved_only, limit,
    )
    return {"defects": [dict(r) for r in rows], "count": len(rows)}


@router.get("/ml/defects/{defect_id}")
async def get_defect(defect_id: str):
    pool = await get_pool()
    row = await pool.fetchrow(
        "SELECT * FROM defect_detections WHERE id = $1", defect_id
    )
    if not row:
        raise HTTPException(404, "defect not found")
    return dict(row)


@router.post("/ml/defects/{defect_id}/resolve")
async def resolve_defect(defect_id: str, req: ResolveRequest):
    pool = await get_pool()
    await pool.execute(
        """
        UPDATE defect_detections
        SET action_taken = $2, resolved_at = NOW()
        WHERE id = $1
        """,
        defect_id, req.action_taken,
    )
    return {"status": "resolved", "defect_id": defect_id}


@router.post("/ml/defects/{defect_id}/reason")
async def reason_defect(defect_id: str):
    """
    Run Claude extended-thinking analysis on a stored defect detection.
    Uses prompt caching so repeat calls are fast.
    """
    pool = await get_pool()
    row = await pool.fetchrow(
        "SELECT * FROM defect_detections WHERE id = $1", defect_id
    )
    if not row:
        raise HTTPException(404, "defect not found")

    result = await reason_about_defect(dict(row))

    # Persist reasoning back
    await pool.execute(
        "UPDATE defect_detections SET reasoning = $2 WHERE id = $1",
        defect_id, result.content,
    )

    return {
        "defect_id": defect_id,
        "reasoning": result.content,
        "thinking": result.thinking,
        "cache_hit": result.cache_hit,
        "latency_ms": result.latency_ms,
        "tokens": {
            "input": result.input_tokens,
            "output": result.output_tokens,
            "cache_read": result.cache_read_tokens,
            "cache_write": result.cache_write_tokens,
        },
    }
