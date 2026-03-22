import os
import asyncpg
from typing import Optional

_pool: Optional[asyncpg.Pool] = None


async def init_db():
    global _pool
    dsn = os.environ["DATABASE_URL"]  # postgresql://...?sslmode=require (Supabase)
    _pool = await asyncpg.create_pool(dsn, min_size=2, max_size=10)
    # Ensure pgvector extension is available
    async with _pool.acquire() as conn:
        await conn.execute("CREATE EXTENSION IF NOT EXISTS vector;")


async def get_pool() -> asyncpg.Pool:
    assert _pool is not None, "DB not initialized"
    return _pool


async def create_job(job_type: str, video_id: str) -> str:
    pool = await get_pool()
    row = await pool.fetchrow(
        """
        INSERT INTO agent_jobs (job_type, video_id, status)
        VALUES ($1, $2, 'pending')
        RETURNING id
        """,
        job_type,
        video_id,
    )
    return str(row["id"])


async def update_job(job_id: str, status: str, result: str = None, error: str = None):
    pool = await get_pool()
    await pool.execute(
        """
        UPDATE agent_jobs
        SET status = $2, result = $3, error = $4, updated_at = NOW()
        WHERE id = $1
        """,
        job_id,
        status,
        result,
        error,
    )


async def get_job(job_id: str) -> dict:
    pool = await get_pool()
    row = await pool.fetchrow(
        "SELECT id, job_type, video_id, status, result, error, created_at FROM agent_jobs WHERE id = $1",
        job_id,
    )
    if not row:
        return None
    return dict(row)


async def store_embedding(video_id: str, embedding: list[float]):
    """Store pgvector embedding for semantic video search."""
    pool = await get_pool()
    await pool.execute(
        "UPDATE videos SET embedding = $2 WHERE id = $1",
        video_id,
        embedding,
    )


async def similar_videos(embedding: list[float], limit: int = 10) -> list[dict]:
    """Find videos by cosine similarity using pgvector <=> operator."""
    pool = await get_pool()
    rows = await pool.fetch(
        """
        SELECT id, caption, 1 - (embedding <=> $1::vector) AS similarity
        FROM videos
        WHERE embedding IS NOT NULL
        ORDER BY embedding <=> $1::vector
        LIMIT $2
        """,
        embedding,
        limit,
    )
    return [dict(r) for r in rows]
