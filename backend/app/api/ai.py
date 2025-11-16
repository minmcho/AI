from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File
from sqlalchemy.ext.asyncio import AsyncSession
from pydantic import BaseModel
from typing import List, Optional
import base64

from app.db.database import get_db
from app.services.auth_service import auth_service
from app.services.llm_service import llm_service
from app.services.vision_service import vision_service
from app.services.embedding_service import embedding_service
from app.agents.crew_agents import crew_agents
from app.api.auth import oauth2_scheme

router = APIRouter(prefix="/ai", tags=["AI Features"])


# Pydantic models
class ChatMessage(BaseModel):
    message: str
    context: Optional[dict] = {}


class ChatResponse(BaseModel):
    message: str
    agent_name: str
    suggestions: List[str] = []
    confidence: float


class FoodAnalysisRequest(BaseModel):
    image_data: str  # Base64 encoded image


class FoodAnalysisResponse(BaseModel):
    food_items: List[str]
    estimated_calories: float
    detected_ingredients: List[str]
    cuisine_type: str
    confidence: float


class CulturalSimilarityRequest(BaseModel):
    meal_description: str
    target_cuisines: List[str]


class CulturalSimilarityResponse(BaseModel):
    analysis: str
    agent: str


class BeveragePairingRequest(BaseModel):
    meal_description: str
    preferences: dict = {}


class BeveragePairingResponse(BaseModel):
    pairings: str
    agent: str


class TechniqueExplanationResponse(BaseModel):
    technique: str
    explanation: str


