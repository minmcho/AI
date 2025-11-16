import chromadb
from chromadb.config import Settings
from typing import List, Dict, Optional
from app.config.settings import get_settings

settings = get_settings()


class VectorStore:
    """ChromaDB vector store for embeddings and similarity search"""

    def __init__(self):
        self.client = chromadb.Client(Settings(
            persist_directory=settings.CHROMA_PERSIST_DIR,
            anonymized_telemetry=False,
        ))

        # Initialize collections
        self.recipe_collection = self._get_or_create_collection("recipes")
        self.ingredient_collection = self._get_or_create_collection("ingredients")
        self.meal_collection = self._get_or_create_collection("meals")
        self.cooking_collection = self._get_or_create_collection("cooking_instructions")

    def _get_or_create_collection(self, name: str):
        """Get or create a collection"""
        try:
            return self.client.get_collection(name=name)
        except:
            return self.client.create_collection(
                name=name,
                metadata={"hnsw:space": "cosine"}
            )

    async def add_recipe_embedding(
        self,
        recipe_id: str,
        embedding: List[float],
        metadata: Dict
    ):
        """Add recipe embedding to vector store"""
        self.recipe_collection.add(
            embeddings=[embedding],
            documents=[metadata.get("description", "")],
            metadatas=[metadata],
            ids=[recipe_id]
        )

    async def search_similar_recipes(
        self,
        query_embedding: List[float],
        limit: int = 10,
        filters: Optional[Dict] = None
    ) -> List[Dict]:
        """Search for similar recipes"""
        results = self.recipe_collection.query(
            query_embeddings=[query_embedding],
            n_results=limit,
            where=filters
        )

        return [
            {
                "id": results["ids"][0][i],
                "distance": results["distances"][0][i],
                "metadata": results["metadatas"][0][i],
            }
            for i in range(len(results["ids"][0]))
        ]

    async def add_ingredient_embedding(
        self,
        ingredient_id: str,
        embedding: List[float],
        metadata: Dict
    ):
        """Add ingredient embedding"""
        self.ingredient_collection.add(
            embeddings=[embedding],
            documents=[metadata.get("name", "")],
            metadatas=[metadata],
            ids=[ingredient_id]
        )

    async def find_ingredient_substitutes(
        self,
        query_embedding: List[float],
        limit: int = 5
    ) -> List[Dict]:
        """Find ingredient substitutes based on embedding similarity"""
        results = self.ingredient_collection.query(
            query_embeddings=[query_embedding],
            n_results=limit
        )

        return [
            {
                "id": results["ids"][0][i],
                "similarity": 1 - results["distances"][0][i],
                "metadata": results["metadatas"][0][i],
            }
            for i in range(len(results["ids"][0]))
        ]

    async def search_cross_cultural_meals(
        self,
        meal_embedding: List[float],
        limit: int = 5
    ) -> List[Dict]:
        """Find similar meals across different countries"""
        results = self.meal_collection.query(
            query_embeddings=[meal_embedding],
            n_results=limit
        )

        return [
            {
                "id": results["ids"][0][i],
                "similarity": 1 - results["distances"][0][i],
                "country": results["metadatas"][0][i].get("country"),
                "cuisine": results["metadatas"][0][i].get("cuisine"),
                "metadata": results["metadatas"][0][i],
            }
            for i in range(len(results["ids"][0]))
        ]


# Singleton instance
vector_store = VectorStore()
