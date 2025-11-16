from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from strawberry.fastapi import GraphQLRouter
from contextlib import asynccontextmanager

from app.config.settings import get_settings
from app.schemas.graphql_schema import schema
from app.db.database import init_db
from app.api.auth import router as auth_router
from app.api.profile import router as profile_router

settings = get_settings()


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Startup and shutdown events"""
    # Startup
    print("🚀 Starting NutriVision AI...")
    await init_db()
    print("✅ Database initialized")

    # Initialize AI models (lazy loading recommended)
    print("🤖 AI models ready for initialization")

    yield

    # Shutdown
    print("👋 Shutting down NutriVision AI...")


app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    description="AI-Powered Meal Planning and Nutrition Assistant",
    lifespan=lifespan,
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# API routers
app.include_router(auth_router)
app.include_router(profile_router)

# GraphQL router
graphql_app = GraphQLRouter(schema)
app.include_router(graphql_app, prefix="/graphql")


@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "app": settings.APP_NAME,
        "version": settings.APP_VERSION,
        "status": "running",
        "endpoints": {
            "auth": {
                "register": "/auth/register",
                "login": "/auth/login",
                "me": "/auth/me",
                "refresh": "/auth/refresh",
                "change_password": "/auth/change-password",
            },
            "profile": {
                "update": "/profile/update",
                "recommendations": "/profile/nutrition-recommendations",
                "meal_plan": "/profile/generate-meal-plan",
                "health_summary": "/profile/health-summary",
            },
            "graphql": "/graphql",
            "docs": "/docs",
        }
    }


@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "database": "connected",
        "ai_models": "ready",
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8000,
        reload=settings.DEBUG,
    )
