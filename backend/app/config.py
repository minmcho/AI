from pydantic_settings import BaseSettings
from functools import lru_cache
from typing import List


class Settings(BaseSettings):
    # App
    APP_NAME: str = "VitalPath AI"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = False
    ALLOWED_ORIGINS: List[str] = ["*"]

    # Database
    DATABASE_URL: str = "postgresql+asyncpg://vitalpath:secret@localhost:5432/vitalpath"

    # Supabase
    SUPABASE_URL: str = ""
    SUPABASE_SERVICE_KEY: str = ""
    SUPABASE_JWT_SECRET: str = ""
    SUPABASE_BUCKET_VIDEOS: str = "wellness-videos"

    # Redis
    REDIS_URL: str = "redis://localhost:6379/0"
    CELERY_BROKER_URL: str = "redis://localhost:6379/1"
    CELERY_RESULT_BACKEND: str = "redis://localhost:6379/2"

    # ChromaDB
    CHROMA_HOST: str = "localhost"
    CHROMA_PORT: int = 8001
    CHROMA_COLLECTION: str = "user_wellness_context"

    # AI — Llama 4 (text / coaching)
    LLAMA4_API_URL: str = "https://api.together.xyz"
    LLAMA4_API_KEY: str = ""
    LLAMA4_MODEL: str = "meta-llama/Llama-4-Maverick-17B-128E-Instruct-FP8"

    # AI — Qwen 3.5 VL (vision + multilingual)
    QWEN_API_URL: str = "https://api.together.xyz"
    QWEN_API_KEY: str = ""
    QWEN_VL_MODEL: str = "Qwen/Qwen2.5-VL-72B-Instruct"
    QWEN_TEXT_MODEL: str = "Qwen/Qwen2.5-72B-Instruct"

    # Circuit Breaker
    CB_FAILURE_THRESHOLD: int = 5
    CB_RECOVERY_TIMEOUT: int = 60

    # Embedding model
    EMBEDDING_MODEL: str = "BAAI/bge-base-en-v1.5"

    # Wellness fallback cache TTL (seconds)
    FALLBACK_CACHE_TTL: int = 3600

    class Config:
        env_file = ".env"
        case_sensitive = True


@lru_cache()
def get_settings() -> Settings:
    return Settings()
