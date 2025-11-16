from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from pydantic import BaseModel
from typing import Optional, List

from app.db.database import get_db
from app.services.auth_service import auth_service
from app.api.auth import oauth2_scheme, UserResponse
from app.agents.nutrition_agents import nutrition_planner

router = APIRouter(prefix="/profile", tags=["User Profile"])


class ProfileUpdate(BaseModel):
    full_name: Optional[str] = None
    age: Optional[int] = None
    weight_kg: Optional[float] = None
    height_cm: Optional[int] = None
    sex: Optional[str] = None
    activity_level: Optional[str] = None
    allergies: Optional[List[str]] = None
    dietary_restrictions: Optional[List[str]] = None
    health_goals: Optional[List[str]] = None
    cuisine_preferences: Optional[List[str]] = None
    disliked_ingredients: Optional[List[str]] = None
    medical_conditions: Optional[List[str]] = None
    medications: Optional[List[str]] = None


class NutritionRecommendationResponse(BaseModel):
    user_id: int
    recommendations: str
    bmi: Optional[float]
    bmi_category: Optional[str]
    generated_by: str


class PersonalizedMealPlanResponse(BaseModel):
    user_id: int
    days: int
    meal_plan: str
    user_profile: dict
    generated_by: str
    agents_used: List[str]


@router.put("/update", response_model=UserResponse)
async def update_profile(
    profile_data: ProfileUpdate,
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
    """
    Update user profile information

    - Updates health metrics, preferences, and dietary information
    - Automatically recalculates daily calorie target if relevant fields change
    - Returns updated user profile with new BMI calculation
    """
    user = await auth_service.get_current_user(db=db, token=token)

    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials"
        )

    # Update user profile
    update_data = profile_data.dict(exclude_unset=True)
    user = await auth_service.update_user_profile(db=db, user=user, **update_data)

    # Calculate BMI
    bmi = None
    bmi_category = None
    if user.weight_kg and user.height_cm:
        bmi = auth_service.calculate_bmi(user.weight_kg, user.height_cm)
        bmi_category = auth_service.get_bmi_category(bmi)

    return UserResponse(
        id=user.id,
        email=user.email,
        username=user.username,
        full_name=user.full_name,
        age=user.age,
        weight_kg=user.weight_kg,
        height_cm=user.height_cm,
        sex=user.sex.value if user.sex else None,
        target_calories=user.target_calories,
        bmi=round(bmi, 1) if bmi else None,
        bmi_category=bmi_category,
        allergies=user.allergies,
        dietary_restrictions=user.dietary_restrictions,
        health_goals=user.health_goals,
    )


@router.get("/nutrition-recommendations", response_model=NutritionRecommendationResponse)
async def get_nutrition_recommendations(
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
    """
    Get AI-powered personalized nutrition recommendations

    Uses smart AI agents to analyze your health profile and provide:
    - Current nutrition assessment
    - Specific recommendations for your health goals
    - Foods to emphasize and avoid
    - Supplement recommendations
    - Lifestyle tips
    - Timeline and expectations

    The recommendations are personalized based on:
    - Age, weight, height, sex
    - Activity level
    - Health goals
    - Dietary restrictions and allergies
    - Medical conditions
    """
    user = await auth_service.get_current_user(db=db, token=token)

    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials"
        )

    # Validate user has required profile data
    if not all([user.age, user.weight_kg, user.height_cm, user.sex]):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Please complete your profile (age, weight, height, sex) to get personalized recommendations"
        )

    # Get personalized recommendations
    recommendations = await nutrition_planner.get_personalized_recommendations(user)

    return NutritionRecommendationResponse(**recommendations)


