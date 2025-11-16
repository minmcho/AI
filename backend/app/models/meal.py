from sqlalchemy import Column, Integer, String, Float, DateTime, JSON, ForeignKey, Date, Time
from sqlalchemy.orm import relationship
from datetime import datetime
from app.db.database import Base


class MealPlan(Base):
    __tablename__ = "meal_plans"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)

    name = Column(String)
    start_date = Column(Date, nullable=False)
    end_date = Column(Date, nullable=False)

    # Nutrition Goals
    daily_calorie_target = Column(Integer)
    daily_protein_target = Column(Float)
    daily_carbs_target = Column(Float)
    daily_fat_target = Column(Float)

    # AI Generation metadata
    generated_by_agent = Column(String)  # Which CrewAI agent created this
    generation_prompt = Column(String)

    # Status
    is_active = Column(String, default=True)

    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    user = relationship("User", back_populates="meal_plans")
    meals = relationship("Meal", back_populates="meal_plan", cascade="all, delete-orphan")


class Meal(Base):
    __tablename__ = "meals"

    id = Column(Integer, primary_key=True, index=True)
    meal_plan_id = Column(Integer, ForeignKey("meal_plans.id", ondelete="CASCADE"))
    recipe_id = Column(Integer, ForeignKey("recipes.id", ondelete="SET NULL"))

    # Meal Details
    meal_type = Column(String)  # breakfast, lunch, dinner, snack
    scheduled_date = Column(Date)
    scheduled_time = Column(Time)

    # Custom meal (if not using a recipe)
    custom_name = Column(String)
    custom_description = Column(String)

    # Actual consumption tracking
    consumed = Column(String, default=False)
    consumed_at = Column(DateTime)
    portion_modifier = Column(Float, default=1.0)  # 0.5 = half portion, 2.0 = double

    # User feedback
    rating = Column(Integer)  # 1-5 stars
    notes = Column(String)

    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow)

    # Relationships
    meal_plan = relationship("MealPlan", back_populates="meals")
    beverage_pairings = relationship("BeveragePairing", back_populates="meal", cascade="all, delete-orphan")


class BeveragePairing(Base):
    __tablename__ = "beverage_pairings"

    id = Column(Integer, primary_key=True, index=True)
    meal_id = Column(Integer, ForeignKey("meals.id", ondelete="CASCADE"), nullable=False)

    beverage_name = Column(String, nullable=False)
    beverage_type = Column(String)  # wine, beer, cocktail, juice, water, etc.
    description = Column(String)

    # Pairing reasoning (from AI)
    pairing_reason = Column(String)
    confidence_score = Column(Float)  # 0.0 to 1.0

    # Beverage details
    alcohol_content = Column(Float)
    calories = Column(Float)
    serving_size_ml = Column(Integer)

    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow)

    # Relationships
    meal = relationship("Meal", back_populates="beverage_pairings")
