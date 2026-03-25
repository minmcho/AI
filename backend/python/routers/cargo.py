"""
Cargo & organisational-structure endpoints served by FastAPI.

GET /cargo/departments   — list departments
GET /cargo/regions       — list regions
GET /cargo/locations     — list locations (optional ?region_id=)
GET /cargo/units         — list unit types
POST /cargo/embed        — generate and store embedding for a shipment/item
POST /cargo/similar      — semantic similarity search
"""
from __future__ import annotations

from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel

from models.database import get_pool
from services.vector_store import (
    search_similar_cargo,
    search_similar_inventory,
    find_similar_items_by_id,
    store_cargo_embedding,
    store_shipment_embedding,
)

router = APIRouter()


# ── Org structure ─────────────────────────────────────────────

@router.get("/cargo/departments")
async def list_departments():
    pool = await get_pool()
    rows = await pool.fetch(
        "SELECT id, name, code, parent_id, created_at FROM departments ORDER BY name"
    )
    return {"departments": [dict(r) for r in rows]}


@router.get("/cargo/regions")
async def list_regions():
    pool = await get_pool()
    rows = await pool.fetch(
        "SELECT id, name, code, country, timezone FROM regions ORDER BY name"
    )
    return {"regions": [dict(r) for r in rows]}


@router.get("/cargo/locations")
async def list_locations(region_id: str | None = Query(None)):
    pool = await get_pool()
    if region_id:
        rows = await pool.fetch(
            "SELECT id, name, code, region_id, department_id, address, "
            "latitude, longitude, location_type FROM locations WHERE region_id = $1 ORDER BY name",
            region_id,
        )
    else:
        rows = await pool.fetch(
            "SELECT id, name, code, region_id, department_id, address, "
            "latitude, longitude, location_type FROM locations ORDER BY name"
        )
    return {"locations": [dict(r) for r in rows]}


@router.get("/cargo/units")
async def list_units():
    pool = await get_pool()
    rows = await pool.fetch(
        "SELECT id, name, code, unit_type, tare_kg, max_load_kg, volume_m3 FROM units ORDER BY name"
    )
    return {"units": [dict(r) for r in rows]}


# ── Embedding ─────────────────────────────────────────────────

class EmbedRequest(BaseModel):
    entity_type: str      # 'cargo_item' | 'shipment' | 'inventory'
    entity_id: str
    text: str             # text to embed (description + metadata)


@router.post("/cargo/embed")
async def store_embedding(req: EmbedRequest):
    pool = await get_pool()
    if req.entity_type == "cargo_item":
        await store_cargo_embedding(pool, req.entity_id, req.text)
    elif req.entity_type == "shipment":
        await store_shipment_embedding(pool, req.entity_id, req.text)
    else:
        raise HTTPException(400, f"unsupported entity_type: {req.entity_type}")
    return {"status": "embedded", "entity_id": req.entity_id}


# ── Similarity search ─────────────────────────────────────────

class SimilarRequest(BaseModel):
    query: str
    entity_type: str = "cargo_item"  # 'cargo_item' | 'inventory'
    threshold: float = 0.6
    limit: int = 20


@router.post("/cargo/similar")
async def similar_items(req: SimilarRequest):
    pool = await get_pool()
    if req.entity_type == "cargo_item":
        results = await search_similar_cargo(pool, req.query, req.threshold, req.limit)
    elif req.entity_type == "inventory":
        results = await search_similar_inventory(pool, req.query, req.threshold, req.limit)
    else:
        raise HTTPException(400, f"unsupported entity_type: {req.entity_type}")
    return {"results": results, "count": len(results)}


@router.get("/cargo/similar/{item_id}")
async def similar_by_id(item_id: str, limit: int = Query(10)):
    pool = await get_pool()
    results = await find_similar_items_by_id(pool, item_id, limit)
    return {"results": results}
