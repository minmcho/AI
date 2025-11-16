import torch
from transformers import ViTImageProcessor, ViTForImageClassification
from transformers import CLIPProcessor, CLIPModel
from PIL import Image
import io
import base64
from typing import List, Dict, Tuple
from app.config.settings import get_settings

settings = get_settings()


class VisionService:
    """Service for Vision Transformer and CLIP models"""

    def __init__(self):
        self.device = "cuda" if torch.cuda.is_available() else "cpu"
        print(f"Vision models using device: {self.device}")

        # Vision Transformer for food classification
        self.vit_processor = None
        self.vit_model = None

        # CLIP for image-text matching
        self.clip_processor = None
        self.clip_model = None

    def _load_vit_model(self):
        """Lazy load ViT model"""
        if self.vit_model is None:
            print("Loading Vision Transformer model...")
            self.vit_processor = ViTImageProcessor.from_pretrained(
                settings.VISION_MODEL
            )
            self.vit_model = ViTForImageClassification.from_pretrained(
                settings.VISION_MODEL
            ).to(self.device)

    def _load_clip_model(self):
        """Lazy load CLIP model"""
        if self.clip_model is None:
            print("Loading CLIP model...")
            self.clip_processor = CLIPProcessor.from_pretrained(
                "openai/clip-vit-base-patch32"
            )
            self.clip_model = CLIPModel.from_pretrained(
                "openai/clip-vit-base-patch32"
            ).to(self.device)

    async def analyze_food_image(self, image_data: str) -> Dict:
        """Analyze food image and identify contents"""
        self._load_vit_model()

        try:
            # Decode base64 image
            image_bytes = base64.b64decode(image_data.split(",")[1])
            image = Image.open(io.BytesIO(image_bytes))

            # Process image
            inputs = self.vit_processor(images=image, return_tensors="pt")
            inputs = {k: v.to(self.device) for k, v in inputs.items()}

            # Get predictions
            with torch.no_grad():
                outputs = self.vit_model(**inputs)
                logits = outputs.logits
                predicted_class = logits.argmax(-1).item()
                confidence = torch.softmax(logits, dim=-1).max().item()

            # Note: For production, use a food-specific model
            # like Food-101 or fine-tuned ViT on food dataset
            return {
                "food_items": [f"Food class {predicted_class}"],
                "estimated_calories": 0.0,  # Requires specialized model
                "detected_ingredients": [],
                "cuisine_type": "unknown",
                "confidence": confidence
            }

        except Exception as e:
            return {
                "error": str(e),
                "food_items": [],
                "estimated_calories": 0.0,
                "detected_ingredients": [],
                "cuisine_type": "unknown",
                "confidence": 0.0
            }

    async def get_image_embedding(self, image: Image.Image) -> List[float]:
        """Get CLIP embedding for image"""
        self._load_clip_model()

        inputs = self.clip_processor(
            images=image,
            return_tensors="pt",
            padding=True
        ).to(self.device)

        with torch.no_grad():
            image_features = self.clip_model.get_image_features(**inputs)
            # Normalize embeddings
            image_features = image_features / image_features.norm(dim=-1, keepdim=True)

        return image_features.cpu().numpy().flatten().tolist()

    async def match_image_to_recipes(
        self,
        image_data: str,
        recipe_descriptions: List[str]
    ) -> List[Tuple[int, float]]:
        """Match image to recipe descriptions using CLIP"""
        self._load_clip_model()

        # Decode image
        image_bytes = base64.b64decode(image_data.split(",")[1])
        image = Image.open(io.BytesIO(image_bytes))

        # Process inputs
        inputs = self.clip_processor(
            text=recipe_descriptions,
            images=image,
            return_tensors="pt",
            padding=True
        ).to(self.device)

        with torch.no_grad():
            outputs = self.clip_model(**inputs)
            logits_per_image = outputs.logits_per_image
            probs = logits_per_image.softmax(dim=1)

        # Return indices and scores
        results = [
            (idx, score.item())
            for idx, score in enumerate(probs[0])
        ]
        results.sort(key=lambda x: x[1], reverse=True)

        return results

    async def estimate_portion_size(self, image_data: str) -> Dict:
        """Estimate portion size from image (requires specialized model)"""
        # This would require a specialized model trained on portion estimation
        # For now, return placeholder
        return {
            "portion_size": "medium",
            "estimated_grams": 200,
            "confidence": 0.5
        }


# Singleton instance
vision_service = VisionService()
