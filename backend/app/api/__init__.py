from app.api.auth import router as auth_router
from app.api.profile import router as profile_router
from app.api.recipes import router as recipes_router
from app.api.ai import router as ai_router
from app.api.videos import router as videos_router
from app.api.shopping import router as shopping_router
from app.api.meals import router as meals_router
from app.api.speech import router as speech_router

__all__ = [
    "auth_router",
    "profile_router",
    "recipes_router",
    "ai_router",
    "videos_router",
    "shopping_router",
    "meals_router",
    "speech_router",
]
