from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, or_, func
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime

from app.db.database import get_db
from app.models.recipe import Recipe, Ingredient
from app.services.auth_service import auth_service
from app.services.embedding_service import embedding_service
from app.services.vector_store import vector_store
from app.api.auth import oauth2_scheme

router = APIRouter(prefix="/recipes", tags=["Recipes"])


# Pydantic models
class IngredientCreate(BaseModel):
    name: str
    quantity: float
    unit: str


class RecipeCreate(BaseModel):
    name: str
    description: Optional[str] = None
    cuisine: str
    country_origin: str
    prep_time_minutes: int
    cook_time_minutes: int
    servings: int = 4
    difficulty: str = "medium"
    instructions: List[str]
    ingredients: List[IngredientCreate]
    tags: List[str] = []
    dietary_tags: List[str] = []
    image_url: Optional[str] = None


class RecipeResponse(BaseModel):
    id: int
    name: str
    description: Optional[str]
    cuisine: str
    country_origin: str
    prep_time_minutes: int
    cook_time_minutes: int
    total_time_minutes: int
    servings: int
    difficulty: str
    calories: Optional[float]
    protein_g: Optional[float]
    rating_avg: float
    tags: List[str]
    dietary_tags: List[str]
    image_url: Optional[str]

    class Config:
        from_attributes = True


class RecipeDetailResponse(RecipeResponse):
    instructions: List[str]
    ingredients: List[dict]
    tips: Optional[List[str]]


