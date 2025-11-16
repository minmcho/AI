from sqlalchemy import Column, Integer, String, Float, DateTime, JSON, ForeignKey, Text, Boolean
from sqlalchemy.orm import relationship
from datetime import datetime
from app.db.database import Base


class JournalEntry(Base):
    __tablename__ = "journal_entries"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    meal_id = Column(Integer, ForeignKey("meals.id", ondelete="SET NULL"))

    # Entry Details
    title = Column(String)
    content = Column(Text)
    meal_date = Column(DateTime, nullable=False)

    # Meal Photos
    photo_urls = Column(JSON, default=list)  # List of uploaded image URLs

    # Mood & Feelings
    mood = Column(String)  # happy, satisfied, energetic, etc.
    hunger_before = Column(Integer)  # 1-10 scale
    hunger_after = Column(Integer)  # 1-10 scale
    satisfaction = Column(Integer)  # 1-10 scale

    # Health Tracking
    weight_kg = Column(Float)
    energy_level = Column(Integer)  # 1-10
    digestion_notes = Column(String)

    # Tags
    tags = Column(JSON, default=list)

    # AI Analysis
    ai_insights = Column(JSON)  # AI-generated insights about patterns

    # Privacy
    is_private = Column(Boolean, default=True)

    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    user = relationship("User", back_populates="journal_entries")


class SocialPost(Base):
    __tablename__ = "social_posts"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    recipe_id = Column(Integer, ForeignKey("recipes.id", ondelete="SET NULL"))
    journal_entry_id = Column(Integer, ForeignKey("journal_entries.id", ondelete="SET NULL"))

    # Post Content
    caption = Column(Text)
    photo_urls = Column(JSON, default=list)
    hashtags = Column(JSON, default=list)

    # Engagement
    likes_count = Column(Integer, default=0)
    comments_count = Column(Integer, default=0)
    shares_count = Column(Integer, default=0)

    # Visibility
    is_public = Column(Boolean, default=True)

    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    user = relationship("User", back_populates="social_posts")
