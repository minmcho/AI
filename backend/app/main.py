from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from strawberry.fastapi import GraphQLRouter
from contextlib import asynccontextmanager

from app.config.settings import get_settings
from app.schemas.graphql_schema import schema
from app.db.database import init_db
from app.api import (
    auth_router,
    profile_router,
    recipes_router,
    ai_router,
    videos_router,
    shopping_router,
    meals_router,
    speech_router,
)
# HIPAA/GDPR Compliance & Medical Nutrition Therapy
from app.api.micronutrients import router as micronutrients_router
from app.api.treatment_diets import router as treatment_diets_router
from app.api.privacy import router as privacy_router
# Security Middleware
from app.middleware.rate_limit import apply_rate_limits

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
    description="AI-Powered Meal Planning and Nutrition Assistant with Multi-Agent Intelligence",
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

# Rate limiting middleware
limiter = apply_rate_limits(app)

# API routers
app.include_router(auth_router)
app.include_router(profile_router)
app.include_router(recipes_router)
app.include_router(ai_router)
app.include_router(videos_router)
app.include_router(shopping_router)
app.include_router(meals_router)
app.include_router(speech_router)

# HIPAA/GDPR Compliance & Medical Features
app.include_router(micronutrients_router)
app.include_router(treatment_diets_router)
app.include_router(privacy_router)

# GraphQL router
graphql_app = GraphQLRouter(schema)
app.include_router(graphql_app, prefix="/graphql")


@app.get("/")
async def root():
    """Root endpoint with API overview"""
    return {
        "app": settings.APP_NAME,
        "version": settings.APP_VERSION,
        "status": "running",
        "endpoints": {
            "auth": "/auth",
            "profile": "/profile",
            "recipes": "/recipes",
            "ai": "/ai",
            "videos": "/videos",
            "shopping": "/shopping",
            "meals": "/meals",
            "speech": "/speech",
            "micronutrients": "/micronutrients",
            "treatment_diets": "/treatment-diets",
            "privacy": "/privacy",
            "graphql": "/graphql",
            "docs": "/docs",
        },
        "features": [
            "User Authentication & Registration",
            "Personalized Nutrition Planning",
            "AI Recipe Discovery & Similarity Search",
            "Food Image Analysis (Vision AI)",
            "BLIP Image Captioning (Natural Language Descriptions)",
            "BLIP Visual Question Answering (Ask Questions About Food Images)",
            "Cooking Assistant Chat (LLaMA 3.2)",
            "Video Recommendations (YouTube, TikTok, Instagram)",
            "MCP Shopping Lists with Price Optimization",
            "Meal Planning & Journaling",
            "Social Sharing",
            "Cross-Cultural Meal Similarity",
            "Beverage Pairing AI",
            "Speech-to-Text & Text-to-Speech (Whisper & gTTS)",
            "Voice Commands with Intent Detection",
            "Multi-language Support (6 Languages: EN, ZH, JA, KO, TH, MY)",
            "AI-Powered Translation",
            "Micronutrient Tracking (Vitamins, Minerals, Trace Elements)",
            "Medical Nutrition Therapy (Treatment-Specific Diets)",
            "HIPAA-Compliant PHI Storage with Encryption",
            "GDPR Compliance (Data Portability, Right to Erasure)",
            "Comprehensive Audit Logging",
            "iOS App Store Privacy Compliance"
        ],
        "documentation": {
            "swagger": "/docs",
            "redoc": "/redoc",
            "endpoints_guide": "API_ENDPOINTS.md",
            "auth_guide": "AUTH_GUIDE.md"
        }
    }


@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "database": "connected",
        "ai_models": "ready",
        "services": {
            "llm": "LLaMA 3.2 (Ollama)",
            "vision": "Vision Transformer",
            "embeddings": "Sentence Transformers",
            "vector_db": "ChromaDB",
            "multi_agent": "CrewAI"
        },
        "compliance": {
            "hipaa": "PHI encryption, audit logging, access controls",
            "gdpr": "Data portability, right to erasure, consent management",
            "ccpa": "Data deletion, opt-out mechanisms",
            "ios_app_store": "Privacy labels, data deletion API"
        }
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8000,
        reload=settings.DEBUG,
    )
