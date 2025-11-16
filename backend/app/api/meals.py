from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from pydantic import BaseModel
from typing import List, Optional
from datetime import date, datetime

from app.db.database import get_db
from app.models.meal import MealPlan, Meal
from app.models.journal import JournalEntry, SocialPost
from app.services.auth_service import auth_service
from app.api.auth import oauth2_scheme

router = APIRouter(prefix="/meals", tags=["Meals & Journaling"])


# Pydantic models
class MealPlanCreate(BaseModel):
    name: str
    start_date: date
    end_date: date
    daily_calorie_target: Optional[int] = None


class MealResponse(BaseModel):
    id: int
    meal_type: str
    scheduled_date: date
    consumed: bool
    rating: Optional[int]

    class Config:
        from_attributes = True


class MealPlanResponse(BaseModel):
    id: int
    name: str
    start_date: date
    end_date: date
    daily_calorie_target: int
    is_active: bool
    created_at: datetime
    meals: List[MealResponse]

    class Config:
        from_attributes = True


class JournalEntryCreate(BaseModel):
    title: str
    content: str
    meal_date: datetime
    mood: Optional[str] = None
    satisfaction: Optional[int] = None
    tags: List[str] = []
    photo_urls: List[str] = []


class JournalEntryResponse(BaseModel):
    id: int
    title: str
    content: str
    meal_date: datetime
    mood: Optional[str]
    satisfaction: Optional[int]
    tags: List[str]
    photo_urls: List[str]
    created_at: datetime

    class Config:
        from_attributes = True


class SocialPostCreate(BaseModel):
    caption: str
    recipe_id: Optional[int] = None
    photo_urls: List[str]
    hashtags: List[str] = []
    is_public: bool = True


class SocialPostResponse(BaseModel):
    id: int
    caption: str
    photo_urls: List[str]
    hashtags: List[str]
    likes_count: int
    comments_count: int
    is_public: bool
    created_at: datetime

    class Config:
        from_attributes = True


