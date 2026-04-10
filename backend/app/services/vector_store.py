"""
ChromaDB vector store for RAG-based user wellness context retrieval.

Collection: user_wellness_context
Index type: HNSW (cosine similarity)

Each document represents a user wellness memory:
  - Dietary preferences
  - Health notes
  - Past session summaries
  - Goals and milestones
"""
from __future__ import annotations

import logging
from typing import Any

import chromadb
from chromadb.config import Settings as ChromaSettings

from app.config import get_settings

logger = logging.getLogger(__name__)
settings = get_settings()


class VectorStore:
    """
    Async-friendly wrapper around ChromaDB client.
    Uses the HNSW index with cosine distance for semantic retrieval.
    """

    COLLECTION_NAME = settings.CHROMA_COLLECTION
    EMBEDDING_MODEL = settings.EMBEDDING_MODEL

    def __init__(self) -> None:
        self._client: chromadb.AsyncHttpClient | None = None
        self._collection = None

    async def connect(self) -> None:
        self._client = await chromadb.AsyncHttpClient(
            host=settings.CHROMA_HOST,
            port=settings.CHROMA_PORT,
            settings=ChromaSettings(anonymized_telemetry=False),
        )
        self._collection = await self._client.get_or_create_collection(
            name=self.COLLECTION_NAME,
            metadata={"hnsw:space": "cosine"},
        )
        logger.info(
            "ChromaDB connected → collection=%r at %s:%s",
            self.COLLECTION_NAME,
            settings.CHROMA_HOST,
            settings.CHROMA_PORT,
        )

    # ── Write ────────────────────────────────────────────────

    async def upsert_user_context(
        self,
        user_id: str,
        documents: list[str],
        metadatas: list[dict] | None = None,
    ) -> None:
        """
        Upsert user wellness memories into the vector store.
        IDs are namespaced as `{user_id}::{index}` for easy bulk deletion.
        """
        ids = [f"{user_id}::{i}" for i in range(len(documents))]
        meta = metadatas or [{} for _ in documents]
        for m in meta:
            m.setdefault("user_id", user_id)

        await self._collection.upsert(
            ids=ids,
            documents=documents,
            metadatas=meta,
        )
        logger.debug("Upserted %d documents for user %s", len(documents), user_id)

    async def add_session_memory(
        self,
        user_id: str,
        session_id: str,
        summary: str,
        tags: list[str],
    ) -> None:
        """Add a post-session summary as a new memory document."""
        doc_id = f"{user_id}::session::{session_id}"
        await self._collection.upsert(
            ids=[doc_id],
            documents=[summary],
            metadatas=[{"user_id": user_id, "session_id": session_id, "tags": ",".join(tags)}],
        )

    # ── Read ─────────────────────────────────────────────────

    async def retrieve_context(
        self,
        user_id: str,
        query: str,
        n_results: int = 5,
    ) -> list[str]:
        """
        Retrieve the top-k most semantically relevant wellness memories
        for a given user and query.
        Returns list of document strings (memories).
        """
        try:
            results = await self._collection.query(
                query_texts=[query],
                n_results=n_results,
                where={"user_id": user_id},
            )
            docs: list[str] = results.get("documents", [[]])[0]
            logger.debug("Retrieved %d context docs for user %s", len(docs), user_id)
            return docs
        except Exception as exc:
            logger.warning("VectorStore retrieval failed: %s", exc)
            return []

    # ── Delete ───────────────────────────────────────────────

    async def delete_user_context(self, user_id: str) -> None:
        """Remove all wellness memories for a user (GDPR / account deletion)."""
        results = await self._collection.get(where={"user_id": user_id})
        ids: list[str] = results.get("ids", [])
        if ids:
            await self._collection.delete(ids=ids)
            logger.info("Deleted %d documents for user %s", len(ids), user_id)

    # ── Profile seeding ──────────────────────────────────────

    async def seed_user_profile(self, user_id: str, profile: dict[str, Any]) -> None:
        """
        Convert WellnessProfile fields into searchable text memories.
        Called when a user updates their profile or on first login.
        """
        documents: list[str] = []

        if prefs := profile.get("dietary_preferences"):
            documents.append(f"User dietary preferences: {', '.join(prefs)}")

        if notes := profile.get("health_notes"):
            documents.append(f"User wellness notes: {', '.join(notes)}")

        if goals := profile.get("wellness_goals"):
            documents.append(f"User wellness goals: {', '.join(goals)}")

        if pref_time := profile.get("preferred_session_time"):
            documents.append(f"User prefers wellness sessions in the {pref_time}")

        if documents:
            await self.upsert_user_context(user_id, documents)


# ── Singleton ────────────────────────────────────────────────

_vector_store: VectorStore | None = None


def get_vector_store() -> VectorStore:
    global _vector_store
    if _vector_store is None:
        _vector_store = VectorStore()
    return _vector_store
