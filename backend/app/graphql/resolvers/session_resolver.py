"""
Session & profile resolvers — habit logging, streaks, goals, profile updates.
"""
from __future__ import annotations

import logging
from datetime import datetime, timezone, timedelta
from typing import List, Optional

from sqlalchemy import select, desc
from sqlalchemy.ext.asyncio import AsyncSession

from app.graphql.types import (
    AIGoalSuggestionType,
    CreateGoalInput,
    GoalCategoryGQL,
    LogHabitInput,
    StreakInfoType,
    UpdateProfileInput,
    WellnessGoalType,
    WellnessProfileType,
    WellnessScoreType,
    WellnessBreakdownType,
    WellnessSessionType,
)
from app.models.database import (
    WellnessGoal,
    WellnessProfile,
    WellnessSession,
    SessionType,
    GoalCategory,
)
from app.services.ai_orchestrator import get_orchestrator

logger = logging.getLogger(__name__)


# ── Profile ──────────────────────────────────────────────────

async def resolve_my_profile(
    info,
    db: AsyncSession,
    user_id: str,
) -> WellnessProfileType:
    profile = await db.scalar(
        select(WellnessProfile).where(WellnessProfile.supabase_uid == user_id)
    )
    if not profile:
        raise ValueError("Profile not found")

    return WellnessProfileType(
        id=str(profile.id),
        display_name=profile.display_name,
        avatar_url=profile.avatar_url,
        preferred_language=profile.preferred_language or "en",
        dietary_preferences=profile.dietary_preferences or [],
        health_notes=profile.health_notes or [],
        wellness_goals=profile.wellness_goals or [],
        current_streak=profile.current_streak or 0,
        longest_streak=profile.longest_streak or 0,
        total_sessions=profile.total_sessions or 0,
        wellness_score=profile.wellness_score or 0.0,
        created_at=profile.created_at,
    )


async def resolve_update_profile(
    info,
    input: UpdateProfileInput,
    db: AsyncSession,
    user_id: str,
) -> WellnessProfileType:
    profile = await db.scalar(
        select(WellnessProfile).where(WellnessProfile.supabase_uid == user_id)
    )
    if not profile:
        raise ValueError("Profile not found")

    if input.display_name is not None:
        profile.display_name = input.display_name
    if input.dietary_preferences is not None:
        profile.dietary_preferences = input.dietary_preferences
    if input.health_notes is not None:
        profile.health_notes = input.health_notes
    if input.wellness_goals is not None:
        profile.wellness_goals = input.wellness_goals
    if input.preferred_session_time is not None:
        profile.preferred_session_time = input.preferred_session_time
    if input.preferred_language is not None:
        profile.preferred_language = input.preferred_language

    await db.commit()
    await db.refresh(profile)

    # Re-seed vector store with updated profile
    from app.services.vector_store import get_vector_store
    vs = get_vector_store()
    await vs.seed_user_profile(str(profile.id), {
        "dietary_preferences": profile.dietary_preferences,
        "health_notes": profile.health_notes,
        "wellness_goals": profile.wellness_goals,
        "preferred_session_time": profile.preferred_session_time,
    })

    return WellnessProfileType(
        id=str(profile.id),
        display_name=profile.display_name,
        avatar_url=profile.avatar_url,
        preferred_language=profile.preferred_language or "en",
        dietary_preferences=profile.dietary_preferences or [],
        health_notes=profile.health_notes or [],
        wellness_goals=profile.wellness_goals or [],
        current_streak=profile.current_streak or 0,
        longest_streak=profile.longest_streak or 0,
        total_sessions=profile.total_sessions or 0,
        wellness_score=profile.wellness_score or 0.0,
        created_at=profile.created_at,
    )


# ── Streaks ──────────────────────────────────────────────────

async def resolve_streak_info(
    info,
    db: AsyncSession,
    user_id: str,
) -> StreakInfoType:
    profile = await db.scalar(
        select(WellnessProfile).where(WellnessProfile.supabase_uid == user_id)
    )
    if not profile:
        raise ValueError("Profile not found")

    # Find last session
    last_session = await db.scalar(
        select(WellnessSession)
        .where(WellnessSession.profile_id == profile.id)
        .order_by(desc(WellnessSession.created_at))
        .limit(1)
    )

    return StreakInfoType(
        current_streak=profile.current_streak or 0,
        longest_streak=profile.longest_streak or 0,
        freeze_available=not (profile.freeze_streak_used_this_month or False),
        last_session_at=last_session.created_at if last_session else None,
    )


async def resolve_freeze_streak(
    info,
    db: AsyncSession,
    user_id: str,
) -> StreakInfoType:
    profile = await db.scalar(
        select(WellnessProfile).where(WellnessProfile.supabase_uid == user_id)
    )
    if not profile:
        raise ValueError("Profile not found")

    if profile.freeze_streak_used_this_month:
        raise ValueError("Streak freeze already used this month")

    profile.freeze_streak_used_this_month = True
    await db.commit()

    return StreakInfoType(
        current_streak=profile.current_streak or 0,
        longest_streak=profile.longest_streak or 0,
        freeze_available=False,
        last_session_at=None,
    )


# ── Goals ────────────────────────────────────────────────────

