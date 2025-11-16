import whisper
from gtts import gTTS
from typing import Optional, Dict, List
import io
import base64
import tempfile
import os
from pathlib import Path
from langdetect import detect, LangDetectException

from app.config.settings import get_settings

settings = get_settings()


class SpeechService:
    """
    Speech-to-Text and Text-to-Speech service with multi-language support

    Supported Languages:
    - English (en)
    - Chinese/Mandarin (zh-cn)
    - Japanese (ja)
    - Korean (ko)
    - Thai (th)
    - Myanmar/Burmese (my)
    """

    SUPPORTED_LANGUAGES = {
        "en": {"name": "English", "tts_code": "en", "whisper_code": "en"},
        "zh": {"name": "Chinese", "tts_code": "zh-cn", "whisper_code": "zh"},
        "ja": {"name": "Japanese", "tts_code": "ja", "whisper_code": "ja"},
        "ko": {"name": "Korean", "tts_code": "ko", "whisper_code": "ko"},
        "th": {"name": "Thai", "tts_code": "th", "whisper_code": "th"},
        "my": {"name": "Myanmar", "tts_code": "my", "whisper_code": "my"},
    }

    def __init__(self):
        self.whisper_model = None
        self.model_size = settings.WHISPER_MODEL_SIZE  # Can be: tiny, base, small, medium, large

    def _load_whisper_model(self):
        """Lazy load Whisper model"""
        if self.whisper_model is None:
            print(f"Loading Whisper {self.model_size} model...")
            self.whisper_model = whisper.load_model(self.model_size)
            print("✅ Whisper model loaded")

    async def speech_to_text(
        self,
        audio_data: bytes,
        language: Optional[str] = None,
        translate_to_english: bool = False
    ) -> Dict:
        """
        Convert speech to text using Whisper

        Args:
            audio_data: Audio file bytes (MP3, WAV, M4A, etc.)
            language: Optional language code (en, zh, ja, ko, th, my)
            translate_to_english: Whether to translate to English

        Returns:
            {
                "text": "transcribed text",
                "language": "detected_language_code",
                "confidence": 0.95
            }
        """
        self._load_whisper_model()

        # Save audio to temporary file
        with tempfile.NamedTemporaryFile(delete=False, suffix=".wav") as temp_audio:
            temp_audio.write(audio_data)
            temp_audio_path = temp_audio.name

        try:
            # Transcribe or translate
            if translate_to_english:
                result = self.whisper_model.transcribe(
                    temp_audio_path,
                    task="translate"  # Translate to English
                )
            else:
                result = self.whisper_model.transcribe(
                    temp_audio_path,
                    language=language if language else None
                )

            return {
                "text": result["text"].strip(),
                "language": result.get("language", language or "unknown"),
                "confidence": 0.9,  # Whisper doesn't provide confidence
                "segments": result.get("segments", [])
            }

        finally:
            # Clean up temporary file
            os.unlink(temp_audio_path)

    async def text_to_speech(
        self,
        text: str,
        language: str = "en",
        slow: bool = False
    ) -> bytes:
        """
        Convert text to speech using gTTS

        Args:
            text: Text to convert to speech
            language: Language code (en, zh-cn, ja, ko, th, my)
            slow: Whether to speak slowly

        Returns:
            Audio bytes (MP3 format)
        """
        # Get TTS language code
        lang_config = self.SUPPORTED_LANGUAGES.get(language, self.SUPPORTED_LANGUAGES["en"])
        tts_lang = lang_config["tts_code"]

        # Generate speech
        tts = gTTS(text=text, lang=tts_lang, slow=slow)

        # Save to bytes
        audio_buffer = io.BytesIO()
        tts.write_to_fp(audio_buffer)
        audio_buffer.seek(0)

        return audio_buffer.read()

    async def detect_language(self, text: str) -> str:
        """
        Detect language from text

        Returns language code (en, zh, ja, ko, th, my)
        """
        try:
            detected = detect(text)

            # Map langdetect codes to our supported languages
            lang_map = {
                "en": "en",
                "zh-cn": "zh",
                "zh-tw": "zh",
                "ja": "ja",
                "ko": "ko",
                "th": "th",
                "my": "my"
            }

            return lang_map.get(detected, "en")
        except LangDetectException:
            return "en"  # Default to English

    async def process_voice_command(
        self,
        audio_data: bytes,
        user_language: str = "en"
    ) -> Dict:
        """
        Process voice command and return action

        Args:
            audio_data: Audio file bytes
            user_language: User's preferred language

        Returns:
            {
                "command": "transcribed command",
                "language": "detected_language",
                "intent": "search_recipe | create_meal_plan | etc.",
                "parameters": {...}
            }
        """
        # Transcribe audio
        transcription = await self.speech_to_text(audio_data, language=user_language)
        command_text = transcription["text"].lower()

        # Detect intent from command
        intent = await self._detect_intent(command_text, user_language)

        return {
            "command": transcription["text"],
            "language": transcription["language"],
            "intent": intent["intent"],
            "parameters": intent["parameters"],
            "confidence": transcription["confidence"]
        }

    async def _detect_intent(self, command: str, language: str) -> Dict:
        """
        Detect user intent from voice command

        Supported intents:
        - search_recipe
        - create_meal_plan
        - get_nutrition_info
        - analyze_food
        - get_recommendations
        - add_to_shopping_list
        - log_meal
        - unknown
        """
        command_lower = command.lower()

        # Intent patterns for different languages
        intent_patterns = {
            "en": {
                "search_recipe": ["find recipe", "search recipe", "show me recipe", "cook", "make"],
                "create_meal_plan": ["meal plan", "plan my meals", "weekly plan", "create plan"],
                "get_nutrition_info": ["nutrition", "calories", "how many calories", "nutritional"],
                "analyze_food": ["what is this", "identify food", "what food", "analyze"],
                "get_recommendations": ["recommend", "suggest", "what should i", "advice"],
                "add_to_shopping_list": ["shopping list", "add to list", "buy", "grocery"],
                "log_meal": ["log meal", "record", "ate", "had for"],
            },
            "zh": {
                "search_recipe": ["找食谱", "搜索食谱", "做菜", "烹饪", "怎么做"],
                "create_meal_plan": ["meal plan", "饮食计划", "一周计划"],
                "get_nutrition_info": ["营养", "卡路里", "热量"],
                "analyze_food": ["这是什么", "识别食物", "分析"],
                "get_recommendations": ["推荐", "建议"],
                "add_to_shopping_list": ["购物清单", "买"],
                "log_meal": ["记录", "吃了"],
            },
            "ja": {
                "search_recipe": ["レシピ", "料理", "作り方", "調理"],
                "create_meal_plan": ["食事プラン", "献立"],
                "get_nutrition_info": ["栄養", "カロリー"],
                "analyze_food": ["これは何", "食べ物", "分析"],
                "get_recommendations": ["おすすめ", "提案"],
                "add_to_shopping_list": ["買い物リスト", "購入"],
                "log_meal": ["記録", "食べた"],
            },
            "ko": {
                "search_recipe": ["레시피", "요리", "만들기", "조리"],
                "create_meal_plan": ["식단", "계획"],
                "get_nutrition_info": ["영양", "칼로리"],
                "analyze_food": ["이게 뭐야", "음식", "분석"],
                "get_recommendations": ["추천", "제안"],
                "add_to_shopping_list": ["장보기", "구매"],
                "log_meal": ["기록", "먹었어"],
            },
            "th": {
                "search_recipe": ["สูตรอาหาร", "ทำอาหาร", "ปรุงอาหาร"],
                "create_meal_plan": ["แผนอาหาร"],
                "get_nutrition_info": ["คุณค่าทางโภชนาการ", "แคลอรี"],
                "analyze_food": ["นี่คืออะไร", "อาหาร"],
                "get_recommendations": ["แนะนำ"],
                "add_to_shopping_list": ["รายการซื้อ"],
                "log_meal": ["บันทึก", "กิน"],
            },
            "my": {
                "search_recipe": ["ချက်နည်း", "အစားအစာ"],
                "create_meal_plan": ["အစားအသောက်စီမံချက်"],
                "get_nutrition_info": ["အာဟာရ", "ကယ်လိုရီ"],
                "analyze_food": ["ဒါဘာလဲ", "အစားအစာ"],
                "get_recommendations": ["အကြံပြု"],
                "add_to_shopping_list": ["စျေးဝယ်စာရင်း"],
                "log_meal": ["မှတ်တမ်း", "စားခဲ့"],
            }
        }

        # Get patterns for user's language (default to English)
        patterns = intent_patterns.get(language, intent_patterns["en"])

        # Check each intent
        for intent, keywords in patterns.items():
            if any(keyword in command_lower for keyword in keywords):
                # Extract parameters based on intent
                parameters = await self._extract_parameters(command_lower, intent, language)
                return {
                    "intent": intent,
                    "parameters": parameters
                }

        return {
            "intent": "unknown",
            "parameters": {}
        }

    async def _extract_parameters(
        self,
        command: str,
        intent: str,
        language: str
    ) -> Dict:
        """Extract parameters from command based on intent"""
        parameters = {}

        if intent == "search_recipe":
            # Try to extract food/dish name
            # This is simplified - in production, use NER or LLM
            words = command.split()
            # Remove common words
            stop_words = {
                "en": ["find", "search", "show", "me", "recipe", "for", "how", "to", "make", "cook"],
                "zh": ["找", "搜索", "食谱", "怎么", "做"],
                "ja": ["レシピ", "を", "の", "作り方"],
                "ko": ["레시피", "를", "의", "만들기"],
            }

            filtered = [w for w in words if w not in stop_words.get(language, stop_words["en"])]
            if filtered:
                parameters["query"] = " ".join(filtered)

        elif intent == "create_meal_plan":
            # Extract duration (days)
            if "week" in command or "weekly" in command or "7" in command:
                parameters["days"] = 7
            elif "day" in command:
                # Try to extract number
                words = command.split()
                for i, word in enumerate(words):
                    if word.isdigit():
                        parameters["days"] = int(word)
                        break
            else:
                parameters["days"] = 7  # Default

        elif intent == "get_nutrition_info":
            # Extract food name
            words = command.split()
            stop_words = ["nutrition", "calories", "in", "of", "how", "many"]
            filtered = [w for w in words if w not in stop_words]
            if filtered:
                parameters["food"] = " ".join(filtered)

        return parameters

    async def translate_text(
        self,
        text: str,
        source_lang: str,
        target_lang: str
    ) -> str:
        """
        Translate text between supported languages

        Uses LLM for translation for better quality
        """
        from app.services.llm_service import llm_service

        if source_lang == target_lang:
            return text

        source_name = self.SUPPORTED_LANGUAGES.get(source_lang, {}).get("name", source_lang)
        target_name = self.SUPPORTED_LANGUAGES.get(target_lang, {}).get("name", target_lang)

        prompt = f"Translate the following {source_name} text to {target_name}. Only return the translation, nothing else:\n\n{text}"

        translation = await llm_service.generate(
            prompt=prompt,
            temperature=0.3,
            max_tokens=500
        )

        return translation.strip()

    def get_supported_languages(self) -> List[Dict]:
        """Get list of supported languages"""
        return [
            {
                "code": code,
                "name": info["name"],
                "stt_supported": True,
                "tts_supported": True
            }
            for code, info in self.SUPPORTED_LANGUAGES.items()
        ]


# Singleton instance
speech_service = SpeechService()
