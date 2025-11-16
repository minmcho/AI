from sentence_transformers import SentenceTransformer
from typing import List, Dict
import torch
from app.config.settings import get_settings

settings = get_settings()


class EmbeddingService:
    """Service for Sentence Transformers embeddings"""

    def __init__(self):
        self.device = "cuda" if torch.cuda.is_available() else "cpu"
        self.model = None

    def _load_model(self):
        """Lazy load sentence transformer model"""
        if self.model is None:
            print(f"Loading Sentence Transformer: {settings.SENTENCE_TRANSFORMER_MODEL}")
            self.model = SentenceTransformer(
                settings.SENTENCE_TRANSFORMER_MODEL,
                device=self.device
            )

    async def encode_text(self, text: str) -> List[float]:
        """Encode single text to embedding"""
        self._load_model()
        embedding = self.model.encode(text, convert_to_tensor=True)
        return embedding.cpu().numpy().tolist()

    async def encode_batch(self, texts: List[str]) -> List[List[float]]:
        """Encode multiple texts to embeddings"""
        self._load_model()
        embeddings = self.model.encode(texts, convert_to_tensor=True)
        return embeddings.cpu().numpy().tolist()

    async def encode_recipe(self, recipe: Dict) -> List[float]:
        """Create comprehensive recipe embedding"""
        self._load_model()

        # Combine recipe information into rich text
        recipe_text = f"""
        {recipe.get('name', '')}
        Cuisine: {recipe.get('cuisine', '')}
        Description: {recipe.get('description', '')}
        Ingredients: {', '.join(recipe.get('ingredients', []))}
        Tags: {', '.join(recipe.get('tags', []))}
        Dietary: {', '.join(recipe.get('dietary_tags', []))}
        """.strip()

        return await self.encode_text(recipe_text)

    async def encode_ingredient(self, ingredient: Dict) -> List[float]:
        """Create ingredient embedding"""
        self._load_model()

        ingredient_text = f"""
        {ingredient.get('name', '')}
        Category: {ingredient.get('category', '')}
        """.strip()

        return await self.encode_text(ingredient_text)

    async def calculate_similarity(
        self,
        embedding1: List[float],
        embedding2: List[float]
    ) -> float:
        """Calculate cosine similarity between two embeddings"""
        import numpy as np

        vec1 = np.array(embedding1)
        vec2 = np.array(embedding2)

        # Cosine similarity
        similarity = np.dot(vec1, vec2) / (np.linalg.norm(vec1) * np.linalg.norm(vec2))

        return float(similarity)

    async def find_similar_texts(
        self,
        query: str,
        corpus: List[str],
        top_k: int = 5
    ) -> List[Dict]:
        """Find most similar texts in corpus"""
        self._load_model()

        # Encode query and corpus
        query_embedding = self.model.encode(query, convert_to_tensor=True)
        corpus_embeddings = self.model.encode(corpus, convert_to_tensor=True)

        # Calculate similarities
        from sentence_transformers import util
        similarities = util.cos_sim(query_embedding, corpus_embeddings)[0]

        # Get top-k results
        top_results = torch.topk(similarities, k=min(top_k, len(corpus)))

        results = []
        for score, idx in zip(top_results.values, top_results.indices):
            results.append({
                "index": idx.item(),
                "text": corpus[idx.item()],
                "similarity": score.item()
            })

        return results

    async def encode_multilingual(self, text: str, language: str = "en") -> List[float]:
        """Encode text in multiple languages (for cross-cultural meal matching)"""
        # For production, use multilingual model like 'paraphrase-multilingual-MiniLM-L12-v2'
        return await self.encode_text(text)


# Singleton instance
embedding_service = EmbeddingService()
