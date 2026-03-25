"""
Item clustering service.

Runs HDBSCAN (preferred) or K-Means on item embeddings stored in pgvector,
then persists cluster assignments back to the DB and records a clustering_runs
snapshot.

Supported run_types: 'cargo', 'inventory', 'defect'
"""
from __future__ import annotations

import json
import os
import uuid
from typing import Any

import asyncpg
import numpy as np


async def run_clustering(
    pool: asyncpg.Pool,
    run_type: str,
    algorithm: str = "hdbscan",
    n_clusters: int | None = None,
    min_cluster_size: int = 5,
) -> dict[str, Any]:
    """
    Fetch item embeddings from the DB, cluster them, persist results.

    Args:
        run_type:         'cargo' | 'inventory' | 'defect'
        algorithm:        'hdbscan' | 'kmeans' | 'dbscan'
        n_clusters:       required for kmeans; ignored for density-based methods
        min_cluster_size: HDBSCAN parameter

    Returns:
        Summary dict with run_id, num_clusters, silhouette_score, clusters list.
    """
    # ── Fetch embeddings ──────────────────────────────────────
    if run_type == "cargo":
        rows = await pool.fetch(
            "SELECT id, embedding FROM cargo_items WHERE embedding IS NOT NULL"
        )
        table = "cargo_items"
    elif run_type == "inventory":
        rows = await pool.fetch(
            "SELECT id, embedding FROM inventory WHERE embedding IS NOT NULL"
        )
        table = "inventory"
    else:
        return {"error": f"unknown run_type: {run_type}"}

    if len(rows) < 2:
        return {"error": "not enough embedded items to cluster (need ≥ 2)"}

    ids = [str(r["id"]) for r in rows]
    # pgvector returns embeddings as string '[0.1,0.2,...]' or list
    vectors = []
    for r in rows:
        emb = r["embedding"]
        if isinstance(emb, str):
            emb = json.loads(emb)
        vectors.append(emb)

    X = np.array(vectors, dtype=np.float32)

    # ── Cluster ───────────────────────────────────────────────
    labels, score, params = _cluster(X, algorithm, n_clusters, min_cluster_size)

    # ── Persist cluster labels ────────────────────────────────
    async with pool.acquire() as conn:
        async with conn.transaction():
            for item_id, label in zip(ids, labels):
                await conn.execute(
                    f"UPDATE {table} SET cluster_id = $2 WHERE id = $1",
                    item_id, int(label),
                )

    # ── Build cluster summary ─────────────────────────────────
    unique_labels = sorted(set(int(l) for l in labels if l >= 0))
    cluster_labels = []
    for cid in unique_labels:
        size = int(np.sum(labels == cid))
        cluster_labels.append({"cluster_id": cid, "name": f"Cluster {cid}", "size": size})

    num_clusters = len(unique_labels)

    # ── Persist run record ────────────────────────────────────
    run_id = str(uuid.uuid4())
    await pool.execute(
        """
        INSERT INTO clustering_runs
          (id, run_type, algorithm, num_clusters, parameters,
           cluster_labels, silhouette_score)
        VALUES ($1, $2, $3, $4, $5, $6, $7)
        """,
        run_id, run_type, algorithm, num_clusters,
        json.dumps(params),
        json.dumps(cluster_labels),
        float(score) if score is not None else None,
    )

    return {
        "run_id": run_id,
        "run_type": run_type,
        "algorithm": algorithm,
        "num_clusters": num_clusters,
        "num_items": len(ids),
        "silhouette_score": score,
        "clusters": cluster_labels,
        "parameters": params,
    }


async def get_latest_clustering(
    pool: asyncpg.Pool,
    run_type: str,
) -> dict[str, Any] | None:
    row = await pool.fetchrow(
        """
        SELECT id, run_type, algorithm, num_clusters,
               parameters, cluster_labels, silhouette_score, created_at
        FROM clustering_runs
        WHERE run_type = $1
        ORDER BY created_at DESC
        LIMIT 1
        """,
        run_type,
    )
    if not row:
        return None
    return {
        "run_id": str(row["id"]),
        "run_type": row["run_type"],
        "algorithm": row["algorithm"],
        "num_clusters": row["num_clusters"],
        "parameters": json.loads(row["parameters"]) if row["parameters"] else {},
        "clusters": json.loads(row["cluster_labels"]) if row["cluster_labels"] else [],
        "silhouette_score": row["silhouette_score"],
        "created_at": row["created_at"].isoformat() if row["created_at"] else None,
    }


# ── Clustering implementations ───────────────────────────────

def _cluster(
    X: np.ndarray,
    algorithm: str,
    n_clusters: int | None,
    min_cluster_size: int,
) -> tuple[np.ndarray, float | None, dict]:
    """Return (labels, silhouette_score, params)."""

    if algorithm == "hdbscan":
        return _hdbscan(X, min_cluster_size)
    elif algorithm == "kmeans":
        k = n_clusters or max(2, int(np.sqrt(len(X) / 2)))
        return _kmeans(X, k)
    elif algorithm == "dbscan":
        return _dbscan(X)
    else:
        return _hdbscan(X, min_cluster_size)


def _hdbscan(X: np.ndarray, min_cluster_size: int) -> tuple[np.ndarray, float | None, dict]:
    try:
        import hdbscan as hdbscan_lib
        clusterer = hdbscan_lib.HDBSCAN(
            min_cluster_size=min_cluster_size,
            metric="euclidean",
            core_dist_n_jobs=-1,
        )
        labels = clusterer.fit_predict(X)
    except ImportError:
        # Fall back to sklearn AgglomerativeClustering
        from sklearn.cluster import AgglomerativeClustering
        k = max(2, int(np.sqrt(len(X) / 2)))
        labels = AgglomerativeClustering(n_clusters=k).fit_predict(X)

    score = _silhouette(X, labels)
    return labels, score, {"min_cluster_size": min_cluster_size}


def _kmeans(X: np.ndarray, k: int) -> tuple[np.ndarray, float | None, dict]:
    from sklearn.cluster import KMeans
    km = KMeans(n_clusters=k, random_state=42, n_init="auto")
    labels = km.fit_predict(X)
    score = _silhouette(X, labels)
    return labels, score, {"n_clusters": k}


def _dbscan(X: np.ndarray) -> tuple[np.ndarray, float | None, dict]:
    from sklearn.cluster import DBSCAN
    db = DBSCAN(eps=0.5, min_samples=5, metric="euclidean", n_jobs=-1)
    labels = db.fit_predict(X)
    score = _silhouette(X, labels)
    return labels, score, {"eps": 0.5, "min_samples": 5}


def _silhouette(X: np.ndarray, labels: np.ndarray) -> float | None:
    unique = set(labels)
    if len(unique) < 2 or (unique == {-1}):
        return None
    valid = labels >= 0
    if valid.sum() < 2:
        return None
    try:
        from sklearn.metrics import silhouette_score
        return float(silhouette_score(X[valid], labels[valid], metric="euclidean"))
    except Exception:
        return None
