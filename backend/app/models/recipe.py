from sqlalchemy import Column, Integer, String, Float, Boolean, DateTime, JSON, Text, ForeignKey, Table
from sqlalchemy.orm import relationship
from datetime import datetime
from app.db.database import Base


# Association table for recipe ingredients
recipe_ingredients = Table(
    'recipe_ingredients',
    Base.metadata,
    Column('recipe_id', Integer, ForeignKey('recipes.id', ondelete='CASCADE')),
    Column('ingredient_id', Integer, ForeignKey('ingredients.id', ondelete='CASCADE')),
    Column('quantity', Float),
    Column('unit', String),
)


class Recipe(Base):
    __tablename__ = "recipes"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False, index=True)
    description = Column(Text)
    cuisine = Column(String, index=True)  # Italian, Chinese, Mexican, etc.
    country_origin = Column(String, index=True)

    # Recipe Details
    prep_time_minutes = Column(Integer)
    cook_time_minutes = Column(Integer)
    total_time_minutes = Column(Integer)
    servings = Column(Integer, default=4)
    difficulty = Column(String)  # easy, medium, hard

    # Instructions
    instructions = Column(JSON)  # List of step objects
    tips = Column(JSON)  # Cooking tips

    # Media
    image_url = Column(String)
    video_url = Column(String)
    youtube_video_id = Column(String)

    # Nutrition (per serving)
    calories = Column(Float)
    protein_g = Column(Float)
    carbs_g = Column(Float)
    fat_g = Column(Float)
    fiber_g = Column(Float)
    sugar_g = Column(Float)
    sodium_mg = Column(Float)

    # Metadata
    is_verified = Column(Boolean, default=False)
    views_count = Column(Integer, default=0)
    likes_count = Column(Integer, default=0)
    rating_avg = Column(Float, default=0.0)
    rating_count = Column(Integer, default=0)

    # Tags
    tags = Column(JSON, default=list)  # breakfast, lunch, dinner, snack, dessert
    dietary_tags = Column(JSON, default=list)  # vegan, gluten-free, etc.

    # AI Embeddings (stored in ChromaDB, referenced here)
    embedding_id = Column(String, unique=True)

    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    ingredients = relationship(
        "Ingredient",
        secondary=recipe_ingredients,
        back_populates="recipes"
    )


class Ingredient(Base):
    __tablename__ = "ingredients"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False, unique=True, index=True)
    category = Column(String, index=True)  # vegetable, protein, dairy, etc.

    # Nutrition per 100g
    calories_per_100g = Column(Float)
    protein_per_100g = Column(Float)
    carbs_per_100g = Column(Float)
    fat_per_100g = Column(Float)
    fiber_per_100g = Column(Float)

    # Metadata
    allergens = Column(JSON, default=list)
    is_common = Column(Boolean, default=False)
    average_price_usd = Column(Float)

    # AI Embeddings
    embedding_id = Column(String, unique=True)

    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow)

    # Relationships
    recipes = relationship(
        "Recipe",
        secondary=recipe_ingredients,
        back_populates="ingredients"
    )
