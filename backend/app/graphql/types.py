"""
Strawberry GraphQL type definitions for VitalPath AI.
Mirrors the SQLAlchemy models for the API surface.
"""
from __future__ import annotations

import strawberry
from typing import Optional, List
from datetime import datetime
from enum import Enum


@strawberry.enum
class SessionTypeGQL(Enum):
    CHAT = "chat"
    VIDEO_ANALYSIS = "video_analysis"
    HABIT_LOG = "habit_log"
    MINDFULNESS = "mindfulness"


@strawberry.enum
class GoalCategoryGQL(Enum):
    NUTRITION = "nutrition"
    EXERCISE = "exercise"
    SLEEP = "sleep"
    MINDFULNESS = "mindfulness"
    HYDRATION = "hydration"
    STRESS = "stress"


# ─────────────────────────── Output types ───────────────────

@strawberry.type
class WellnessProfileType:
    id: str
    display_name: Optional[str]
    avatar_url: Optional[str]
    preferred_language: str
    dietary_preferences: List[str]
    health_notes: List[str]
    wellness_goals: List[str]
    current_streak: int
    longest_streak: int
    total_sessions: int
    wellness_score: float
    created_at: datetime


@strawberry.type
class WellnessGoalType:
    id: str
    category: GoalCategoryGQL
    title: str
    description: Optional[str]
    target_value: Optional[float]
    current_value: float
    unit: Optional[str]
    ai_suggested: bool
    is_active: bool
    target_date: Optional[datetime]
    completed_at: Optional[datetime]
    created_at: datetime


@strawberry.type
class WellnessSessionType:
    id: str
    session_type: SessionTypeGQL
    title: Optional[str]
    summary: Optional[str]
    ai_model_used: Optional[str]
    intent_detected: Optional[str]
    language_detected: str
    mood_before: Optional[int]
    mood_after: Optional[int]
    duration_seconds: int
    flagged_for_review: bool
    safety_intercepted: bool
    created_at: datetime
    completed_at: Optional[datetime]


@strawberry.type
class ChatMessageType:
    role: str                      # "user" | "assistant"
    content: str
    timestamp: datetime


@strawberry.type
class ChatResponseType:
    session_id: str
    response_type: str             # "wellness" | "crisis" | "fallback"
    message: Optional[str]
    intent: str
    safety_intercepted: bool
    crisis_resources: Optional[CrisisResourceType]


@strawberry.type
class CrisisResourceType:
    country: str
    hotline: str
    name: str
    url: Optional[str]


@strawberry.type
class VideoAnalysisResultType:
    task_id: str
    status: str                    # "pending" | "processing" | "completed" | "failed"
    feedback: Optional[str]
    nutrition_estimate: Optional[str]
    form_notes: Optional[str]
    safety_flag: bool


@strawberry.type
class WearableDataType:
    platform: str
    is_connected: bool
    daily_steps: int
    resting_heart_rate: Optional[float]
    sleep_hours: Optional[float]
    active_calories: int
    hrv_ms: Optional[float]
    last_synced_at: Optional[datetime]


@strawberry.type
class StreakInfoType:
    current_streak: int
    longest_streak: int
    freeze_available: bool
    last_session_at: Optional[datetime]


@strawberry.type
class WellnessScoreType:
    overall: float
    breakdown: WellnessBreakdownType


@strawberry.type
class WellnessBreakdownType:
    nutrition: float
    exercise: float
    sleep: float
    mindfulness: float
    consistency: float


@strawberry.type
class AIGoalSuggestionType:
    category: GoalCategoryGQL
    title: str
    rationale: str
    target_value: Optional[float]
    unit: Optional[str]


# ─────────────────────────── Input types ────────────────────

@strawberry.input
class SendMessageInput:
    message: str
    session_id: Optional[str] = None
    language: str = "en"
    mood_before: Optional[int] = None      # 1–10


@strawberry.input
class CreateGoalInput:
    category: GoalCategoryGQL
    title: str
    description: Optional[str] = None
    target_value: Optional[float] = None
    unit: Optional[str] = None
    target_date: Optional[datetime] = None


@strawberry.input
class UpdateProfileInput:
    display_name: Optional[str] = None
    dietary_preferences: Optional[List[str]] = None
    health_notes: Optional[List[str]] = None
    wellness_goals: Optional[List[str]] = None
    preferred_session_time: Optional[str] = None
    preferred_language: Optional[str] = None


@strawberry.input
class LogHabitInput:
    category: GoalCategoryGQL
    value: float
    unit: str
    notes: Optional[str] = None
    mood_rating: Optional[int] = None


@strawberry.input
class InitiateVideoAnalysisInput:
    video_url: str
    analysis_type: str = "meal"      # "meal" | "exercise"
    session_id: Optional[str] = None
