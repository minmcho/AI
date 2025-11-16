from sqlalchemy import Column, Integer, String, Boolean, DateTime, JSON, Enum as SQLEnum, Float
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


class Sex(str, enum.Enum):
    MALE = "male"
    FEMALE = "female"
    OTHER = "other"


class HealthGoal(str, enum.Enum):
    WEIGHT_LOSS = "weight_loss"
    WEIGHT_GAIN = "weight_gain"
    MUSCLE_GAIN = "muscle_gain"
    MAINTAIN_WEIGHT = "maintain_weight"
    IMPROVE_FITNESS = "improve_fitness"
    MANAGE_DIABETES = "manage_diabetes"
    LOWER_CHOLESTEROL = "lower_cholesterol"
    HEART_HEALTH = "heart_health"
    DIGESTIVE_HEALTH = "digestive_health"
    GENERAL_WELLNESS = "general_wellness"


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
    weight_kg = Column(Float)  # Weight in kilograms
    height_cm = Column(Integer)  # Height in centimeters
    sex = Column(SQLEnum(Sex))  # Biological sex for calorie calculation
    target_calories = Column(Integer)
    target_protein_g = Column(Float)  # Daily protein target in grams
    target_carbs_g = Column(Float)  # Daily carbs target in grams
    target_fat_g = Column(Float)  # Daily fat target in grams
    activity_level = Column(SQLEnum(ActivityLevel))
    health_goals = Column(JSON, default=list)  # List of HealthGoal enums

    # Medical Information
    medical_conditions = Column(JSON, default=list)  # List of medical conditions
    medications = Column(JSON, default=list)  # Current medications

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
