"""
SQLAlchemy async ORM models for VitalPath AI.
Schema aligns with Supabase PostgreSQL + SwiftData local store.
"""
from __future__ import annotations

import uuid
from datetime import datetime
from enum import Enum as PyEnum

from sqlalchemy import (
    Boolean,
    Column,
    DateTime,
    Enum,
    Float,
    ForeignKey,
    Integer,
    String,
    Text,
    JSON,
    UniqueConstraint,
    func,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import DeclarativeBase, relationship

from app.config import get_settings

settings = get_settings()


# ─────────────────────────── Base ───────────────────────────

class Base(DeclarativeBase):
    pass


# ─────────────────────────── Enums ──────────────────────────

class SessionType(str, PyEnum):
    CHAT = "chat"
    VIDEO_ANALYSIS = "video_analysis"
    HABIT_LOG = "habit_log"
    MINDFULNESS = "mindfulness"


class GoalCategory(str, PyEnum):
    NUTRITION = "nutrition"
    EXERCISE = "exercise"
    SLEEP = "sleep"
    MINDFULNESS = "mindfulness"
    HYDRATION = "hydration"
    STRESS = "stress"


class SafetyEvent(str, PyEnum):
    CRISIS_TRIGGERED = "crisis_triggered"
    MEDICAL_CLAIM_BLOCKED = "medical_claim_blocked"
    PII_REDACTED = "pii_redacted"
    OUTPUT_REGENERATED = "output_regenerated"


# ─────────────────────────── Models ─────────────────────────

class WellnessProfile(Base):
    """Core user wellness profile. Synced from Supabase Auth."""
    __tablename__ = "wellness_profiles"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    supabase_uid = Column(String(255), unique=True, nullable=False, index=True)
    display_name = Column(String(100))
    avatar_url = Column(Text)
    preferred_language = Column(String(10), default="en")

    # Wellness preferences (stored as JSON for flexibility)
    dietary_preferences = Column(JSON, default=list)   # ["vegetarian", "gluten-free"]
    health_notes = Column(JSON, default=list)           # ["knee pain", "insomnia"]  — wellness only
    wellness_goals = Column(JSON, default=list)         # ["lose weight", "sleep better"]
    preferred_session_time = Column(String(20))        # "morning" | "evening"

    # Streak & gamification
    current_streak = Column(Integer, default=0)
    longest_streak = Column(Integer, default=0)
    freeze_streak_used_this_month = Column(Boolean, default=False)
    total_sessions = Column(Integer, default=0)
    wellness_score = Column(Float, default=0.0)

    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    last_active_at = Column(DateTime(timezone=True))

    # Relationships
    sessions = relationship("WellnessSession", back_populates="profile", cascade="all, delete-orphan")
    goals = relationship("WellnessGoal", back_populates="profile", cascade="all, delete-orphan")
    wearable = relationship("WearableConnection", back_populates="profile", uselist=False, cascade="all, delete-orphan")
    safety_logs = relationship("SafetyLog", back_populates="profile", cascade="all, delete-orphan")


class WellnessSession(Base):
    """A single coaching session (chat, video, habit log, mindfulness)."""
    __tablename__ = "wellness_sessions"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    profile_id = Column(UUID(as_uuid=True), ForeignKey("wellness_profiles.id"), nullable=False, index=True)

    session_type = Column(Enum(SessionType), nullable=False)
    title = Column(String(200))
    summary = Column(Text)

    # Chat messages (JSON array for lightweight storage)
    messages = Column(JSON, default=list)
    # [{"role": "user"|"assistant", "content": "...", "timestamp": "..."}]

    # AI metadata
    ai_model_used = Column(String(100))
    intent_detected = Column(String(50))
    language_detected = Column(String(10), default="en")

    # Video analysis (nullable — only for video sessions)
    video_url = Column(Text)
    video_analysis_result = Column(JSON)
    # {"nutrition_estimate": "...", "safety_flag": false, "feedback": "..."}

    # Wellness metrics captured in this session
    mood_before = Column(Integer)   # 1–10 scale
    mood_after = Column(Integer)
    energy_level = Column(Integer)
    stress_level = Column(Integer)

    # Flags
    flagged_for_review = Column(Boolean, default=False)
    safety_intercepted = Column(Boolean, default=False)

    duration_seconds = Column(Integer, default=0)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    completed_at = Column(DateTime(timezone=True))

    profile = relationship("WellnessProfile", back_populates="sessions")


class WellnessGoal(Base):
    """User-defined or AI-suggested wellness goals."""
    __tablename__ = "wellness_goals"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    profile_id = Column(UUID(as_uuid=True), ForeignKey("wellness_profiles.id"), nullable=False, index=True)

    category = Column(Enum(GoalCategory), nullable=False)
    title = Column(String(200), nullable=False)
    description = Column(Text)
    target_value = Column(Float)          # e.g., 10000 (steps), 8 (hours sleep)
    current_value = Column(Float, default=0.0)
    unit = Column(String(50))             # "steps", "hours", "sessions"
    ai_suggested = Column(Boolean, default=False)
    is_active = Column(Boolean, default=True)
    target_date = Column(DateTime(timezone=True))
    completed_at = Column(DateTime(timezone=True))
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    profile = relationship("WellnessProfile", back_populates="goals")


class WearableConnection(Base):
    """Apple HealthKit / wearable data sync."""
    __tablename__ = "wearable_connections"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    profile_id = Column(UUID(as_uuid=True), ForeignKey("wellness_profiles.id"), unique=True, nullable=False)

    platform = Column(String(50), default="apple_health")
    is_connected = Column(Boolean, default=False)

    # Latest snapshot from HealthKit
    daily_steps = Column(Integer, default=0)
    resting_heart_rate = Column(Float)
    sleep_hours = Column(Float)
    active_calories = Column(Integer, default=0)
    hrv_ms = Column(Float)  # Heart Rate Variability

    last_synced_at = Column(DateTime(timezone=True))
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    profile = relationship("WellnessProfile", back_populates="wearable")


class SafetyLog(Base):
    """Audit trail for safety events. PHI is never stored in plain text."""
    __tablename__ = "safety_logs"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    profile_id = Column(UUID(as_uuid=True), ForeignKey("wellness_profiles.id"), nullable=False, index=True)

    event_type = Column(Enum(SafetyEvent), nullable=False)
    # Content hash only — never plain text for crisis events
    content_hash = Column(String(64))
    session_id = Column(UUID(as_uuid=True), ForeignKey("wellness_sessions.id"))
    language = Column(String(10), default="en")
    resolved = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    profile = relationship("WellnessProfile", back_populates="safety_logs")


class WellnessTip(Base):
    """Pre-cached wellness tips served when AI is unavailable (circuit open)."""
    __tablename__ = "wellness_tips"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    tags = Column(JSON, default=list)       # ["stress", "sleep", "nutrition"]
    language = Column(String(10), default="en")
    content = Column(Text, nullable=False)
    source = Column(String(200))
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())


# ─────────────────────────── Engine ─────────────────────────

engine = create_async_engine(
    settings.DATABASE_URL,
    echo=settings.DEBUG,
    pool_pre_ping=True,
    pool_size=20,
    max_overflow=10,
)


async def get_session() -> AsyncSession:
    async with AsyncSession(engine, expire_on_commit=False) as session:
        yield session


async def create_tables() -> None:
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