async def resolve_my_goals(
    info,
    db: AsyncSession,
    user_id: str,
    active_only: bool = True,
) -> List[WellnessGoalType]:
    profile = await db.scalar(
        select(WellnessProfile).where(WellnessProfile.supabase_uid == user_id)
    )
    query = select(WellnessGoal).where(WellnessGoal.profile_id == profile.id)
    if active_only:
        query = query.where(WellnessGoal.is_active == True)

    goals = (await db.scalars(query)).all()
    return [
        WellnessGoalType(
            id=str(g.id),
            category=GoalCategoryGQL(g.category.value),
            title=g.title,
            description=g.description,
            target_value=g.target_value,
            current_value=g.current_value or 0.0,
            unit=g.unit,
            ai_suggested=g.ai_suggested or False,
            is_active=g.is_active or True,
            target_date=g.target_date,
            completed_at=g.completed_at,
            created_at=g.created_at,
        )
        for g in goals
    ]


async def resolve_create_goal(
    info,
    input: CreateGoalInput,
    db: AsyncSession,
    user_id: str,
) -> WellnessGoalType:
    profile = await db.scalar(
        select(WellnessProfile).where(WellnessProfile.supabase_uid == user_id)
    )
    goal = WellnessGoal(
        profile_id=profile.id,
        category=GoalCategory(input.category.value),
        title=input.title,
        description=input.description,
        target_value=input.target_value,
        unit=input.unit,
        target_date=input.target_date,
        ai_suggested=False,
    )
    db.add(goal)
    await db.commit()
    await db.refresh(goal)

    return WellnessGoalType(
        id=str(goal.id),
        category=GoalCategoryGQL(goal.category.value),
        title=goal.title,
        description=goal.description,
        target_value=goal.target_value,
        current_value=goal.current_value or 0.0,
        unit=goal.unit,
        ai_suggested=False,
        is_active=True,
        target_date=goal.target_date,
        completed_at=None,
        created_at=goal.created_at,
    )


async def resolve_suggest_goals(
    info,
    db: AsyncSession,
    user_id: str,
) -> List[AIGoalSuggestionType]:
    """Use AI to suggest next goals based on profile + recent sessions."""
    profile = await db.scalar(
        select(WellnessProfile).where(WellnessProfile.supabase_uid == user_id)
    )

    # Build context for AI
    context = (
        f"User goals: {profile.wellness_goals}. "
        f"Streak: {profile.current_streak} days. "
        f"Total sessions: {profile.total_sessions}."
    )

    orchestrator = get_orchestrator()
    result = await orchestrator.chat(
        user_id=str(profile.id),
        message=(
            "Based on my profile and progress, suggest 3 specific, achievable wellness goals for next week. "
            "Format as JSON array: [{\"category\": \"...\", \"title\": \"...\", \"rationale\": \"...\", "
            "\"target_value\": 0, \"unit\": \"...\"}]"
        ),
        language=profile.preferred_language or "en",
    )

    import json
    try:
        raw = result.get("response", "[]")
        start = raw.find("[")
        end = raw.rfind("]") + 1
        suggestions = json.loads(raw[start:end])
        return [
            AIGoalSuggestionType(
                category=GoalCategoryGQL(s.get("category", "general").upper()),
                title=s.get("title", ""),
                rationale=s.get("rationale", ""),
                target_value=s.get("target_value"),
                unit=s.get("unit"),
            )
            for s in suggestions[:3]
        ]
    except Exception:
        return []


# ── Habit logging ────────────────────────────────────────────

async def resolve_log_habit(
    info,
    input: LogHabitInput,
    db: AsyncSession,
    user_id: str,
) -> WellnessSessionType:
    profile = await db.scalar(
        select(WellnessProfile).where(WellnessProfile.supabase_uid == user_id)
    )

    session = WellnessSession(
        profile_id=profile.id,
        session_type=SessionType.HABIT_LOG,
        title=f"{input.category.value.title()} habit logged",
        summary=f"{input.value} {input.unit}. Notes: {input.notes or 'N/A'}",
        messages=[],
        mood_before=input.mood_rating,
    )
    db.add(session)

    # Update streak
    now = datetime.now(timezone.utc)
    last_active = profile.last_active_at

    if last_active and (now - last_active) <= timedelta(hours=48):
        if (now - last_active) > timedelta(hours=24):
            profile.current_streak = (profile.current_streak or 0) + 1
    else:
        profile.current_streak = 1

    if (profile.current_streak or 0) > (profile.longest_streak or 0):
        profile.longest_streak = profile.current_streak

    profile.last_active_at = now
    profile.total_sessions = (profile.total_sessions or 0) + 1

    await db.commit()
    await db.refresh(session)

    return WellnessSessionType(
        id=str(session.id),
        session_type=session.session_type,
        title=session.title,
        summary=session.summary,
        ai_model_used=None,
        intent_detected=input.category.value,
        language_detected="en",
        mood_before=session.mood_before,
        mood_after=None,
        duration_seconds=0,
        flagged_for_review=False,
        safety_intercepted=False,
        created_at=session.created_at,
        completed_at=None,
    )


# ── Wellness score ───────────────────────────────────────────

async def resolve_wellness_score(
    info,
    db: AsyncSession,
    user_id: str,
) -> WellnessScoreType:
    profile = await db.scalar(
        select(WellnessProfile).where(WellnessProfile.supabase_uid == user_id)
    )

    # Simple scoring: each category contributes equally (20%)
    # Real implementation would use actual tracked data
    streak_bonus = min((profile.current_streak or 0) * 2, 20)
    base = min(((profile.total_sessions or 0) / 100) * 80, 80)
    overall = min(base + streak_bonus, 100)

    return WellnessScoreType(
        overall=round(overall, 1),
        breakdown=WellnessBreakdownType(
            nutrition=round(overall * 0.9, 1),
            exercise=round(overall * 0.85, 1),
            sleep=round(overall * 0.8, 1),
            mindfulness=round(overall * 0.95, 1),
            consistency=round(min(streak_bonus * 5, 100), 1),
        ),
    )
