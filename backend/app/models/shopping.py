from sqlalchemy import Column, Integer, String, Float, DateTime, JSON, ForeignKey, Boolean
from sqlalchemy.orm import relationship
from datetime import datetime
from app.db.database import Base


class ShoppingList(Base):
    __tablename__ = "shopping_lists"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    meal_plan_id = Column(Integer, ForeignKey("meal_plans.id", ondelete="SET NULL"))

    name = Column(String, nullable=False)

    # Store preferences
    preferred_stores = Column(JSON, default=list)
    budget_limit = Column(Float)

    # MCP Integration metadata
    mcp_session_id = Column(String)  # Model Context Protocol session
    last_price_check = Column(DateTime)

    # Status
    is_completed = Column(Boolean, default=False)
    completed_at = Column(DateTime)

    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    user = relationship("User", back_populates="shopping_lists")
    items = relationship("ShoppingListItem", back_populates="shopping_list", cascade="all, delete-orphan")


class ShoppingListItem(Base):
    __tablename__ = "shopping_list_items"

    id = Column(Integer, primary_key=True, index=True)
    shopping_list_id = Column(Integer, ForeignKey("shopping_lists.id", ondelete="CASCADE"), nullable=False)
    ingredient_id = Column(Integer, ForeignKey("ingredients.id", ondelete="SET NULL"))

    # Item Details
    name = Column(String, nullable=False)
    quantity = Column(Float, nullable=False)
    unit = Column(String, nullable=False)
    category = Column(String)  # produce, dairy, meat, etc.

    # Price tracking (from MCP)
    estimated_price = Column(Float)
    actual_price = Column(Float)
    store_name = Column(String)
    product_url = Column(String)

    # AI Suggestions
    substitution_suggestions = Column(JSON, default=list)

    # Status
    is_purchased = Column(Boolean, default=False)
    purchased_at = Column(DateTime)

    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow)

    # Relationships
    shopping_list = relationship("ShoppingList", back_populates="items")


class RecipeVideo(Base):
    __tablename__ = "recipe_videos"

    id = Column(Integer, primary_key=True, index=True)
    recipe_id = Column(Integer, ForeignKey("recipes.id", ondelete="CASCADE"))

    # Video Details
    title = Column(String, nullable=False)
    description = Column(Text)
    platform = Column(String)  # youtube, tiktok, instagram
    video_id = Column(String, nullable=False)
    url = Column(String, nullable=False)
    thumbnail_url = Column(String)

    # Creator
    channel_name = Column(String)
    channel_url = Column(String)

    # Metrics
    view_count = Column(Integer)
    like_count = Column(Integer)
    duration_seconds = Column(Integer)

    # Relevance scoring (from AI)
    relevance_score = Column(Float)  # 0.0 to 1.0
    embedding_similarity = Column(Float)

    # Timestamps
    published_at = Column(DateTime)
    fetched_at = Column(DateTime, default=datetime.utcnow)
