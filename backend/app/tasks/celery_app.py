"""
Celery application configuration for VitalPath AI.
Workers handle: video analysis, streak resets, tip cache refresh.
"""
from __future__ import annotations

from celery import Celery
from celery.schedules import crontab

from app.config import get_settings

settings = get_settings()

celery_app = Celery(
    "vitalpath",
    broker=settings.CELERY_BROKER_URL,
    backend=settings.CELERY_RESULT_BACKEND,
    include=[
        "app.tasks.video_tasks",
        "app.tasks.maintenance_tasks",
    ],
)

celery_app.conf.update(
    # Serialisation
    task_serializer="json",
    accept_content=["json"],
    result_serializer="json",
    timezone="UTC",
    enable_utc=True,

    # Reliability
    task_acks_late=True,
    task_reject_on_worker_lost=True,
    worker_prefetch_multiplier=1,

    # Concurrency (per Kubernetes pod — tune via env)
    worker_concurrency=4,

    # Result expiry
    result_expires=3600,

    # Retry defaults
    task_max_retries=3,
    task_default_retry_delay=10,

    # Beat schedule — periodic tasks
    beat_schedule={
        "reset-monthly-streak-freeze": {
            "task": "app.tasks.maintenance_tasks.reset_monthly_streak_freeze",
            "schedule": crontab(day_of_month=1, hour=0, minute=0),
        },
        "refresh-fallback-tips-cache": {
            "task": "app.tasks.maintenance_tasks.refresh_fallback_tips",
            "schedule": crontab(hour=3, minute=0),  # Daily at 03:00 UTC
        },
        "calculate-wellness-scores": {
            "task": "app.tasks.maintenance_tasks.recalculate_wellness_scores",
            "schedule": crontab(hour=2, minute=0),  # Daily at 02:00 UTC
        },
    },
)
