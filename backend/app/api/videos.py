from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from pydantic import BaseModel
from typing import List, Optional

from app.db.database import get_db
from app.services.auth_service import auth_service
from app.services.video_service import video_service
from app.api.auth import oauth2_scheme

router = APIRouter(prefix="/videos", tags=["Video Recommendations"])


# Pydantic models
class VideoResponse(BaseModel):
    platform: str
    video_id: str
    title: str
    description: str
    url: str
    thumbnail_url: str
    channel_name: str
    channel_url: str
    view_count: int
    like_count: int
    duration: str
    relevance_score: Optional[float] = None


class TrendingVideosResponse(BaseModel):
    videos: List[VideoResponse]
    cuisine: Optional[str]
    total_count: int


@router.get("/recipe/{recipe_id}", response_model=List[VideoResponse])
async def get_recipe_videos(
    recipe_id: int,
    limit: int = Query(5, le=20),
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
    """
    Get cooking videos for a specific recipe

    Returns curated YouTube and social media videos showing how to make this recipe.

    Videos are ranked by:
    - Semantic similarity to recipe
    - View count and engagement
    - Video quality and duration
    """
    user = await auth_service.get_current_user(db=db, token=token)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")

    # Get recipe from database
    from app.models.recipe import Recipe
    from sqlalchemy import select

    result = await db.execute(select(Recipe).where(Recipe.id == recipe_id))
    recipe = result.scalar_one_or_none()

    if not recipe:
        raise HTTPException(status_code=404, detail="Recipe not found")

    # Get videos using video service
    videos = await video_service.find_recipe_videos(
        recipe_name=recipe.name,
        cuisine=recipe.cuisine,
        max_results=limit
    )

    return videos


@router.get("/search", response_model=List[VideoResponse])
async def search_cooking_videos(
    query: str = Query(..., min_length=2),
    limit: int = Query(10, le=20),
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
    """
    Search for cooking videos by keyword

    Search YouTube and social media for cooking videos matching your query.

    Examples:
    - "pasta carbonara recipe"
    - "how to make sushi"
    - "vegetarian curry"
    """
    user = await auth_service.get_current_user(db=db, token=token)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")

    videos = await video_service.search_youtube_videos(
        query=query,
        max_results=limit
    )

    return videos


@router.get("/trending", response_model=TrendingVideosResponse)
async def get_trending_videos(
    cuisine: Optional[str] = None,
    limit: int = Query(10, le=20),
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
    """
    Get trending cooking videos

    Discover popular cooking videos from the last 30 days.

    Filter by cuisine type or get all trending cooking content.
    """
    user = await auth_service.get_current_user(db=db, token=token)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")

    videos = await video_service.get_trending_cooking_videos(
        cuisine=cuisine,
        limit=limit
    )

    return TrendingVideosResponse(
        videos=videos,
        cuisine=cuisine,
        total_count=len(videos)
    )


@router.get("/technique/{technique}", response_model=List[VideoResponse])
async def get_technique_videos(
    technique: str,
    limit: int = Query(3, le=10),
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
    """
    Get tutorial videos for cooking techniques

    Learn cooking techniques from video tutorials.

    Examples:
    - "knife skills"
    - "sautéing"
    - "bread kneading"
    - "tempering chocolate"

    Returns educational, step-by-step tutorial videos.
    """
    user = await auth_service.get_current_user(db=db, token=token)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")

    videos = await video_service.get_cooking_technique_videos(
        technique=technique,
        max_results=limit
    )

    return videos


@router.get("/multi-platform/{recipe_name}")
async def get_multi_platform_videos(
    recipe_name: str,
    max_per_platform: int = Query(3, le=5),
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
    """
    Get videos from multiple platforms

    Search YouTube, TikTok, and Instagram for recipe videos.

    Returns aggregated results from all platforms with relevance scoring.
    """
    user = await auth_service.get_current_user(db=db, token=token)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")

    results = await video_service.aggregate_multi_platform_videos(
        recipe_name=recipe_name,
        max_per_platform=max_per_platform
    )

    return results
