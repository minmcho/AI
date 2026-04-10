"""
Celery Beat periodic maintenance tasks.
"""
from __future__ import annotations

import asyncio
import logging
from datetime import datetime, timezone

from app.tasks.celery_app import celery_app

logger = logging.getLogger(__name__)


@celery_app.task(name="app.tasks.maintenance_tasks.reset_monthly_streak_freeze")
def reset_monthly_streak_freeze():
    """Reset streak freeze availability on the 1st of each month."""
    async def _run():
        from app.models.database import get_session, WellnessProfile
        from sqlalchemy import update

        async for db in get_session():
            await db.execute(
                update(WellnessProfile).values(freeze_streak_used_this_month=False)
            )
            await db.commit()
            logger.info("Monthly streak freeze reset complete")

    asyncio.get_event_loop().run_until_complete(_run())


@celery_app.task(name="app.tasks.maintenance_tasks.refresh_fallback_tips")
def refresh_fallback_tips():
    """
    Refresh Redis cache with latest wellness tips from DB.
    Tips are served when AI circuit is OPEN.
    """
    import json
    import redis

    from app.config import get_settings
    settings = get_settings()
    r = redis.from_url(settings.REDIS_URL)

    async def _run():
        from app.models.database import get_session, WellnessTip
        from sqlalchemy import select

        async for db in get_session():
            tips = (
                await db.scalars(select(WellnessTip).where(WellnessTip.is_active == True))
            ).all()

            for tip in tips:
                for tag in (tip.tags or []):
                    key = f"fallback_tip:{tag}:{tip.language}"
                    r.set(key, json.dumps({"content": tip.content, "source": tip.source}), ex=86400)

            logger.info("Refreshed %d fallback tips in Redis", len(tips))

    asyncio.get_event_loop().run_until_complete(_run())


@celery_app.task(name="app.tasks.maintenance_tasks.recalculate_wellness_scores")
def recalculate_wellness_scores():
    """Recalculate and persist wellness scores for all active users."""
    async def _run():
        from app.models.database import get_session, WellnessProfile
        from sqlalchemy import select

        async for db in get_session():
            profiles = (await db.scalars(select(WellnessProfile))).all()
            for profile in profiles:
                streak_bonus = min((profile.current_streak or 0) * 2, 20)
                base = min(((profile.total_sessions or 0) / 100) * 80, 80)
                profile.wellness_score = round(min(base + streak_bonus, 100), 1)
            await db.commit()
            logger.info("Recalculated wellness scores for %d profiles", len(profiles))

    asyncio.get_event_loop().run_until_complete(_run())
