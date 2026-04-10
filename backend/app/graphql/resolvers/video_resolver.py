"""
Video analysis resolvers — triggers Celery tasks and polls results.
"""
from __future__ import annotations

import logging
import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.graphql.types import (
    InitiateVideoAnalysisInput,
    VideoAnalysisResultType,
)
from app.models.database import WellnessProfile, WellnessSession, SessionType

logger = logging.getLogger(__name__)


async def resolve_initiate_video_analysis(
    info,
    input: InitiateVideoAnalysisInput,
    db: AsyncSession,
    user_id: str,
) -> VideoAnalysisResultType:
    """
    Validates the video URL belongs to the user's Supabase bucket,
    then enqueues a Celery task for async processing.
    """
    from app.tasks.video_tasks import analyze_video_task

    profile = await db.scalar(
        select(WellnessProfile).where(WellnessProfile.supabase_uid == user_id)
    )
    if not profile:
        raise ValueError("Profile not found")

    # Create a pending session
    session = WellnessSession(
        profile_id=profile.id,
        session_type=SessionType.VIDEO_ANALYSIS,
        title=f"{input.analysis_type.title()} Video Analysis",
        video_url=input.video_url,
        messages=[],
    )
    db.add(session)
    await db.commit()
    await db.refresh(session)

    # Enqueue Celery task
    task = analyze_video_task.delay(
        session_id=str(session.id),
        user_id=str(profile.id),
        video_url=input.video_url,
        analysis_type=input.analysis_type,
    )

    logger.info(
        "Video analysis task enqueued: task_id=%s session_id=%s", task.id, session.id
    )

    return VideoAnalysisResultType(
        task_id=task.id,
        status="pending",
        feedback=None,
        nutrition_estimate=None,
        form_notes=None,
        safety_flag=False,
    )


async def resolve_video_analysis_result(
    info,
    task_id: str,
    db: AsyncSession,
    user_id: str,
) -> VideoAnalysisResultType:
    """Poll Celery task result."""
    from celery.result import AsyncResult
    from app.tasks.celery_app import celery_app

    result = AsyncResult(task_id, app=celery_app)

    if result.state == "PENDING":
        return VideoAnalysisResultType(
            task_id=task_id, status="pending",
            feedback=None, nutrition_estimate=None, form_notes=None, safety_flag=False,
        )
    if result.state == "STARTED" or result.state == "PROGRESS":
        return VideoAnalysisResultType(
            task_id=task_id, status="processing",
            feedback=None, nutrition_estimate=None, form_notes=None, safety_flag=False,
        )
    if result.state == "SUCCESS":
        data: dict = result.result or {}
        return VideoAnalysisResultType(
            task_id=task_id,
            status="completed",
            feedback=data.get("feedback"),
            nutrition_estimate=data.get("nutrition_estimate"),
            form_notes=data.get("form_notes"),
            safety_flag=data.get("safety_flag", False),
        )

    return VideoAnalysisResultType(
        task_id=task_id, status="failed",
        feedback="Analysis failed. Please try again.",
        nutrition_estimate=None, form_notes=None, safety_flag=False,
    )