@router.post("/", response_model=RecipeResponse, status_code=status.HTTP_201_CREATED)
async def create_recipe(
    recipe_data: RecipeCreate,
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
    """
    Create a new recipe

    Requires authentication. Creates a recipe with ingredients and generates embeddings for similarity search.
    """
    user = await auth_service.get_current_user(db=db, token=token)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")

    # Create recipe
    recipe = Recipe(
        name=recipe_data.name,
        description=recipe_data.description,
        cuisine=recipe_data.cuisine,
        country_origin=recipe_data.country_origin,
        prep_time_minutes=recipe_data.prep_time_minutes,
        cook_time_minutes=recipe_data.cook_time_minutes,
        total_time_minutes=recipe_data.prep_time_minutes + recipe_data.cook_time_minutes,
        servings=recipe_data.servings,
        difficulty=recipe_data.difficulty,
        instructions=recipe_data.instructions,
        tags=recipe_data.tags,
        dietary_tags=recipe_data.dietary_tags,
        image_url=recipe_data.image_url,
        is_verified=False
    )

    db.add(recipe)
    await db.flush()

    # Generate embedding for similarity search
    recipe_dict = {
        "name": recipe.name,
        "description": recipe.description or "",
        "cuisine": recipe.cuisine,
        "ingredients": [ing.name for ing in recipe_data.ingredients],
        "tags": recipe.tags,
        "dietary_tags": recipe.dietary_tags
    }

    embedding = await embedding_service.encode_recipe(recipe_dict)

    # Store in vector database
    await vector_store.add_recipe_embedding(
        recipe_id=str(recipe.id),
        embedding=embedding,
        metadata={
            "name": recipe.name,
            "cuisine": recipe.cuisine,
            "description": recipe.description or ""
        }
    )

    await db.commit()
    await db.refresh(recipe)

    return recipe


@router.get("/search", response_model=List[RecipeResponse])
async def search_recipes(
    query: str = Query(..., min_length=2),
    cuisine: Optional[str] = None,
    max_prep_time: Optional[int] = None,
    dietary_tags: Optional[List[str]] = Query(None),
    limit: int = Query(20, le=100),
    db: AsyncSession = Depends(get_db)
):
    """
    Search recipes by text query

    - **query**: Search term (name, description, ingredients)
    - **cuisine**: Filter by cuisine type
    - **max_prep_time**: Maximum preparation time in minutes
    - **dietary_tags**: Filter by dietary tags (vegan, gluten-free, etc.)
    - **limit**: Maximum number of results (max 100)
    """
    # Build query
    stmt = select(Recipe).where(
        or_(
            Recipe.name.ilike(f"%{query}%"),
            Recipe.description.ilike(f"%{query}%"),
            Recipe.cuisine.ilike(f"%{query}%")
        )
    )

    if cuisine:
        stmt = stmt.where(Recipe.cuisine == cuisine)

    if max_prep_time:
        stmt = stmt.where(Recipe.prep_time_minutes <= max_prep_time)

    if dietary_tags:
        for tag in dietary_tags:
            stmt = stmt.where(Recipe.dietary_tags.contains([tag]))

    stmt = stmt.limit(limit)

    result = await db.execute(stmt)
    recipes = result.scalars().all()

    return recipes


@router.get("/similar/{recipe_id}", response_model=List[RecipeResponse])
async def get_similar_recipes(
    recipe_id: int,
    limit: int = Query(10, le=50),
    db: AsyncSession = Depends(get_db)
):
    """
    Find similar recipes using AI embeddings

    Uses semantic similarity to find recipes with similar:
    - Ingredients
    - Cooking methods
    - Flavor profiles
    - Cuisine types
    """
    # Get the recipe
    result = await db.execute(select(Recipe).where(Recipe.id == recipe_id))
    recipe = result.scalar_one_or_none()

    if not recipe:
        raise HTTPException(status_code=404, detail="Recipe not found")

    # Generate embedding for this recipe
    recipe_dict = {
        "name": recipe.name,
        "description": recipe.description or "",
        "cuisine": recipe.cuisine,
        "tags": recipe.tags,
        "dietary_tags": recipe.dietary_tags
    }

    query_embedding = await embedding_service.encode_recipe(recipe_dict)

    # Search for similar recipes
    similar = await vector_store.search_similar_recipes(
        query_embedding=query_embedding,
        limit=limit + 1  # +1 to exclude the query recipe itself
    )

    # Get recipe IDs (exclude the query recipe)
    similar_ids = [int(item["id"]) for item in similar if int(item["id"]) != recipe_id][:limit]

    if not similar_ids:
        return []

    # Fetch recipes from database
    result = await db.execute(
        select(Recipe).where(Recipe.id.in_(similar_ids))
    )
    recipes = result.scalars().all()

    return recipes


@router.get("/{recipe_id}", response_model=RecipeDetailResponse)
async def get_recipe(
    recipe_id: int,
    db: AsyncSession = Depends(get_db)
):
    """Get recipe details by ID"""
    result = await db.execute(select(Recipe).where(Recipe.id == recipe_id))
    recipe = result.scalar_one_or_none()

    if not recipe:
        raise HTTPException(status_code=404, detail="Recipe not found")

    # Increment view count
    recipe.views_count += 1
    await db.commit()

    return recipe


@router.get("/", response_model=List[RecipeResponse])
async def list_recipes(
    skip: int = Query(0, ge=0),
    limit: int = Query(20, le=100),
    cuisine: Optional[str] = None,
    sort_by: str = Query("rating", regex="^(rating|views|recent)$"),
    db: AsyncSession = Depends(get_db)
):
    """
    List recipes with pagination and filtering

    - **skip**: Number of recipes to skip
    - **limit**: Maximum number of recipes to return
    - **cuisine**: Filter by cuisine type
    - **sort_by**: Sort order (rating, views, recent)
    """
    stmt = select(Recipe)

    if cuisine:
        stmt = stmt.where(Recipe.cuisine == cuisine)

    # Sorting
    if sort_by == "rating":
        stmt = stmt.order_by(Recipe.rating_avg.desc())
    elif sort_by == "views":
        stmt = stmt.order_by(Recipe.views_count.desc())
    else:  # recent
        stmt = stmt.order_by(Recipe.created_at.desc())

    stmt = stmt.offset(skip).limit(limit)

    result = await db.execute(stmt)
    recipes = result.scalars().all()

    return recipes


@router.get("/by-cuisine/{cuisine}", response_model=List[RecipeResponse])
async def get_recipes_by_cuisine(
    cuisine: str,
    limit: int = Query(20, le=100),
    db: AsyncSession = Depends(get_db)
):
    """Get recipes by cuisine type"""
    result = await db.execute(
        select(Recipe)
        .where(Recipe.cuisine.ilike(f"%{cuisine}%"))
        .order_by(Recipe.rating_avg.desc())
        .limit(limit)
    )
    recipes = result.scalars().all()

    return recipes


@router.get("/by-country/{country}", response_model=List[RecipeResponse])
async def get_recipes_by_country(
    country: str,
    limit: int = Query(20, le=100),
    db: AsyncSession = Depends(get_db)
):
    """Get recipes by country of origin"""
    result = await db.execute(
        select(Recipe)
        .where(Recipe.country_origin.ilike(f"%{country}%"))
        .order_by(Recipe.rating_avg.desc())
        .limit(limit)
    )
    recipes = result.scalars().all()

    return recipes


@router.get("/cuisines/list")
async def list_cuisines(db: AsyncSession = Depends(get_db)):
    """Get list of all available cuisines"""
    result = await db.execute(
        select(Recipe.cuisine, func.count(Recipe.id))
        .group_by(Recipe.cuisine)
        .order_by(func.count(Recipe.id).desc())
    )
    cuisines = [{"cuisine": row[0], "count": row[1]} for row in result.all()]

    return cuisines


@router.delete("/{recipe_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_recipe(
    recipe_id: int,
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
    """Delete a recipe (requires authentication)"""
    user = await auth_service.get_current_user(db=db, token=token)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")

    result = await db.execute(select(Recipe).where(Recipe.id == recipe_id))
    recipe = result.scalar_one_or_none()

    if not recipe:
        raise HTTPException(status_code=404, detail="Recipe not found")

    await db.delete(recipe)
    await db.commit()

    return None