# Meal Plan endpoints
@router.post("/plans", response_model=MealPlanResponse, status_code=status.HTTP_201_CREATED)
async def create_meal_plan(
    plan_data: MealPlanCreate,
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
    """
    Create a meal plan

    Create a new meal plan for tracking daily meals.

    For AI-generated meal plans, use `/profile/generate-meal-plan` endpoint.
    """
    user = await auth_service.get_current_user(db=db, token=token)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")

    meal_plan = MealPlan(
        user_id=user.id,
        name=plan_data.name,
        start_date=plan_data.start_date,
        end_date=plan_data.end_date,
        daily_calorie_target=plan_data.daily_calorie_target or user.target_calories,
        is_active=True
    )

    db.add(meal_plan)
    await db.commit()
    await db.refresh(meal_plan)

    return meal_plan


@router.get("/plans", response_model=List[MealPlanResponse])
async def get_meal_plans(
    active_only: bool = False,
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
    """Get all meal plans for current user"""
    user = await auth_service.get_current_user(db=db, token=token)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")

    stmt = select(MealPlan).where(MealPlan.user_id == user.id)

    if active_only:
        stmt = stmt.where(MealPlan.is_active == True)

    stmt = stmt.order_by(MealPlan.created_at.desc())

    result = await db.execute(stmt)
    meal_plans = result.scalars().all()

    return meal_plans


@router.get("/plans/{plan_id}", response_model=MealPlanResponse)
async def get_meal_plan(
    plan_id: int,
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
    """Get meal plan by ID"""
    user = await auth_service.get_current_user(db=db, token=token)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")

    result = await db.execute(
        select(MealPlan).where(
            MealPlan.id == plan_id,
            MealPlan.user_id == user.id
        )
    )
    meal_plan = result.scalar_one_or_none()

    if not meal_plan:
        raise HTTPException(status_code=404, detail="Meal plan not found")

    return meal_plan


@router.patch("/plans/{plan_id}/meals/{meal_id}/consume")
async def mark_meal_consumed(
    plan_id: int,
    meal_id: int,
    rating: Optional[int] = None,
    notes: Optional[str] = None,
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
    """
    Mark meal as consumed

    Track meal consumption with optional rating (1-5) and notes.
    """
    user = await auth_service.get_current_user(db=db, token=token)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")

    # Verify plan ownership
    result = await db.execute(
        select(MealPlan).where(
            MealPlan.id == plan_id,
            MealPlan.user_id == user.id
        )
    )
    meal_plan = result.scalar_one_or_none()

    if not meal_plan:
        raise HTTPException(status_code=404, detail="Meal plan not found")

    # Get meal
    result = await db.execute(
        select(Meal).where(
            Meal.id == meal_id,
            Meal.meal_plan_id == plan_id
        )
    )
    meal = result.scalar_one_or_none()

    if not meal:
        raise HTTPException(status_code=404, detail="Meal not found")

    # Update meal
    meal.consumed = True
    meal.consumed_at = datetime.utcnow()
    if rating:
        meal.rating = rating
    if notes:
        meal.notes = notes

    await db.commit()

    return {"message": "Meal marked as consumed"}


# Journal endpoints
@router.post("/journal", response_model=JournalEntryResponse, status_code=status.HTTP_201_CREATED)
async def create_journal_entry(
    entry_data: JournalEntryCreate,
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
    """
    Create meal journal entry

    Journal your meals with:
    - Photos
    - Mood tracking
    - Satisfaction ratings
    - Personal notes
    - Tags for organization

    This helps track patterns and improve meal planning.
    """
    user = await auth_service.get_current_user(db=db, token=token)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")

    entry = JournalEntry(
        user_id=user.id,
        title=entry_data.title,
        content=entry_data.content,
        meal_date=entry_data.meal_date,
        mood=entry_data.mood,
        satisfaction=entry_data.satisfaction,
        tags=entry_data.tags,
        photo_urls=entry_data.photo_urls,
        is_private=True
    )

    db.add(entry)
    await db.commit()
    await db.refresh(entry)

    return entry


@router.get("/journal", response_model=List[JournalEntryResponse])
async def get_journal_entries(
    start_date: Optional[date] = None,
    end_date: Optional[date] = None,
    limit: int = Query(50, le=200),
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
    """
    Get journal entries

    Retrieve your meal journal entries with optional date filtering.
    """
    user = await auth_service.get_current_user(db=db, token=token)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")

    stmt = select(JournalEntry).where(JournalEntry.user_id == user.id)

    if start_date:
        stmt = stmt.where(JournalEntry.meal_date >= start_date)
    if end_date:
        stmt = stmt.where(JournalEntry.meal_date <= end_date)

    stmt = stmt.order_by(JournalEntry.meal_date.desc()).limit(limit)

    result = await db.execute(stmt)
    entries = result.scalars().all()

    return entries


@router.get("/journal/{entry_id}", response_model=JournalEntryResponse)
async def get_journal_entry(
    entry_id: int,
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
    """Get journal entry by ID"""
    user = await auth_service.get_current_user(db=db, token=token)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")

    result = await db.execute(
        select(JournalEntry).where(
            JournalEntry.id == entry_id,
            JournalEntry.user_id == user.id
        )
    )
    entry = result.scalar_one_or_none()

    if not entry:
        raise HTTPException(status_code=404, detail="Journal entry not found")

    return entry


@router.delete("/journal/{entry_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_journal_entry(
    entry_id: int,
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
    """Delete journal entry"""
    user = await auth_service.get_current_user(db=db, token=token)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")

    result = await db.execute(
        select(JournalEntry).where(
            JournalEntry.id == entry_id,
            JournalEntry.user_id == user.id
        )
    )
    entry = result.scalar_one_or_none()

    if not entry:
        raise HTTPException(status_code=404, detail="Journal entry not found")

    await db.delete(entry)
    await db.commit()

    return None


# Social endpoints
@router.post("/social", response_model=SocialPostResponse, status_code=status.HTTP_201_CREATED)
async def create_social_post(
    post_data: SocialPostCreate,
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
    """
    Share to social feed

    Share your meals with the community:
    - Photos of your creations
    - Recipe links
    - Captions and hashtags
    - Public or private posts

    Public posts appear in the community feed.
    """
    user = await auth_service.get_current_user(db=db, token=token)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")

    post = SocialPost(
        user_id=user.id,
        recipe_id=post_data.recipe_id,
        caption=post_data.caption,
        photo_urls=post_data.photo_urls,
        hashtags=post_data.hashtags,
        is_public=post_data.is_public
    )

    db.add(post)
    await db.commit()
    await db.refresh(post)

    return post


@router.get("/social/feed", response_model=List[SocialPostResponse])
async def get_social_feed(
    limit: int = Query(20, le=100),
    offset: int = Query(0, ge=0),
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
    """
    Get community social feed

    Discover meals shared by the community.
    Only public posts are shown.
    """
    user = await auth_service.get_current_user(db=db, token=token)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")

    result = await db.execute(
        select(SocialPost)
        .where(SocialPost.is_public == True)
        .order_by(SocialPost.created_at.desc())
        .offset(offset)
        .limit(limit)
    )
    posts = result.scalars().all()

    return posts


@router.get("/social/my-posts", response_model=List[SocialPostResponse])
async def get_my_posts(
    limit: int = Query(20, le=100),
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
    """Get all posts from current user"""
    user = await auth_service.get_current_user(db=db, token=token)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")

    result = await db.execute(
        select(SocialPost)
        .where(SocialPost.user_id == user.id)
        .order_by(SocialPost.created_at.desc())
        .limit(limit)
    )
    posts = result.scalars().all()

    return posts


@router.post("/social/{post_id}/like")
async def like_post(
    post_id: int,
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
    """Like a social post"""
    user = await auth_service.get_current_user(db=db, token=token)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")

    result = await db.execute(select(SocialPost).where(SocialPost.id == post_id))
    post = result.scalar_one_or_none()

    if not post:
        raise HTTPException(status_code=404, detail="Post not found")

    post.likes_count += 1
    await db.commit()

    return {"message": "Post liked", "likes_count": post.likes_count}


@router.delete("/social/{post_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_social_post(
    post_id: int,
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
    """Delete social post (own posts only)"""
    user = await auth_service.get_current_user(db=db, token=token)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")

    result = await db.execute(
        select(SocialPost).where(
            SocialPost.id == post_id,
            SocialPost.user_id == user.id
        )
    )
    post = result.scalar_one_or_none()

    if not post:
        raise HTTPException(status_code=404, detail="Post not found")

    await db.delete(post)
    await db.commit()

    return None
