from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File
from sqlalchemy.ext.asyncio import AsyncSession
from pydantic import BaseModel
from typing import List, Optional, Dict
import base64

from app.db.database import get_db
from app.services.auth_service import auth_service
from app.services.speech_service import speech_service
from app.api.auth import oauth2_scheme

router = APIRouter(prefix="/speech", tags=["Speech & Multi-language"])


# Pydantic models
class TranscribeRequest(BaseModel):
    audio_base64: str
    language: Optional[str] = None
    translate_to_english: bool = False


class TranscribeResponse(BaseModel):
    text: str
    language: str
    confidence: float


class SynthesizeRequest(BaseModel):
    text: str
    language: str = "en"
    slow: bool = False


class SynthesizeResponse(BaseModel):
    audio_base64: str
    language: str


class VoiceCommandRequest(BaseModel):
    audio_base64: str
    user_language: str = "en"


class VoiceCommandResponse(BaseModel):
    command: str
    language: str
    intent: str
    parameters: Dict
    confidence: float


class TranslateRequest(BaseModel):
    text: str
    source_lang: str
    target_lang: str


class TranslateResponse(BaseModel):
    translated_text: str
    source_lang: str
    target_lang: str


class LanguageInfo(BaseModel):
    code: str
    name: str
    stt_supported: bool
    tts_supported: bool


