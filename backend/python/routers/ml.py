"""
ML endpoints: clustering, classification, reasoning, similar-item search.

POST /ml/cluster              — run clustering on cargo or inventory items
GET  /ml/cluster/{runType}/latest  — get latest clustering run
POST /ml/classify             — classify one or more items
POST /ml/similar-items        — semantic similarity search
POST /ml/reason               — Claude reasoning with prompt caching
"""
from __future__ import annotations

from typing import Any

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from models.database import get_pool
from services.clustering import run_clustering, get_latest_clustering
from services.classification import classify_item, batch_classify
from services.vector_store import search_similar_cargo, search_similar_inventory
from services.reasoning_cache import (
    reason_about_defect,
    reason_about_shipment,
    reason_about_inventory,
    reason_about_classification,
)

router = APIRouter()


# ── Clustering ────────────────────────────────────────────────

class ClusterRequest(BaseModel):
    run_type: str            # 'cargo' | 'inventory'
    algorithm: str = "hdbscan"
    n_clusters: int | None = None
    min_cluster_size: int = 5


@router.post("/ml/cluster")
async def trigger_clustering(req: ClusterRequest):
    pool = await get_pool()
    result = await run_clustering(
        pool,
        run_type=req.run_type,
        algorithm=req.algorithm,
        n_clusters=req.n_clusters,
        min_cluster_size=req.min_cluster_size,
    )
    if "error" in result:
        raise HTTPException(400, result["error"])
    return result


@router.get("/ml/cluster/{run_type}/latest")
async def latest_clustering(run_type: str):
    pool = await get_pool()
    result = await get_latest_clustering(pool, run_type)
    if not result:
        raise HTTPException(404, f"no clustering run found for type: {run_type}")
    return result


# ── Classification ────────────────────────────────────────────

class ClassifyItemRequest(BaseModel):
    description: str
    sku: str | None = None
    hs_code: str | None = None
    use_reasoning: bool = False


class BatchClassifyRequest(BaseModel):
    items: list[dict[str, Any]]


@router.post("/ml/classify")
async def classify(req: ClassifyItemRequest):
    result = await classify_item(
        description=req.description,
        sku=req.sku,
        hs_code=req.hs_code,
        use_reasoning=req.use_reasoning,
    )
    return result


@router.post("/ml/classify/batch")
async def classify_batch(req: BatchClassifyRequest):
    if len(req.items) > 200:
        raise HTTPException(400, "maximum 200 items per batch request")
    results = await batch_classify(req.items)
    return {"results": results, "count": len(results)}


# ── Similarity search ─────────────────────────────────────────

class SimilarItemsRequest(BaseModel):
    query: str
    entity_type: str = "cargo_item"
    threshold: float = 0.6
    limit: int = 20


@router.post("/ml/similar-items")
async def similar_items(req: SimilarItemsRequest):
    pool = await get_pool()
    if req.entity_type == "cargo_item":
        results = await search_similar_cargo(pool, req.query, req.threshold, req.limit)
    elif req.entity_type == "inventory":
        results = await search_similar_inventory(pool, req.query, req.threshold, req.limit)
    else:
        raise HTTPException(400, f"unknown entity_type: {req.entity_type}")
    return {"results": results, "count": len(results)}


# ── Reasoning (Claude + prompt caching) ───────────────────────

class ReasonRequest(BaseModel):
    reason_type: str         # 'defect' | 'shipment' | 'inventory' | 'classification'
    data: dict[str, Any]
    budget_tokens: int = 6000


@router.post("/ml/reason")
async def reason(req: ReasonRequest):
    """
    Invoke Claude extended-thinking reasoning with prompt caching.
    The system prompt is cached for ~5 min — warm calls return instantly.
    """
    if req.reason_type == "defect":
        result = await reason_about_defect(req.data, req.budget_tokens)
    elif req.reason_type == "shipment":
        result = await reason_about_shipment(req.data, req.budget_tokens)
    elif req.reason_type == "inventory":
        result = await reason_about_inventory(req.data, req.budget_tokens)
    elif req.reason_type == "classification":
        items = req.data.get("items", [req.data])
        result = await reason_about_classification(items, req.budget_tokens)
    else:
        raise HTTPException(400, f"unknown reason_type: {req.reason_type}")

    return {
        "content": result.content,
        "thinking": result.thinking,
        "model": result.model,
        "cache_hit": result.cache_hit,
        "latency_ms": result.latency_ms,
        "tokens": {
            "input": result.input_tokens,
            "output": result.output_tokens,
            "cache_read": result.cache_read_tokens,
            "cache_write": result.cache_write_tokens,
        },
    }


# ── GraphQL passthrough ───────────────────────────────────────

@router.post("/graphql")
async def graphql_passthrough(body: dict[str, Any]):
    """
    Minimal GraphQL execution for ML-related fields proxied from Go.
    A full gqlgen/graphql-core implementation would go here.
    """
    query = body.get("query", "")
    return {
        "data": {"_note": "ML GraphQL fields — implement with strawberry-graphql"},
        "errors": None,
    }