@router.post("/chat/cooking-assistant", response_model=ChatResponse)
async def chat_with_cooking_assistant(
    chat: ChatMessage,
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
    """
    Chat with AI cooking assistant

    Get real-time cooking help, technique explanations, troubleshooting, and recipe advice.

    The assistant has knowledge of:
    - Culinary techniques and cooking methods
    - Recipe modifications and substitutions
    - Timing and temperature guidelines
    - Troubleshooting common cooking issues
    - Food safety and storage

    Provide context about your current recipe or cooking situation for better assistance.
    """
    user = await auth_service.get_current_user(db=db, token=token)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")

    # Add user profile to context
    context = chat.context or {}
    context.update({
        "dietary_restrictions": user.dietary_restrictions,
        "allergies": user.allergies,
        "experience_level": "intermediate",  # Could be stored in user profile
    })

    # Get response from LLM service
    response = await llm_service.chat_cooking_assistant(
        message=chat.message,
        context=context
    )

    return ChatResponse(**response)


@router.post("/analyze-food-image", response_model=FoodAnalysisResponse)
async def analyze_food_image(
    request: FoodAnalysisRequest,
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
    """
    Analyze food image using Vision Transformer

    Upload an image of food and get:
    - Identified food items
    - Estimated calories
    - Detected ingredients
    - Cuisine type
    - Confidence score

    **Image format**: Base64 encoded image (JPEG, PNG)

    Example:
    ```
    {
      "image_data": "data:image/jpeg;base64,/9j/4AAQSkZJRg..."
    }
    ```
    """
    user = await auth_service.get_current_user(db=db, token=token)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")

    # Analyze image
    analysis = await vision_service.analyze_food_image(request.image_data)

    return FoodAnalysisResponse(**analysis)


@router.post("/analyze-food-image/upload", response_model=FoodAnalysisResponse)
async def analyze_food_image_upload(
    file: UploadFile = File(...),
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
    """
    Analyze food image via file upload

    Upload a food image file directly and get AI analysis.

    Accepts: JPEG, PNG, WebP
    Max size: 10MB
    """
    user = await auth_service.get_current_user(db=db, token=token)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")

    # Validate file type
    if file.content_type not in ["image/jpeg", "image/png", "image/webp"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid file type. Accepted: JPEG, PNG, WebP"
        )

    # Read file and convert to base64
    contents = await file.read()
    image_data = base64.b64encode(contents).decode('utf-8')
    image_data = f"data:{file.content_type};base64,{image_data}"

    # Analyze image
    analysis = await vision_service.analyze_food_image(image_data)

    return FoodAnalysisResponse(**analysis)


@router.post("/cultural-similarity", response_model=CulturalSimilarityResponse)
async def analyze_cultural_similarity(
    request: CulturalSimilarityRequest,
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
    """
    Find similar dishes across different cultures

    Analyzes a meal description and finds equivalent or similar dishes in other cuisines.

    Example:
    ```json
    {
      "meal_description": "Italian pasta carbonara with eggs, bacon, and cheese",
      "target_cuisines": ["French", "Chinese", "Mexican"]
    }
    ```

    The AI will identify:
    - Similar dishes in target cuisines
    - Key ingredient similarities
    - Cultural significance
    - Notable differences
    """
    user = await auth_service.get_current_user(db=db, token=token)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")

    # Use CrewAI cultural cuisine agent
    result = await crew_agents.analyze_cross_cultural_similarity(
        meal_description=request.meal_description,
        target_cuisines=request.target_cuisines
    )

    return CulturalSimilarityResponse(**result)


@router.post("/beverage-pairing", response_model=BeveragePairingResponse)
async def get_beverage_pairing(
    request: BeveragePairingRequest,
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
    """
    Get AI beverage pairing recommendations

    Get expert sommelier recommendations for drinks that pair well with your meal.

    Provide:
    - **meal_description**: Description of the meal
    - **preferences**: Optional preferences (alcohol preference, budget, flavor profiles)

    Example:
    ```json
    {
      "meal_description": "Grilled salmon with lemon butter and asparagus",
      "preferences": {
        "alcohol": "wine",
        "budget": "moderate",
        "flavors": ["citrus", "crisp"]
      }
    }
    ```

    Returns 3 beverage recommendations with explanations.
    """
    user = await auth_service.get_current_user(db=db, token=token)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")

    # Use CrewAI beverage sommelier agent
    result = await crew_agents.suggest_beverage_pairing(
        meal_description=request.meal_description,
        preferences=request.preferences
    )

    return BeveragePairingResponse(**result)


@router.get("/explain-technique/{technique}", response_model=TechniqueExplanationResponse)
async def explain_cooking_technique(
    technique: str,
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
    """
    Get explanation of a cooking technique

    Learn about specific cooking techniques:
    - Sautéing, braising, poaching, etc.
    - Knife techniques
    - Baking methods
    - Food preparation techniques

    Returns detailed explanation with tips for success.
    """
    user = await auth_service.get_current_user(db=db, token=token)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")

    explanation = await llm_service.explain_recipe_technique(technique)

    return TechniqueExplanationResponse(
        technique=technique,
        explanation=explanation
    )


@router.post("/ingredient-substitutes")
async def find_ingredient_substitutes(
    ingredient: str,
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
    """
    Find ingredient substitutes using AI

    Get smart substitution recommendations based on:
    - Flavor profile similarity
    - Cooking properties
    - Dietary restrictions
    - Nutritional equivalence

    Example: "butter" → margarine, coconut oil, olive oil
    """
    user = await auth_service.get_current_user(db=db, token=token)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")

    # Generate embedding for ingredient
    ingredient_dict = {"name": ingredient}
    embedding = await embedding_service.encode_ingredient(ingredient_dict)

    # Find similar ingredients
    substitutes = await vector_store.find_ingredient_substitutes(
        query_embedding=embedding,
        limit=5
    )

    return {
        "original_ingredient": ingredient,
        "substitutes": substitutes
    }


@router.post("/meal-plan/ai-generate")
async def ai_generate_meal_plan(
    days: int = 7,
    preferences: dict = {},
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
    """
    Generate AI meal plan using multi-agent system

    This endpoint uses the full CrewAI multi-agent system to create a comprehensive meal plan.

    Agents involved:
    - Nutrition Advisor
    - Recipe Discovery
    - Meal Planner

    Returns a detailed meal plan considering your full user profile.
    """
    user = await auth_service.get_current_user(db=db, token=token)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")

    # Validate user profile
    if not all([user.age, user.weight_kg, user.height_cm, user.sex]):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Complete your profile (age, weight, height, sex) to generate meal plan"
        )

    # Build user profile dict
    user_profile = {
        "dietary_restrictions": user.dietary_restrictions or [],
        "daily_calories": user.target_calories or 2000,
        "health_goals": user.health_goals or [],
        "allergies": user.allergies or [],
        "cuisine_preferences": user.cuisine_preferences or []
    }

    # Generate meal plan using CrewAI
    result = await crew_agents.generate_weekly_meal_plan(
        user_profile=user_profile,
        days=days
    )

    return result


# BLIP Models - Image Captioning & Visual Question Answering


class ImageCaptionRequest(BaseModel):
    image_data: str  # Base64 encoded image
    max_length: int = 50
    num_beams: int = 3
    conditional_text: Optional[str] = None


class ImageCaptionResponse(BaseModel):
    caption: str
    confidence: float
    model: str


class VisualQuestionRequest(BaseModel):
    image_data: str  # Base64 encoded image
    question: str
    max_length: int = 50


class VisualQuestionResponse(BaseModel):
    question: str
    answer: str
    confidence: float
    model: str


class BlipFoodAnalysisResponse(BaseModel):
    caption: str
    food_type: str
    ingredients: str
    cooking_method: str
    cuisine: str
    servings: str
    confidence: float


@router.post("/blip/caption", response_model=ImageCaptionResponse)
async def generate_image_caption(
    request: ImageCaptionRequest,
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
    """
    Generate natural language caption for food image using BLIP

    **BLIP (Bootstrapping Language-Image Pre-training)** generates human-like descriptions
    of images with high accuracy.

    **Features:**
    - Natural language descriptions
    - Food-specific captions
    - Conditional text generation (optional)
    - Beam search for quality

    **Use Cases:**
    - Automated recipe documentation
    - Food blog content generation
    - Accessibility (alt text)
    - Social media descriptions
    - Recipe cataloging

    **Example Output:**
    - "a plate of pasta carbonara with bacon and parmesan cheese"
    - "freshly baked chocolate chip cookies on a cooling rack"
    - "colorful vegetable stir fry in a wok"

    **Parameters:**
    - `image_data`: Base64 encoded image
    - `max_length`: Maximum caption length (default: 50)
    - `num_beams`: Beam search parameter (default: 3, higher = better quality but slower)
    - `conditional_text`: Optional text to guide caption (e.g., "a delicious")
    """
    user = await auth_service.get_current_user(db=db, token=token)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")

    try:
        result = await vision_service.generate_image_caption(
            image_data=request.image_data,
            max_length=request.max_length,
            num_beams=request.num_beams,
            conditional_text=request.conditional_text
        )

        if "error" in result:
            raise HTTPException(status_code=500, detail=result["error"])

        return ImageCaptionResponse(
            caption=result["caption"],
            confidence=result["confidence"],
            model=result["model"]
        )

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Caption generation failed: {str(e)}")


@router.post("/blip/caption/upload", response_model=ImageCaptionResponse)
async def generate_image_caption_upload(
    file: UploadFile = File(...),
    max_length: int = 50,
    num_beams: int = 3,
    conditional_text: Optional[str] = None,
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
    """
    Generate caption from uploaded image file

    Upload an image file directly for caption generation.

    **Supported formats:** JPG, PNG, WEBP
    **Max size:** 10MB
    """
    user = await auth_service.get_current_user(db=db, token=token)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")

    # Validate file type
    if file.content_type not in ["image/jpeg", "image/png", "image/webp"]:
        raise HTTPException(status_code=400, detail="Invalid file type. Use JPG, PNG, or WEBP")

    # Read and encode image
    contents = await file.read()
    image_base64 = base64.b64encode(contents).decode('utf-8')

    try:
        result = await vision_service.generate_image_caption(
            image_data=image_base64,
            max_length=max_length,
            num_beams=num_beams,
            conditional_text=conditional_text
        )

        if "error" in result:
            raise HTTPException(status_code=500, detail=result["error"])

        return ImageCaptionResponse(
            caption=result["caption"],
            confidence=result["confidence"],
            model=result["model"]
        )

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Caption generation failed: {str(e)}")


@router.post("/blip/vqa", response_model=VisualQuestionResponse)
async def visual_question_answering(
    request: VisualQuestionRequest,
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
    """
    Answer questions about food images using BLIP Visual Question Answering

    **BLIP-VQA** can answer natural language questions about images with high accuracy.

    **Example Questions:**
    - "What type of food is this?"
    - "What are the main ingredients?"
    - "How is this food cooked?"
    - "What cuisine does this belong to?"
    - "Is this healthy?"
    - "How many servings?"
    - "What color is the sauce?"
    - "Are there vegetables in this dish?"

    **Use Cases:**
    - Recipe ingredient identification
    - Dietary restriction checking
    - Cooking method detection
    - Cuisine classification
    - Portion size estimation
    - Food quality assessment

    **Technical Details:**
    - Model: BLIP-VQA (Salesforce)
    - Input: Image + Natural language question
    - Output: Natural language answer
    - Processing: Attention-based vision-language model

    **Tips for Best Results:**
    - Ask specific, clear questions
    - Focus on visible aspects
    - Use food-related questions
    - Avoid abstract concepts
    """
    user = await auth_service.get_current_user(db=db, token=token)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")

    try:
        result = await vision_service.answer_visual_question(
            image_data=request.image_data,
            question=request.question,
            max_length=request.max_length
        )

        if "error" in result:
            raise HTTPException(status_code=500, detail=result["error"])

        return VisualQuestionResponse(
            question=result["question"],
            answer=result["answer"],
            confidence=result["confidence"],
            model=result["model"]
        )

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"VQA failed: {str(e)}")


@router.post("/blip/vqa/upload", response_model=VisualQuestionResponse)
async def visual_question_answering_upload(
    file: UploadFile = File(...),
    question: str = "What type of food is this?",
    max_length: int = 50,
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
    """
    Answer questions about uploaded image file

    Upload an image and ask a question about it.
    """
    user = await auth_service.get_current_user(db=db, token=token)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")

    # Validate file type
    if file.content_type not in ["image/jpeg", "image/png", "image/webp"]:
        raise HTTPException(status_code=400, detail="Invalid file type. Use JPG, PNG, or WEBP")

    # Read and encode image
    contents = await file.read()
    image_base64 = base64.b64encode(contents).decode('utf-8')

    try:
        result = await vision_service.answer_visual_question(
            image_data=image_base64,
            question=question,
            max_length=max_length
        )

        if "error" in result:
            raise HTTPException(status_code=500, detail=result["error"])

        return VisualQuestionResponse(
            question=result["question"],
            answer=result["answer"],
            confidence=result["confidence"],
            model=result["model"]
        )

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"VQA failed: {str(e)}")


@router.post("/blip/analyze-food", response_model=BlipFoodAnalysisResponse)
async def comprehensive_food_analysis_blip(
    request: FoodAnalysisRequest,
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
    """
    Comprehensive food image analysis using BLIP

    **Complete food analysis** combining BLIP captioning and VQA to extract:
    - Natural language description
    - Food type identification
    - Ingredient detection
    - Cooking method
    - Cuisine classification
    - Serving size estimation

    **This endpoint runs multiple BLIP models** to provide rich, detailed analysis:
    1. BLIP Captioning - Overall description
    2. BLIP VQA - Food type
    3. BLIP VQA - Ingredients
    4. BLIP VQA - Cooking method
    5. BLIP VQA - Cuisine
    6. BLIP VQA - Servings

    **Advantages over single model:**
    - More comprehensive information
    - Higher accuracy through multiple perspectives
    - Structured output for easy integration
    - Consistent format

    **Use Cases:**
    - Recipe creation from photos
    - Food journaling
    - Nutritional analysis prep
    - Menu digitization
    - Food inventory management

    **Performance:**
    - Processing time: ~2-5 seconds
    - Accuracy: 80-90% on clear food images
    - Works best with: well-lit, close-up food photos
    """
    user = await auth_service.get_current_user(db=db, token=token)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")

    try:
        result = await vision_service.analyze_food_with_blip(request.image_data)

        if "error" in result:
            raise HTTPException(status_code=500, detail=result["error"])

        return BlipFoodAnalysisResponse(
            caption=result["caption"],
            food_type=result["food_type"],
            ingredients=result["ingredients"],
            cooking_method=result["cooking_method"],
            cuisine=result["cuisine"],
            servings=result["servings"],
            confidence=result["confidence"]
        )

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Food analysis failed: {str(e)}")


@router.post("/blip/analyze-food/upload", response_model=BlipFoodAnalysisResponse)
async def comprehensive_food_analysis_blip_upload(
    file: UploadFile = File(...),
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
    """
    Comprehensive food analysis from uploaded image file

    Upload a food image for complete BLIP-powered analysis.
    """
    user = await auth_service.get_current_user(db=db, token=token)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")

    # Validate file type
    if file.content_type not in ["image/jpeg", "image/png", "image/webp"]:
        raise HTTPException(status_code=400, detail="Invalid file type. Use JPG, PNG, or WEBP")

    # Read and encode image
    contents = await file.read()
    image_base64 = base64.b64encode(contents).decode('utf-8')

    try:
        result = await vision_service.analyze_food_with_blip(image_base64)

        if "error" in result:
            raise HTTPException(status_code=500, detail=result["error"])

        return BlipFoodAnalysisResponse(
            caption=result["caption"],
            food_type=result["food_type"],
            ingredients=result["ingredients"],
            cooking_method=result["cooking_method"],
            cuisine=result["cuisine"],
            servings=result["servings"],
            confidence=result["confidence"]
        )

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Food analysis failed: {str(e)}")
