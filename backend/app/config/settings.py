from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    """Application settings and configuration"""

    # App Config
    APP_NAME: str = "NutriVision AI"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = True

    # Database
    DATABASE_URL: str = "postgresql+asyncpg://postgres:postgres@localhost:5432/nutrivision"

    # ChromaDB
    CHROMA_PERSIST_DIR: str = "./chroma_db"
    CHROMA_HOST: str = "localhost"
    CHROMA_PORT: int = 8000

    # Redis
    REDIS_URL: str = "redis://localhost:6379/0"

    # Security
    SECRET_KEY: str = "your-secret-key-change-this-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30

    # AI Models
    LLAMA_MODEL_PATH: str = "llama-2-7b-chat"
    OLLAMA_BASE_URL: str = "http://localhost:11434"

    VISION_MODEL: str = "google/vit-base-patch16-224"
    SENTENCE_TRANSFORMER_MODEL: str = "sentence-transformers/all-MiniLM-L6-v2"

    # BLIP Models
    BLIP_CAPTION_MODEL: str = "Salesforce/blip-image-captioning-base"
    BLIP_VQA_MODEL: str = "Salesforce/blip-vqa-base"
    # Options: base, large (larger = better quality but slower)

    # Speech & Multi-language
    WHISPER_MODEL_SIZE: str = "base"  # tiny, base, small, medium, large
    DEFAULT_LANGUAGE: str = "en"  # en, zh, ja, ko, th, my

    # External APIs
    YOUTUBE_API_KEY: str = ""
    USDA_API_KEY: str = ""
    EDAMAM_APP_ID: str = ""
    EDAMAM_APP_KEY: str = ""

    # CORS
    CORS_ORIGINS: list = ["http://localhost:3000", "http://localhost:5173"]

    # File Upload
    MAX_UPLOAD_SIZE: int = 10 * 1024 * 1024  # 10MB
    UPLOAD_DIR: str = "./uploads"

    # HIPAA/GDPR Compliance
    ENCRYPTION_KEY: str = ""  # Base64-encoded 256-bit key for PHI encryption
    ENABLE_AUDIT_LOGGING: bool = True
    ENABLE_PHI_ENCRYPTION: bool = True
    DATA_RETENTION_DAYS: int = 2555  # 7 years (HIPAA requirement)
    AUDIT_LOG_RETENTION_DAYS: int = 2190  # 6 years (HIPAA requirement)

    # Privacy & Compliance
    PRIVACY_POLICY_VERSION: str = "1.0.0"
    PRIVACY_POLICY_URL: str = "https://nutrivision.ai/privacy"
    TERMS_OF_SERVICE_URL: str = "https://nutrivision.ai/terms"
    GDPR_DPO_EMAIL: str = "privacy@nutrivision.ai"  # Data Protection Officer
    HIPAA_PRIVACY_OFFICER_EMAIL: str = "compliance@nutrivision.ai"

    # iOS/Mobile Compliance
    APP_STORE_PRIVACY_URL: str = "https://nutrivision.ai/app-privacy"
    DATA_DELETION_AVAILABLE: bool = True
    ACCOUNT_DELETION_AVAILABLE: bool = True

    class Config:
        env_file = ".env"
        case_sensitive = True


@lru_cache()
def get_settings() -> Settings:
    """Get cached settings instance"""
    return Settings()
