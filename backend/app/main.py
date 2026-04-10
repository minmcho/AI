"""
VitalPath AI — FastAPI entry point.
Mounts Strawberry GraphQL, WebSocket support, and health endpoints.
"""
from __future__ import annotations

import logging
from contextlib import asynccontextmanager

import strawberry
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from strawberry.fastapi import GraphQLRouter

from app.config import get_settings
from app.models.database import create_tables
from app.graphql.schema import build_schema

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)
settings = get_settings()


@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("VitalPath AI starting up …")
    await create_tables()
    logger.info("Database tables ready.")
    yield
    logger.info("VitalPath AI shutting down.")


def create_app() -> FastAPI:
    app = FastAPI(
        title=settings.APP_NAME,
        version=settings.APP_VERSION,
        lifespan=lifespan,
        docs_url="/docs" if settings.DEBUG else None,
        redoc_url=None,
    )

    # ── CORS ──────────────────────────────────────────────────
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.ALLOWED_ORIGINS,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # ── GraphQL ───────────────────────────────────────────────
    schema = build_schema()
    graphql_app = GraphQLRouter(schema, graphql_ide="apollo-sandbox" if settings.DEBUG else None)
    app.include_router(graphql_app, prefix="/graphql")

    # ── Health endpoints ──────────────────────────────────────
    @app.get("/health", tags=["infra"])
    async def health():
        return {"status": "healthy", "version": settings.APP_VERSION}

    @app.get("/health/ready", tags=["infra"])
    async def readiness():
        return {"status": "ready"}

    # ── Global exception handler ──────────────────────────────
    @app.exception_handler(Exception)
    async def global_exception_handler(request: Request, exc: Exception):
        logger.error("Unhandled exception: %s", exc, exc_info=True)
        return JSONResponse(
            status_code=500,
            content={"error": "Internal server error", "detail": str(exc) if settings.DEBUG else "Contact support"},
        )

    return app


app = create_app()
