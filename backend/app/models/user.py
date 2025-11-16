from sqlalchemy import Column, Integer, String, Boolean, DateTime, JSON, Enum as SQLEnum
from sqlalchemy.orm import relationship
from datetime import datetime
import enum
from app.db.database import Base


class DietaryRestriction(str, enum.Enum):
    VEGETARIAN = "vegetarian"
    VEGAN = "vegan"
    GLUTEN_FREE = "gluten_free"
    DAIRY_FREE = "dairy_free"
    KETO = "keto"
    PALEO = "paleo"
    HALAL = "halal"
    KOSHER = "kosher"
    LOW_CARB = "low_carb"
    LOW_FAT = "low_fat"


class ActivityLevel(str, enum.Enum):
    SEDENTARY = "sedentary"
    LIGHT = "light"
    MODERATE = "moderate"
    ACTIVE = "active"
    VERY_ACTIVE = "very_active"


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    username = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)

    # Profile
    full_name = Column(String)
    avatar_url = Column(String)
    bio = Column(String)

    # Preferences
    dietary_restrictions = Column(JSON, default=list)  # List of DietaryRestriction
    allergies = Column(JSON, default=list)  # List of allergens
    cuisine_preferences = Column(JSON, default=list)  # Preferred cuisines
    disliked_ingredients = Column(JSON, default=list)

    # Health & Nutrition Goals
    age = Column(Integer)
    weight_kg = Column(Integer)
    height_cm = Column(Integer)
    target_calories = Column(Integer)
    activity_level = Column(SQLEnum(ActivityLevel))
    health_goals = Column(JSON, default=list)  # weight_loss, muscle_gain, etc.

    # Settings
    is_active = Column(Boolean, default=True)
    is_premium = Column(Boolean, default=False)
    language = Column(String, default="en")
    timezone = Column(String, default="UTC")

    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    meal_plans = relationship("MealPlan", back_populates="user", cascade="all, delete-orphan")
    journal_entries = relationship("JournalEntry", back_populates="user", cascade="all, delete-orphan")
    shopping_lists = relationship("ShoppingList", back_populates="user", cascade="all, delete-orphan")
    social_posts = relationship("SocialPost", back_populates="user", cascade="all, delete-orphan")