@router.post("/generate-meal-plan", response_model=PersonalizedMealPlanResponse)
async def generate_personalized_meal_plan(
    days: int = 7,
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
    """
    Generate AI-powered personalized meal plan

    Creates a complete meal plan tailored to your profile using multi-agent AI system.

    The meal plan considers:
    - Your daily calorie target
    - Macronutrient ratios for your goals
    - All dietary restrictions
    - All allergies (strictly avoided)
    - Medical conditions
    - Food preferences
    - Variety and balance

    AI Agents used:
    1. **Macronutrient Calculator** - Calculates optimal protein/carbs/fat ratios
    2. **Personalized Nutrition Advisor** - Creates the meal plan
    3. **Allergy Safety Specialist** - Verifies all meals are allergen-free

    Args:
        days: Number of days for the meal plan (default: 7)

    Returns:
        Complete personalized meal plan with:
        - Daily meals (breakfast, lunch, dinner, snacks)
        - Portions and calories
        - Macro breakdown
        - Safety verification report
    """
    user = await auth_service.get_current_user(db=db, token=token)

    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials"
        )

    # Validate user has required profile data
    if not all([user.age, user.weight_kg, user.height_cm, user.sex]):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Please complete your profile (age, weight, height, sex) to generate a meal plan"
        )

    if days < 1 or days > 30:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Days must be between 1 and 30"
        )

    # Generate personalized meal plan
    meal_plan = await nutrition_planner.generate_personalized_meal_plan(
        user=user,
        days=days
    )

    return PersonalizedMealPlanResponse(**meal_plan)


@router.get("/health-summary")
async def get_health_summary(
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
    """
    Get comprehensive health summary

    Returns:
    - Current health metrics (BMI, calorie targets, etc.)
    - Health status assessment
    - Progress towards goals
    - Quick recommendations
    """
    user = await auth_service.get_current_user(db=db, token=token)

    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials"
        )

    # Calculate BMI
    bmi = None
    bmi_category = None
    if user.weight_kg and user.height_cm:
        bmi = auth_service.calculate_bmi(user.weight_kg, user.height_cm)
        bmi_category = auth_service.get_bmi_category(bmi)

    # Calculate macronutrient targets
    protein_target = None
    carbs_target = None
    fat_target = None

    if user.target_calories:
        # Standard macro distribution (can be customized based on goals)
        if "muscle_gain" in (user.health_goals or []):
            protein_ratio = 0.30  # 30% protein
            carbs_ratio = 0.40    # 40% carbs
            fat_ratio = 0.30      # 30% fat
        elif "weight_loss" in (user.health_goals or []):
            protein_ratio = 0.35  # 35% protein
            carbs_ratio = 0.30    # 30% carbs
            fat_ratio = 0.35      # 35% fat
        elif "keto" in (user.dietary_restrictions or []):
            protein_ratio = 0.25  # 25% protein
            carbs_ratio = 0.05    # 5% carbs
            fat_ratio = 0.70      # 70% fat
        else:  # balanced
            protein_ratio = 0.25  # 25% protein
            carbs_ratio = 0.45    # 45% carbs
            fat_ratio = 0.30      # 30% fat

        protein_target = (user.target_calories * protein_ratio) / 4  # 4 cal/g
        carbs_target = (user.target_calories * carbs_ratio) / 4      # 4 cal/g
        fat_target = (user.target_calories * fat_ratio) / 9          # 9 cal/g

    return {
        "user_id": user.id,
        "health_metrics": {
            "age": user.age,
            "weight_kg": user.weight_kg,
            "height_cm": user.height_cm,
            "sex": user.sex.value if user.sex else None,
            "bmi": round(bmi, 1) if bmi else None,
            "bmi_category": bmi_category,
            "activity_level": user.activity_level.value if user.activity_level else None,
        },
        "nutrition_targets": {
            "daily_calories": user.target_calories,
            "protein_g": round(protein_target, 1) if protein_target else None,
            "carbs_g": round(carbs_target, 1) if carbs_target else None,
            "fat_g": round(fat_target, 1) if fat_target else None,
        },
        "dietary_profile": {
            "restrictions": user.dietary_restrictions,
            "allergies": user.allergies,
            "health_goals": user.health_goals,
            "cuisine_preferences": user.cuisine_preferences,
            "disliked_ingredients": user.disliked_ingredients,
        },
        "medical_info": {
            "conditions": user.medical_conditions,
            "medications": user.medications,
        }
    }