@router.post("/transcribe", response_model=TranscribeResponse)
async def transcribe_audio(
    request: TranscribeRequest,
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
    """
    Speech-to-text transcription

    Convert audio to text using OpenAI Whisper with multi-language support.

    Supports 6 languages:
    - English (en)
    - Chinese/Mandarin (zh)
    - Japanese (ja)
    - Korean (ko)
    - Thai (th)
    - Myanmar/Burmese (my)

    **Features:**
    - Automatic language detection if not specified
    - Optional translation to English
    - High accuracy across all supported languages

    **Audio Format:**
    - Accepts base64-encoded audio
    - Supports: MP3, WAV, M4A, FLAC, OGG
    - Max file size: 25MB
    """
    user = await auth_service.get_current_user(db=db, token=token)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")

    try:
        # Decode base64 audio
        audio_data = base64.b64decode(request.audio_base64)

        # Transcribe
        result = await speech_service.speech_to_text(
            audio_data=audio_data,
            language=request.language,
            translate_to_english=request.translate_to_english
        )

        return TranscribeResponse(
            text=result["text"],
            language=result["language"],
            confidence=result["confidence"]
        )

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Transcription failed: {str(e)}")


@router.post("/transcribe/upload", response_model=TranscribeResponse)
async def transcribe_audio_upload(
    file: UploadFile = File(...),
    language: Optional[str] = None,
    translate_to_english: bool = False,
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
    """
    Speech-to-text via file upload

    Upload an audio file directly for transcription.

    **Accepts:** MP3, WAV, M4A, FLAC, OGG
    **Max size:** 25MB
    """
    user = await auth_service.get_current_user(db=db, token=token)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")

    # Validate file size (25MB limit)
    MAX_SIZE = 25 * 1024 * 1024
    contents = await file.read()

    if len(contents) > MAX_SIZE:
        raise HTTPException(status_code=400, detail="File too large. Maximum size is 25MB")

    # Validate file type
    allowed_types = ["audio/mpeg", "audio/wav", "audio/m4a", "audio/flac", "audio/ogg"]
    if file.content_type not in allowed_types:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid file type. Allowed: {', '.join(allowed_types)}"
        )

    try:
        # Transcribe
        result = await speech_service.speech_to_text(
            audio_data=contents,
            language=language,
            translate_to_english=translate_to_english
        )

        return TranscribeResponse(
            text=result["text"],
            language=result["language"],
            confidence=result["confidence"]
        )

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Transcription failed: {str(e)}")


@router.post("/synthesize", response_model=SynthesizeResponse)
async def synthesize_speech(
    request: SynthesizeRequest,
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
    """
    Text-to-speech synthesis

    Convert text to natural-sounding speech using gTTS.

    **Supported Languages:**
    - English (en)
    - Chinese/Mandarin (zh)
    - Japanese (ja)
    - Korean (ko)
    - Thai (th)
    - Myanmar/Burmese (my)

    **Features:**
    - Natural-sounding voices
    - Adjustable speed (normal/slow)
    - Returns base64-encoded MP3 audio

    **Use Cases:**
    - Recipe instructions narration
    - Cooking step-by-step guidance
    - Nutrition advice playback
    - Multi-language accessibility
    """
    user = await auth_service.get_current_user(db=db, token=token)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")

    try:
        # Generate speech
        audio_bytes = await speech_service.text_to_speech(
            text=request.text,
            language=request.language,
            slow=request.slow
        )

        # Encode to base64
        audio_base64 = base64.b64encode(audio_bytes).decode('utf-8')

        return SynthesizeResponse(
            audio_base64=audio_base64,
            language=request.language
        )

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Speech synthesis failed: {str(e)}")


@router.post("/voice-command", response_model=VoiceCommandResponse)
async def process_voice_command(
    request: VoiceCommandRequest,
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
    """
    Process voice command

    Convert voice command to text and detect user intent.

    **Supported Intents:**
    - `search_recipe`: Find recipes by name or ingredients
    - `create_meal_plan`: Generate meal plans
    - `get_nutrition_info`: Get nutritional information
    - `analyze_food`: Analyze food from description
    - `get_recommendations`: Get AI recommendations
    - `add_to_shopping_list`: Add items to shopping list
    - `log_meal`: Log meal to journal
    - `unknown`: Intent not recognized

    **Multi-language Support:**
    All intents are supported in all 6 languages with native keywords.

    **Example Commands:**
    - English: "Find recipe for pasta carbonara"
    - Chinese: "找意大利面食谱"
    - Japanese: "パスタのレシピを探して"
    - Korean: "파스타 레시피 찾아줘"
    - Thai: "หาสูตรทำพาสต้า"
    - Myanmar: "ပါစတာချက်နည်းရှာပါ"

    **Returns:**
    - Transcribed command text
    - Detected intent
    - Extracted parameters
    - Confidence score
    """
    user = await auth_service.get_current_user(db=db, token=token)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")

    try:
        # Decode audio
        audio_data = base64.b64decode(request.audio_base64)

        # Process command
        result = await speech_service.process_voice_command(
            audio_data=audio_data,
            user_language=request.user_language
        )

        return VoiceCommandResponse(
            command=result["command"],
            language=result["language"],
            intent=result["intent"],
            parameters=result["parameters"],
            confidence=result["confidence"]
        )

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Voice command processing failed: {str(e)}")


@router.post("/voice-command/upload", response_model=VoiceCommandResponse)
async def process_voice_command_upload(
    file: UploadFile = File(...),
    user_language: str = "en",
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
    """
    Process voice command via file upload

    Upload audio file with voice command for processing.
    """
    user = await auth_service.get_current_user(db=db, token=token)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")

    # Validate file
    MAX_SIZE = 10 * 1024 * 1024  # 10MB for voice commands
    contents = await file.read()

    if len(contents) > MAX_SIZE:
        raise HTTPException(status_code=400, detail="File too large. Maximum size is 10MB")

    try:
        # Process command
        result = await speech_service.process_voice_command(
            audio_data=contents,
            user_language=user_language
        )

        return VoiceCommandResponse(
            command=result["command"],
            language=result["language"],
            intent=result["intent"],
            parameters=result["parameters"],
            confidence=result["confidence"]
        )

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Voice command processing failed: {str(e)}")


@router.post("/translate", response_model=TranslateResponse)
async def translate_text(
    request: TranslateRequest,
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
    """
    Translate text between languages

    Translate text between any of the 6 supported languages using LLM.

    **Features:**
    - High-quality LLM-based translation
    - Context-aware translation
    - Preserves meaning and nuance
    - Optimized for food and nutrition domain

    **Supported Languages:**
    - en: English
    - zh: Chinese/Mandarin
    - ja: Japanese
    - ko: Korean
    - th: Thai
    - my: Myanmar/Burmese

    **Example:**
    ```json
    {
        "text": "This pasta carbonara is delicious",
        "source_lang": "en",
        "target_lang": "ja"
    }
    ```
    """
    user = await auth_service.get_current_user(db=db, token=token)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")

    try:
        # Validate languages
        supported = ["en", "zh", "ja", "ko", "th", "my"]
        if request.source_lang not in supported or request.target_lang not in supported:
            raise HTTPException(
                status_code=400,
                detail=f"Language not supported. Supported: {', '.join(supported)}"
            )

        # Translate
        translated = await speech_service.translate_text(
            text=request.text,
            source_lang=request.source_lang,
            target_lang=request.target_lang
        )

        return TranslateResponse(
            translated_text=translated,
            source_lang=request.source_lang,
            target_lang=request.target_lang
        )

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Translation failed: {str(e)}")


@router.get("/languages", response_model=List[LanguageInfo])
async def get_supported_languages(
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
    """
    Get list of supported languages

    Returns all languages supported by the speech and translation services.

    **Languages:**
    1. **English (en)** - Full support
    2. **Chinese/Mandarin (zh)** - Full support
    3. **Japanese (ja)** - Full support
    4. **Korean (ko)** - Full support
    5. **Thai (th)** - Full support
    6. **Myanmar/Burmese (my)** - Full support

    **All languages support:**
    - Speech-to-text (STT)
    - Text-to-speech (TTS)
    - Voice commands
    - Translation
    - Intent detection
    """
    user = await auth_service.get_current_user(db=db, token=token)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")

    languages = speech_service.get_supported_languages()
    return [LanguageInfo(**lang) for lang in languages]


@router.get("/detect-language")
async def detect_language_from_text(
    text: str,
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
    """
    Detect language from text

    Automatically detect the language of provided text.

    **Use Cases:**
    - Auto-detect user input language
    - Language-aware search
    - Automatic translation routing
    """
    user = await auth_service.get_current_user(db=db, token=token)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")

    try:
        detected_lang = await speech_service.detect_language(text)

        # Get language name
        lang_info = next(
            (lang for lang in speech_service.get_supported_languages() if lang["code"] == detected_lang),
            None
        )

        return {
            "detected_language": detected_lang,
            "language_name": lang_info["name"] if lang_info else "Unknown",
            "text": text
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Language detection failed: {str(e)}")
