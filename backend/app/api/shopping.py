from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime

from app.db.database import get_db
from app.models.shopping import ShoppingList, ShoppingListItem
from app.models.meal import MealPlan
from app.services.auth_service import auth_service
from app.services.mcp_shopping import mcp_shopping
from app.api.auth import oauth2_scheme

router = APIRouter(prefix="/shopping", tags=["Shopping Lists"])


# Pydantic models
class ShoppingItemCreate(BaseModel):
    name: str
    quantity: float
    unit: str
    category: Optional[str] = "other"


class ShoppingListCreate(BaseModel):
    name: str
    meal_plan_id: Optional[int] = None
    items: List[ShoppingItemCreate] = []
    preferred_stores: List[str] = []
    budget_limit: Optional[float] = None


class ShoppingItemResponse(BaseModel):
    id: int
    name: str
    quantity: float
    unit: str
    category: str
    estimated_price: Optional[float]
    actual_price: Optional[float]
    is_purchased: bool
    substitution_suggestions: List[dict]

    class Config:
        from_attributes = True


class ShoppingListResponse(BaseModel):
    id: int
    name: str
    is_completed: bool
    created_at: datetime
    items: List[ShoppingItemResponse]
    total_estimated_cost: float

    class Config:
        from_attributes = True


@router.post("/", response_model=ShoppingListResponse, status_code=status.HTTP_201_CREATED)
async def create_shopping_list(
    list_data: ShoppingListCreate,
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
    """
    Create a shopping list

    Create a shopping list manually or from a meal plan.

    If `meal_plan_id` is provided, items will be generated from the meal plan's recipes.
    """
    user = await auth_service.get_current_user(db=db, token=token)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")

    # Create shopping list
    shopping_list = ShoppingList(
        user_id=user.id,
        name=list_data.name,
        meal_plan_id=list_data.meal_plan_id,
        preferred_stores=list_data.preferred_stores,
        budget_limit=list_data.budget_limit
    )

    db.add(shopping_list)
    await db.flush()

    # Add items
    total_cost = 0.0
    for item_data in list_data.items:
        # Estimate price using MCP
        estimated_price = await mcp_shopping._estimate_price(
            item_data.name,
            item_data.quantity,
            item_data.unit
        )

        # Find substitutions
        substitutions = await mcp_shopping._find_substitutions(item_data.name)

        item = ShoppingListItem(
            shopping_list_id=shopping_list.id,
            name=item_data.name,
            quantity=item_data.quantity,
            unit=item_data.unit,
            category=item_data.category,
            estimated_price=estimated_price,
            substitution_suggestions=substitutions
        )
        db.add(item)
        total_cost += estimated_price

    await db.commit()
    await db.refresh(shopping_list)

    # Return response
    return ShoppingListResponse(
        id=shopping_list.id,
        name=shopping_list.name,
        is_completed=shopping_list.is_completed,
        created_at=shopping_list.created_at,
        items=[ShoppingItemResponse.from_orm(item) for item in shopping_list.items],
        total_estimated_cost=total_cost
    )


@router.post("/from-meal-plan/{meal_plan_id}", response_model=ShoppingListResponse)
async def create_shopping_list_from_meal_plan(
    meal_plan_id: int,
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
    """
    Generate shopping list from meal plan using AI

    Uses the MCP shopping assistant to:
    - Aggregate ingredients from all meals
    - Estimate prices
    - Suggest substitutions
    - Optimize by store
    - Find savings opportunities

    Returns a complete shopping list with price estimates.
    """
    user = await auth_service.get_current_user(db=db, token=token)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")

    # Get meal plan
    result = await db.execute(
        select(MealPlan).where(
            MealPlan.id == meal_plan_id,
            MealPlan.user_id == user.id
        )
    )
    meal_plan = result.scalar_one_or_none()

    if not meal_plan:
        raise HTTPException(status_code=404, detail="Meal plan not found")

    # Initialize MCP session
    session_id = await mcp_shopping.initialize_session({
        "preferred_stores": user.cuisine_preferences or [],  # Could be store preferences
        "budget": None
    })

    # TODO: Get recipes from meal plan
    # For now, use placeholder
    recipes = []  # Would fetch actual recipes from meal plan meals

    # Generate shopping list
    result = await mcp_shopping.generate_shopping_list(
        meal_plan_id=meal_plan_id,
        recipes=recipes
    )

    # Create database records
    shopping_list = ShoppingList(
        user_id=user.id,
        meal_plan_id=meal_plan_id,
        name=f"Shopping List for {meal_plan.name}",
        mcp_session_id=session_id,
        last_price_check=datetime.utcnow()
    )

    db.add(shopping_list)
    await db.flush()

    # Add items
    for item_data in result["items"]:
        item = ShoppingListItem(
            shopping_list_id=shopping_list.id,
            name=item_data["name"],
            quantity=item_data["quantity"],
            unit=item_data["unit"],
            category=item_data["category"],
            estimated_price=item_data["estimated_price"],
            substitution_suggestions=item_data.get("substitutions", [])
        )
        db.add(item)

    await db.commit()
    await db.refresh(shopping_list)

    return ShoppingListResponse(
        id=shopping_list.id,
        name=shopping_list.name,
        is_completed=shopping_list.is_completed,
        created_at=shopping_list.created_at,
        items=[ShoppingItemResponse.from_orm(item) for item in shopping_list.items],
        total_estimated_cost=result["total_estimated_cost"]
    )


@router.get("/", response_model=List[ShoppingListResponse])
async def get_shopping_lists(
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
    """Get all shopping lists for current user"""
    user = await auth_service.get_current_user(db=db, token=token)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")

    result = await db.execute(
        select(ShoppingList)
        .where(ShoppingList.user_id == user.id)
        .order_by(ShoppingList.created_at.desc())
    )
    lists = result.scalars().all()

    response_lists = []
    for shopping_list in lists:
        total_cost = sum(item.estimated_price or 0 for item in shopping_list.items)
        response_lists.append(
            ShoppingListResponse(
                id=shopping_list.id,
                name=shopping_list.name,
                is_completed=shopping_list.is_completed,
                created_at=shopping_list.created_at,
                items=[ShoppingItemResponse.from_orm(item) for item in shopping_list.items],
                total_estimated_cost=total_cost
            )
        )

    return response_lists


@router.get("/{list_id}", response_model=ShoppingListResponse)
async def get_shopping_list(
    list_id: int,
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
    """Get shopping list by ID"""
    user = await auth_service.get_current_user(db=db, token=token)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")

    result = await db.execute(
        select(ShoppingList).where(
            ShoppingList.id == list_id,
            ShoppingList.user_id == user.id
        )
    )
    shopping_list = result.scalar_one_or_none()

    if not shopping_list:
        raise HTTPException(status_code=404, detail="Shopping list not found")

    total_cost = sum(item.estimated_price or 0 for item in shopping_list.items)

    return ShoppingListResponse(
        id=shopping_list.id,
        name=shopping_list.name,
        is_completed=shopping_list.is_completed,
        created_at=shopping_list.created_at,
        items=[ShoppingItemResponse.from_orm(item) for item in shopping_list.items],
        total_estimated_cost=total_cost
    )


@router.patch("/{list_id}/items/{item_id}/purchased")
async def mark_item_purchased(
    list_id: int,
    item_id: int,
    purchased: bool = True,
    actual_price: Optional[float] = None,
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
    """Mark shopping list item as purchased"""
    user = await auth_service.get_current_user(db=db, token=token)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")

    # Verify list ownership
    result = await db.execute(
        select(ShoppingList).where(
            ShoppingList.id == list_id,
            ShoppingList.user_id == user.id
        )
    )
    shopping_list = result.scalar_one_or_none()

    if not shopping_list:
        raise HTTPException(status_code=404, detail="Shopping list not found")

    # Get item
    result = await db.execute(
        select(ShoppingListItem).where(
            ShoppingListItem.id == item_id,
            ShoppingListItem.shopping_list_id == list_id
        )
    )
    item = result.scalar_one_or_none()

    if not item:
        raise HTTPException(status_code=404, detail="Item not found")

    # Update item
    item.is_purchased = purchased
    if actual_price is not None:
        item.actual_price = actual_price
    if purchased:
        item.purchased_at = datetime.utcnow()

    await db.commit()

    return {"message": "Item updated successfully"}


@router.patch("/{list_id}/complete")
async def complete_shopping_list(
    list_id: int,
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
    """Mark shopping list as completed"""
    user = await auth_service.get_current_user(db=db, token=token)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")

    result = await db.execute(
        select(ShoppingList).where(
            ShoppingList.id == list_id,
            ShoppingList.user_id == user.id
        )
    )
    shopping_list = result.scalar_one_or_none()

    if not shopping_list:
        raise HTTPException(status_code=404, detail="Shopping list not found")

    shopping_list.is_completed = True
    shopping_list.completed_at = datetime.utcnow()

    await db.commit()

    return {"message": "Shopping list completed"}


@router.delete("/{list_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_shopping_list(
    list_id: int,
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
    """Delete shopping list"""
    user = await auth_service.get_current_user(db=db, token=token)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")

    result = await db.execute(
        select(ShoppingList).where(
            ShoppingList.id == list_id,
            ShoppingList.user_id == user.id
        )
    )
    shopping_list = result.scalar_one_or_none()

    if not shopping_list:
        raise HTTPException(status_code=404, detail="Shopping list not found")

    await db.delete(shopping_list)
    await db.commit()

    return None
