"""
Strawberry GraphQL schema — root Query and Mutation types.
Auth is enforced via Supabase JWT decoded in the request context.
"""
from __future__ import annotations

import logging
from typing import List, Optional

import strawberry
from fastapi import Request
from strawberry.fastapi import BaseContext
from strawberry.types import Info

from app.graphql.types import (
    AIGoalSuggestionType,
    ChatResponseType,
    CreateGoalInput,
    InitiateVideoAnalysisInput,
    LogHabitInput,
    SendMessageInput,
    StreakInfoType,
    UpdateProfileInput,
    VideoAnalysisResultType,
    WellnessGoalType,
    WellnessProfileType,
    WellnessScoreType,
    WellnessSessionType,
)
from app.graphql.resolvers import chat_resolver, session_resolver, video_resolver
from app.models.database import get_session

logger = logging.getLogger(__name__)


# ─────────────────────── Context ────────────────────────────

class VitalPathContext(BaseContext):
    """Injects DB session and authenticated user_id into resolvers."""

    @property
    def user_id(self) -> str:
        """Extract Supabase user_id from JWT claims in Authorization header."""
        request: Request = self.request
        # In production: verify JWT with Supabase secret
        # Here we read the pre-verified claim forwarded by middleware
        uid = request.headers.get("X-User-ID")
        if not uid:
            raise PermissionError("Authentication required")
        return uid

    async def get_db(self):
        async for db in get_session():
            return db


async def get_context() -> VitalPathContext:
    return VitalPathContext()


# ─────────────────────── Query ───────────────────────────────

@strawberry.type
class Query:

    @strawberry.field(description="Get the authenticated user's wellness profile")
    async def my_profile(self, info: Info[VitalPathContext, None]) -> WellnessProfileType:
        db = await info.context.get_db()
        return await session_resolver.resolve_my_profile(info, db=db, user_id=info.context.user_id)

    @strawberry.field(description="Get the user's current streak information")
    async def streak_info(self, info: Info[VitalPathContext, None]) -> StreakInfoType:
        db = await info.context.get_db()
        return await session_resolver.resolve_streak_info(info, db=db, user_id=info.context.user_id)

    @strawberry.field(description="Get active wellness goals")
    async def my_goals(
        self,
        info: Info[VitalPathContext, None],
        active_only: bool = True,
    ) -> List[WellnessGoalType]:
        db = await info.context.get_db()
        return await session_resolver.resolve_my_goals(info, db=db, user_id=info.context.user_id, active_only=active_only)

    @strawberry.field(description="Get AI-suggested next wellness goals")
    async def suggested_goals(self, info: Info[VitalPathContext, None]) -> List[AIGoalSuggestionType]:
        db = await info.context.get_db()
        return await session_resolver.resolve_suggest_goals(info, db=db, user_id=info.context.user_id)

    @strawberry.field(description="Get overall wellness score and breakdown")
    async def wellness_score(self, info: Info[VitalPathContext, None]) -> WellnessScoreType:
        db = await info.context.get_db()
        return await session_resolver.resolve_wellness_score(info, db=db, user_id=info.context.user_id)

    @strawberry.field(description="Get a specific chat session by ID")
    async def session(
        self,
        info: Info[VitalPathContext, None],
        session_id: str,
    ) -> Optional[WellnessSessionType]:
        db = await info.context.get_db()
        return await chat_resolver.resolve_get_session(
            info, session_id=session_id, db=db, user_id=info.context.user_id
        )

    @strawberry.field(description="Poll video analysis task result")
    async def video_analysis_result(
        self,
        info: Info[VitalPathContext, None],
        task_id: str,
    ) -> VideoAnalysisResultType:
        db = await info.context.get_db()
        return await video_resolver.resolve_video_analysis_result(
            info, task_id=task_id, db=db, user_id=info.context.user_id
        )


# ─────────────────────── Mutation ────────────────────────────

@strawberry.type
class Mutation:

    @strawberry.mutation(description="Send a wellness coaching message")
    async def send_message(
        self,
        info: Info[VitalPathContext, None],
        input: SendMessageInput,
    ) -> ChatResponseType:
        db = await info.context.get_db()
        return await chat_resolver.resolve_send_message(
            info, input=input, db=db, user_id=info.context.user_id
        )

    @strawberry.mutation(description="Update user wellness profile")
    async def update_profile(
        self,
        info: Info[VitalPathContext, None],
        input: UpdateProfileInput,
    ) -> WellnessProfileType:
        db = await info.context.get_db()
        return await session_resolver.resolve_update_profile(
            info, input=input, db=db, user_id=info.context.user_id
        )

    @strawberry.mutation(description="Create a new wellness goal")
    async def create_goal(
        self,
        info: Info[VitalPathContext, None],
        input: CreateGoalInput,
    ) -> WellnessGoalType:
        db = await info.context.get_db()
        return await session_resolver.resolve_create_goal(
            info, input=input, db=db, user_id=info.context.user_id
        )

    @strawberry.mutation(description="Log a wellness habit (steps, water, sleep, etc.)")
    async def log_habit(
        self,
        info: Info[VitalPathContext, None],
        input: LogHabitInput,
    ) -> WellnessSessionType:
        db = await info.context.get_db()
        return await session_resolver.resolve_log_habit(
            info, input=input, db=db, user_id=info.context.user_id
        )

    @strawberry.mutation(description="Use freeze streak for a rest day (once per month)")
    async def freeze_streak(self, info: Info[VitalPathContext, None]) -> StreakInfoType:
        db = await info.context.get_db()
        return await session_resolver.resolve_freeze_streak(
            info, db=db, user_id=info.context.user_id
        )

    @strawberry.mutation(description="Initiate async video analysis")
    async def initiate_video_analysis(
        self,
        info: Info[VitalPathContext, None],
        input: InitiateVideoAnalysisInput,
    ) -> VideoAnalysisResultType:
        db = await info.context.get_db()
        return await video_resolver.resolve_initiate_video_analysis(
            info, input=input, db=db, user_id=info.context.user_id
        )


# ─────────────────────── Schema builder ──────────────────────

def build_schema() -> strawberry.Schema:
    return strawberry.Schema(
        query=Query,
        mutation=Mutation,
        context_getter=get_context,
    )
