import torch
from transformers import ViTImageProcessor, ViTForImageClassification
from transformers import CLIPProcessor, CLIPModel
from transformers import BlipProcessor, BlipForConditionalGeneration, BlipForQuestionAnswering
from PIL import Image
import io
import base64
from typing import List, Dict, Tuple, Optional
from app.config.settings import get_settings

settings = get_settings()


class VisionService:
    """Service for Vision Transformer, CLIP, and BLIP models"""

    def __init__(self):
        self.device = "cuda" if torch.cuda.is_available() else "cpu"
        print(f"Vision models using device: {self.device}")

        # Vision Transformer for food classification
        self.vit_processor = None
        self.vit_model = None

        # CLIP for image-text matching
        self.clip_processor = None
        self.clip_model = None

        # BLIP for image captioning
        self.blip_caption_processor = None
        self.blip_caption_model = None

        # BLIP for visual question answering
        self.blip_vqa_processor = None
        self.blip_vqa_model = None

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

    def _load_blip_caption_model(self):
        """Lazy load BLIP image captioning model"""
        if self.blip_caption_model is None:
            print("Loading BLIP image captioning model...")
            model_name = getattr(settings, 'BLIP_CAPTION_MODEL', 'Salesforce/blip-image-captioning-base')
            self.blip_caption_processor = BlipProcessor.from_pretrained(model_name)
            self.blip_caption_model = BlipForConditionalGeneration.from_pretrained(
                model_name
            ).to(self.device)
            print("✅ BLIP captioning model loaded")

    def _load_blip_vqa_model(self):
        """Lazy load BLIP Visual Question Answering model"""
        if self.blip_vqa_model is None:
            print("Loading BLIP VQA model...")
            model_name = getattr(settings, 'BLIP_VQA_MODEL', 'Salesforce/blip-vqa-base')
            self.blip_vqa_processor = BlipProcessor.from_pretrained(model_name)
            self.blip_vqa_model = BlipForQuestionAnswering.from_pretrained(
                model_name
            ).to(self.device)
            print("✅ BLIP VQA model loaded")

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

    async def generate_image_caption(
        self,
        image_data: str,
        max_length: int = 50,
        num_beams: int = 3,
        conditional_text: Optional[str] = None
    ) -> Dict:
        """
        Generate natural language caption for food image using BLIP

        Args:
            image_data: Base64 encoded image or image bytes
            max_length: Maximum length of generated caption
            num_beams: Number of beams for beam search
            conditional_text: Optional text to condition the caption generation

        Returns:
            {
                "caption": "Generated caption describing the food",
                "confidence": 0.95,
                "model": "BLIP"
            }
        """
        self._load_blip_caption_model()

        try:
            # Decode image
            if "," in image_data:
                image_bytes = base64.b64decode(image_data.split(",")[1])
            else:
                image_bytes = base64.b64decode(image_data)
            image = Image.open(io.BytesIO(image_bytes)).convert('RGB')

            # Process image
            if conditional_text:
                # Conditional caption generation (e.g., "a photo of")
                inputs = self.blip_caption_processor(
                    images=image,
                    text=conditional_text,
                    return_tensors="pt"
                ).to(self.device)
            else:
                # Unconditional caption generation
                inputs = self.blip_caption_processor(
                    images=image,
                    return_tensors="pt"
                ).to(self.device)

            # Generate caption
            with torch.no_grad():
                outputs = self.blip_caption_model.generate(
                    **inputs,
                    max_length=max_length,
                    num_beams=num_beams,
                    early_stopping=True
                )

            # Decode caption
            caption = self.blip_caption_processor.decode(
                outputs[0],
                skip_special_tokens=True
            )

            return {
                "caption": caption,
                "confidence": 0.9,  # BLIP doesn't provide explicit confidence
                "model": "BLIP",
                "conditional": conditional_text is not None
            }

        except Exception as e:
            return {
                "error": str(e),
                "caption": "",
                "confidence": 0.0,
                "model": "BLIP"
            }

    async def answer_visual_question(
        self,
        image_data: str,
        question: str,
        max_length: int = 50
    ) -> Dict:
        """
        Answer questions about food image using BLIP VQA

        Args:
            image_data: Base64 encoded image
            question: Question about the image
            max_length: Maximum length of answer

        Returns:
            {
                "question": "What food is this?",
                "answer": "pasta carbonara",
                "confidence": 0.95,
                "model": "BLIP-VQA"
            }
        """
        self._load_blip_vqa_model()

        try:
            # Decode image
            if "," in image_data:
                image_bytes = base64.b64decode(image_data.split(",")[1])
            else:
                image_bytes = base64.b64decode(image_data)
            image = Image.open(io.BytesIO(image_bytes)).convert('RGB')

            # Process inputs
            inputs = self.blip_vqa_processor(
                images=image,
                text=question,
                return_tensors="pt"
            ).to(self.device)

            # Generate answer
            with torch.no_grad():
                outputs = self.blip_vqa_model.generate(
                    **inputs,
                    max_length=max_length
                )

            # Decode answer
            answer = self.blip_vqa_processor.decode(
                outputs[0],
                skip_special_tokens=True
            )

            return {
                "question": question,
                "answer": answer,
                "confidence": 0.9,
                "model": "BLIP-VQA"
            }

        except Exception as e:
            return {
                "error": str(e),
                "question": question,
                "answer": "",
                "confidence": 0.0,
                "model": "BLIP-VQA"
            }

    async def analyze_food_with_blip(self, image_data: str) -> Dict:
        """
        Comprehensive food image analysis using BLIP

        Combines caption generation and answers common food-related questions

        Returns:
            {
                "caption": "Description of the food",
                "food_type": "pasta",
                "ingredients": ["pasta", "cheese", "bacon"],
                "cooking_method": "boiled and sautéed",
                "presentation": "plated with garnish",
                "estimated_servings": 1
            }
        """
        self._load_blip_caption_model()
        self._load_blip_vqa_model()

        try:
            # Decode image once
            if "," in image_data:
                image_bytes = base64.b64decode(image_data.split(",")[1])
            else:
                image_bytes = base64.b64decode(image_data)
            image = Image.open(io.BytesIO(image_bytes)).convert('RGB')

            # Generate caption
            caption_inputs = self.blip_caption_processor(
                images=image,
                return_tensors="pt"
            ).to(self.device)

            with torch.no_grad():
                caption_output = self.blip_caption_model.generate(
                    **caption_inputs,
                    max_length=50,
                    num_beams=3
                )
            caption = self.blip_caption_processor.decode(
                caption_output[0],
                skip_special_tokens=True
            )

            # Ask multiple questions about the food
            questions = [
                "What type of food is this?",
                "What are the main ingredients?",
                "How is this food prepared?",
                "What cuisine is this?",
                "How many servings does this appear to be?"
            ]

            answers = {}
            for question in questions:
                vqa_inputs = self.blip_vqa_processor(
                    images=image,
                    text=question,
                    return_tensors="pt"
                ).to(self.device)

                with torch.no_grad():
                    vqa_output = self.blip_vqa_model.generate(**vqa_inputs, max_length=20)

                answer = self.blip_vqa_processor.decode(
                    vqa_output[0],
                    skip_special_tokens=True
                )
                answers[question] = answer

            return {
                "caption": caption,
                "food_type": answers.get("What type of food is this?", "unknown"),
                "ingredients": answers.get("What are the main ingredients?", "unknown"),
                "cooking_method": answers.get("How is this food prepared?", "unknown"),
                "cuisine": answers.get("What cuisine is this?", "unknown"),
                "servings": answers.get("How many servings does this appear to be?", "1"),
                "model": "BLIP (Comprehensive)",
                "confidence": 0.85
            }

        except Exception as e:
            return {
                "error": str(e),
                "caption": "",
                "food_type": "unknown",
                "ingredients": "",
                "cooking_method": "",
                "cuisine": "unknown",
                "servings": "1",
                "confidence": 0.0
            }


# Singleton instance
vision_service = VisionService()
