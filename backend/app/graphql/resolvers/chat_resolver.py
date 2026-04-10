"""
Chat resolvers — handles all conversational wellness AI interactions.
Integrates SafetyValidator + AIOrchestrator + ChromaDB.
"""
from __future__ import annotations

import logging
import uuid
from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.graphql.types import (
    ChatResponseType,
    CrisisResourceType,
    SendMessageInput,
    WellnessSessionType,
)
from app.models.database import WellnessProfile, WellnessSession, SafetyLog, SafetyEvent, SessionType
from app.services.ai_orchestrator import get_orchestrator
from app.services.safety_validator import SafetyLevel, get_crisis_resources

logger = logging.getLogger(__name__)


async def resolve_send_message(
    info,
    input: SendMessageInput,
    db: AsyncSession,
    user_id: str,
) -> ChatResponseType:
    orchestrator = get_orchestrator()

    # Fetch user profile for context
    profile = await db.scalar(
        select(WellnessProfile).where(WellnessProfile.supabase_uid == user_id)
    )
    if not profile:
        raise ValueError("User profile not found. Please complete onboarding.")

    # Detect language from header/input
    language = input.language or profile.preferred_language or "en"

    # Fetch or create session
    session_id = input.session_id
    session: WellnessSession | None = None

    if session_id:
        session = await db.get(WellnessSession, uuid.UUID(session_id))

    if not session:
        session = WellnessSession(
            profile_id=profile.id,
            session_type=SessionType.CHAT,
            language_detected=language,
            messages=[],
        )
        db.add(session)
        await db.flush()  # Get generated ID

    # Append user message to history
    messages: list[dict] = session.messages or []
    messages.append({"role": "user", "content": input.message, "timestamp": datetime.now(timezone.utc).isoformat()})

    # Build history for AI context (last 6 turns, role/content only)
    history = [{"role": m["role"], "content": m["content"]} for m in messages[-6:]]

    # Run through orchestrator
    result = await orchestrator.chat(
        user_id=str(profile.id),
        message=input.message,
        language=language,
        session_history=history[:-1],  # Exclude current message
    )

    # Handle crisis escalation
    if result["type"] == "crisis":
        # Log safety event (hashed, never plain text)
        safety_log = SafetyLog(
            profile_id=profile.id,
            event_type=SafetyEvent.CRISIS_TRIGGERED,
            content_hash=result.get("crisis_hash"),
            session_id=session.id,
            language=language,
        )
        db.add(safety_log)
        session.safety_intercepted = True
        session.flagged_for_review = True
        await db.commit()

        resources = result["crisis_resources"]
        return ChatResponseType(
            session_id=str(session.id),
            response_type="crisis",
            message=None,
            intent="crisis",
            safety_intercepted=True,
            crisis_resources=CrisisResourceType(
                country=resources["country"],
                hotline=resources["hotline"],
                name=resources["name"],
                url=resources.get("url"),
            ),
        )

    # Append assistant response to history
    ai_message = result.get("response", "")
    messages.append({
        "role": "assistant",
        "content": ai_message,
        "timestamp": datetime.now(timezone.utc).isoformat(),
    })

    # Update session
    session.messages = messages
    session.intent_detected = result.get("intent")
    session.language_detected = language
    session.safety_intercepted = result.get("safety_intercepted", False)
    if input.mood_before:
        session.mood_before = input.mood_before

    # Update profile stats
    profile.total_sessions = (profile.total_sessions or 0) + (1 if not session_id else 0)
    profile.last_active_at = datetime.now(timezone.utc)

    await db.commit()
    await db.refresh(session)

    return ChatResponseType(
        session_id=str(session.id),
        response_type=result["type"],
        message=ai_message,
        intent=result.get("intent", "general"),
        safety_intercepted=result.get("safety_intercepted", False),
        crisis_resources=None,
    )


async def resolve_get_session(
    info,
    session_id: str,
    db: AsyncSession,
    user_id: str,
) -> WellnessSessionType | None:
    session = await db.get(WellnessSession, uuid.UUID(session_id))
    if not session:
        return None

    profile = await db.get(WellnessProfile, session.profile_id)
    if not profile or profile.supabase_uid != user_id:
        raise PermissionError("Access denied")

    return WellnessSessionType(
        id=str(session.id),
        session_type=session.session_type,
        title=session.title,
        summary=session.summary,
        ai_model_used=session.ai_model_used,
        intent_detected=session.intent_detected,
        language_detected=session.language_detected or "en",
        mood_before=session.mood_before,
        mood_after=session.mood_after,
        duration_seconds=session.duration_seconds or 0,
        flagged_for_review=session.flagged_for_review or False,
        safety_intercepted=session.safety_intercepted or False,
        created_at=session.created_at,
        completed_at=session.completed_at,
    )
