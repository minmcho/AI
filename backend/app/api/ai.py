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
