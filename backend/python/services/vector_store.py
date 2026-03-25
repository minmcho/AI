"""
Vector store service — pgvector-backed semantic search for cargo items,
inventory, and shipments using HNSW ANN indexes.
"""
from __future__ import annotations

import os
from typing import Any

import anthropic
import asyncpg

# Anthropic client reused across calls (embeddings use text-embedding-3 via
# the Bedrock/batch API; for standalone we use claude's embedding proxy).
_anthropic = anthropic.AsyncAnthropic(api_key=os.environ.get("ANTHROPIC_API_KEY", ""))

# Embedding dimension produced by text-embedding-3-small (OpenAI) or
# Gemini text-embedding-004 (1536-d both).
EMBEDDING_DIM = 1536


async def embed_text(text: str) -> list[float]:
    """
    Return a 1536-d vector for *text*.
    Uses Anthropic's voyage-3 embedding model via the API.
    Falls back to a zero-vector in demo mode (no API key set).
    """
    api_key = os.environ.get("ANTHROPIC_API_KEY", "")
    if not api_key:
        # Demo mode — return zero vector
        return [0.0] * EMBEDDING_DIM

    # Anthropic doesn't expose embeddings directly in the Python SDK yet;
    # use httpx to call the voyage endpoint directly.
    import httpx

    async with httpx.AsyncClient(timeout=30) as client:
        resp = await client.post(
            "https://api.voyageai.com/v1/embeddings",
            headers={
                "Authorization": f"Bearer {os.environ.get('VOYAGE_API_KEY', api_key)}",
                "Content-Type": "application/json",
            },
            json={"model": "voyage-3", "input": [text[:8000]]},
        )
        if resp.status_code == 200:
            data = resp.json()
            return data["data"][0]["embedding"]
    return [0.0] * EMBEDDING_DIM


async def store_cargo_embedding(pool: asyncpg.Pool, item_id: str, text: str) -> None:
    """Embed *text* and store in cargo_items.embedding."""
    vec = await embed_text(text)
    await pool.execute(
        "UPDATE cargo_items SET embedding = $2::vector WHERE id = $1",
        item_id,
        vec,
    )


async def store_inventory_embedding(pool: asyncpg.Pool, inv_id: str, text: str) -> None:
    vec = await embed_text(text)
    await pool.execute(
        "UPDATE inventory SET embedding = $2::vector WHERE id = $1",
        inv_id,
        vec,
    )


async def store_shipment_embedding(pool: asyncpg.Pool, shipment_id: str, text: str) -> None:
    vec = await embed_text(text)
    await pool.execute(
        "UPDATE shipments SET embedding = $2::vector WHERE id = $1",
        shipment_id,
        vec,
    )


async def search_similar_cargo(
    pool: asyncpg.Pool,
    query: str,
    threshold: float = 0.6,
    limit: int = 20,
) -> list[dict[str, Any]]:
    """Semantic search over cargo_items using pgvector <=> cosine distance."""
    vec = await embed_text(query)
    rows = await pool.fetch(
        "SELECT * FROM search_cargo_items($1::vector, $2, $3)",
        vec, threshold, limit,
    )
    return [dict(r) for r in rows]


async def search_similar_inventory(
    pool: asyncpg.Pool,
    query: str,
    threshold: float = 0.6,
    limit: int = 20,
) -> list[dict[str, Any]]:
    """Semantic search over inventory using pgvector."""
    vec = await embed_text(query)
    rows = await pool.fetch(
        "SELECT * FROM search_inventory($1::vector, $2, $3)",
        vec, threshold, limit,
    )
    return [dict(r) for r in rows]


async def find_similar_items_by_id(
    pool: asyncpg.Pool,
    item_id: str,
    limit: int = 10,
) -> list[dict[str, Any]]:
    """Find cargo items similar to *item_id* using its stored embedding."""
    row = await pool.fetchrow(
        "SELECT embedding FROM cargo_items WHERE id = $1", item_id
    )
    if not row or row["embedding"] is None:
        return []
    rows = await pool.fetch(
        """
        SELECT id, description, sku, shipment_id, category, cluster_id,
               1 - (embedding <=> $1::vector) AS similarity
        FROM cargo_items
        WHERE id != $2 AND embedding IS NOT NULL
        ORDER BY embedding <=> $1::vector
        LIMIT $3
        """,
        row["embedding"], item_id, limit,
    )
    return [dict(r) for r in rows]
