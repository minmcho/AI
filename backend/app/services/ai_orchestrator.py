"""
VitalPath AI Orchestrator
=========================
Multi-agent router that selects the right model and applies the full
safety pipeline (input scan → context retrieval → generation → output scan).

Routing logic:
  ┌────────────────────────────────────────────────────────────┐
  │  Input                                                     │
  │   └─ Safety Validator (pre)                               │
  │       ├─ CRISIS → Escalation (no AI call)                 │
  │       └─ SAFE/PII_REDACTED → Intent Detection             │
  │           ├─ Multilingual / Complex → Qwen 3.5            │
  │           └─ Nutrition / Exercise / General → Llama 4     │
  │               └─ Safety Validator (post)                  │
  │                   ├─ BLOCKED → Regenerate (strict prompt) │
  │                   └─ SAFE → Return to user                │
  └────────────────────────────────────────────────────────────┘
"""
from __future__ import annotations

import logging
from enum import Enum
from typing import Any

import httpx

from app.config import get_settings
from app.services.circuit_breaker import CircuitBreaker, CircuitOpenError
from app.services.safety_validator import (
    SafetyLevel,
    SafetyValidator,
    get_crisis_resources,
)
from app.services.vector_store import get_vector_store

logger = logging.getLogger(__name__)
settings = get_settings()


# ─────────────────────────── Enums ──────────────────────────

class QueryIntent(str, Enum):
    NUTRITION = "nutrition"
    MINDFULNESS = "mindfulness"
    EXERCISE = "exercise"
    SLEEP = "sleep"
    GENERAL = "general"
    MULTILINGUAL = "multilingual"
    COMPLEX = "complex"


# ─────────────────────── Prompt templates ───────────────────

_SYSTEM_BASE = (
    "You are a certified wellness coach named Vita, NOT a doctor. "
    "You help users with lifestyle habits, nutrition guidance, mindfulness, "
    "exercise form, motivation, and general wellbeing. "
    "NEVER diagnose medical conditions. NEVER prescribe medications. "
    "NEVER claim to treat or cure any disease. "
    "If a user describes a medical concern, warmly encourage them to consult "
    "a qualified healthcare professional."
)

_SYSTEM_STRICT = (
    _SYSTEM_BASE
    + " IMPORTANT: Your previous response was flagged for containing prohibited "
    "medical claims. In this regenerated response, discuss ONLY lifestyle habits, "
    "general wellness tips, and emotional support. Do NOT reference any specific "
    "disease, condition, medication, or treatment."
)

_SYSTEM_MULTILINGUAL = (
    _SYSTEM_BASE
    + " Always respond in the SAME LANGUAGE as the user's message. "
    "Supported languages: English (en), Myanmar (my), Thai (th), "
    "Chinese (zh), Japanese (ja), Korean (ko)."
)


# ─────────────────────── Fallback tips ──────────────────────

_FALLBACK_TIPS = {
    "stress": (
        "Take 5 slow, deep breaths — inhale for 4 counts, hold for 4, exhale for 6. "
        "Short breathing exercises can quickly calm your nervous system. "
        "Also, a 10-minute walk in nature can work wonders for stress. 🌿"
    ),
    "sleep": (
        "Try maintaining a consistent sleep schedule — even on weekends. "
        "Dim your lights an hour before bed and avoid screens. "
        "A cool room (65–68°F / 18–20°C) tends to improve sleep quality. 😴"
    ),
    "nutrition": (
        "A simple rule: fill half your plate with colourful vegetables, "
        "one quarter with lean protein, and one quarter with whole grains. "
        "Stay hydrated — aim for 8 glasses of water daily. 🥗"
    ),
    "exercise": (
        "Even 20 minutes of moderate movement per day improves mood and energy. "
        "Try a brisk walk, bodyweight exercises, or a short yoga flow. "
        "Consistency beats intensity for long-term wellness. 💪"
    ),
    "general": (
        "Small, consistent habits create lasting change. "
        "Today, try choosing one thing to do for your body and one for your mind. "
        "I am here to support you every step of the way. ✨"
    ),
}


# ─────────────────────── Orchestrator ───────────────────────

class AIOrchestrator:
    """
    Stateful AI orchestrator with circuit breakers for each model backend.
    Designed to be instantiated once (singleton) and reused.
    """

    def __init__(self) -> None:
        self.safety = SafetyValidator()
        self.vector_store = get_vector_store()

        self.llama_cb = CircuitBreaker(
            name="llama4",
            failure_threshold=settings.CB_FAILURE_THRESHOLD,
            recovery_timeout=settings.CB_RECOVERY_TIMEOUT,
        )
        self.qwen_cb = CircuitBreaker(
            name="qwen",
            failure_threshold=settings.CB_FAILURE_THRESHOLD,
            recovery_timeout=settings.CB_RECOVERY_TIMEOUT,
        )

    # ── Primary entry point ──────────────────────────────────

    async def chat(
        self,
        user_id: str,
        message: str,
        language: str = "en",
        session_history: list[dict] | None = None,
    ) -> dict[str, Any]:
        """
        Process a chat message through the full safety + AI pipeline.

        Returns a dict with keys:
          - type: "wellness" | "crisis" | "fallback"
          - response: str | None
          - intent: str
          - crisis_resources: dict | None
          - safety_intercepted: bool
        """
        # ── Step 1: Pre-processing safety scan ────────────────
        safety_result = self.safety.validate_input(message)

        if safety_result.level == SafetyLevel.CRISIS:
            return {
                "type": "crisis",
                "response": None,
                "intent": "crisis",
                "crisis_resources": get_crisis_resources(language),
                "safety_intercepted": True,
                "crisis_hash": safety_result.crisis_hash,
            }

        # Use redacted text if PII was found
        clean_message = (
            safety_result.masked_content
            if safety_result.masked_content
            else message
        )

        # ── Step 2: Retrieve user context from ChromaDB ───────
        context_docs = await self.vector_store.retrieve_context(
            user_id=user_id,
            query=clean_message,
            n_results=4,
        )
        context_str = "\n".join(f"- {d}" for d in context_docs) if context_docs else "No prior context."

        # ── Step 3: Detect intent and route to model ──────────
        intent = self._detect_intent(clean_message, language)
        use_qwen = intent in (QueryIntent.MULTILINGUAL, QueryIntent.COMPLEX) or language != "en"

        # ── Step 4: Generate response ─────────────────────────
        try:
            if use_qwen:
                response_text = await self.qwen_cb.call(
                    self._call_qwen_text,
                    message=clean_message,
                    context=context_str,
                    history=session_history or [],
                )
            else:
                response_text = await self.llama_cb.call(
                    self._call_llama,
                    message=clean_message,
                    context=context_str,
                    history=session_history or [],
                )
        except CircuitOpenError as exc:
            logger.warning("Circuit open, serving fallback: %s", exc)
            return {
                "type": "fallback",
                "response": self._get_fallback(intent),
                "intent": intent.value,
                "crisis_resources": None,
                "safety_intercepted": False,
            }

        # ── Step 5: Post-processing safety scan ───────────────
        output_safety = self.safety.validate_output(response_text)

        if output_safety.level == SafetyLevel.BLOCKED:
            logger.warning("Output blocked — regenerating with strict prompt")
            try:
                if use_qwen:
                    response_text = await self.qwen_cb.call(
                        self._call_qwen_text,
                        message=clean_message,
                        context=context_str,
                        history=[],
                        strict=True,
                    )
                else:
                    response_text = await self.llama_cb.call(
                        self._call_llama,
                        message=clean_message,
                        context=context_str,
                        history=[],
                        strict=True,
                    )
            except Exception:
                response_text = self._get_fallback(intent)

        return {
            "type": "wellness",
            "response": response_text,
            "intent": intent.value,
            "crisis_resources": None,
            "safety_intercepted": safety_result.level == SafetyLevel.PII_FOUND,
        }

    # ── Video analysis ───────────────────────────────────────

    async def analyze_video_frames(
        self,
        frame_urls: list[str],
        analysis_type: str = "meal",
    ) -> dict[str, Any]:
        """
        Analyze video frames with Qwen 3.5 VL.
        analysis_type: "meal" | "exercise"
        """
        prompt = (
            "Analyze these frames as a wellness coach. "
            "For a MEAL: estimate nutritional balance (protein, fiber, carbs, vegetables). "
            "For EXERCISE: assess form and safety. "
            "NEVER diagnose health conditions. NEVER prescribe treatments. "
            f"Analysis type: {analysis_type}. "
            "Respond in JSON: {\"feedback\": \"...\", \"safety_flag\": false, \"nutrition_estimate\": \"...\", \"form_notes\": \"...\"}"
        )

        content = [{"type": "text", "text": prompt}]
        for url in frame_urls[:6]:  # Max 6 frames
            content.append({"type": "image_url", "image_url": {"url": url}})

        try:
            result = await self.qwen_cb.call(self._call_qwen_vision, content=content)
            output_check = self.safety.validate_output(result.get("feedback", ""))
            if output_check.level == SafetyLevel.BLOCKED:
                result["feedback"] = "Great effort! For personalised nutrition or injury advice, consult a professional."
                result["safety_flag"] = True
            return result
        except CircuitOpenError:
            return {
                "feedback": "Video analysis is temporarily unavailable. Please try again shortly.",
                "safety_flag": False,
                "nutrition_estimate": "N/A",
                "form_notes": "N/A",
            }

    # ── Model calls ──────────────────────────────────────────

    async def _call_llama(
        self,
        message: str,
        context: str,
        history: list[dict],
        strict: bool = False,
    ) -> str:
        system = _SYSTEM_STRICT if strict else _SYSTEM_BASE
        messages = [
            {"role": "system", "content": f"{system}\n\nUser wellness context:\n{context}"},
            *history[-6:],  # Keep last 3 turns
            {"role": "user", "content": message},
        ]
        async with httpx.AsyncClient(timeout=30.0) as client:
            resp = await client.post(
                f"{settings.LLAMA4_API_URL}/v1/chat/completions",
                headers={"Authorization": f"Bearer {settings.LLAMA4_API_KEY}"},
                json={
                    "model": settings.LLAMA4_MODEL,
                    "messages": messages,
                    "max_tokens": 600 if not strict else 350,
                    "temperature": 0.75 if not strict else 0.5,
                    "top_p": 0.9,
                },
            )
            resp.raise_for_status()
            return resp.json()["choices"][0]["message"]["content"]

    async def _call_qwen_text(
        self,
        message: str,
        context: str,
        history: list[dict],
        strict: bool = False,
    ) -> str:
        system = (
            (_SYSTEM_STRICT if strict else _SYSTEM_BASE)
            + "\n\n"
            + _SYSTEM_MULTILINGUAL
            + f"\n\nUser wellness context:\n{context}"
        )
        messages = [
            {"role": "system", "content": system},
            *history[-6:],
            {"role": "user", "content": message},
        ]
        async with httpx.AsyncClient(timeout=30.0) as client:
            resp = await client.post(
                f"{settings.QWEN_API_URL}/v1/chat/completions",
                headers={"Authorization": f"Bearer {settings.QWEN_API_KEY}"},
                json={
                    "model": settings.QWEN_TEXT_MODEL,
                    "messages": messages,
                    "max_tokens": 600,
                    "temperature": 0.7,
                },
            )
            resp.raise_for_status()
            return resp.json()["choices"][0]["message"]["content"]

    async def _call_qwen_vision(self, content: list[dict]) -> dict:
        async with httpx.AsyncClient(timeout=60.0) as client:
            resp = await client.post(
                f"{settings.QWEN_API_URL}/v1/chat/completions",
                headers={"Authorization": f"Bearer {settings.QWEN_API_KEY}"},
                json={
                    "model": settings.QWEN_VL_MODEL,
                    "messages": [{"role": "user", "content": content}],
                    "max_tokens": 400,
                    "temperature": 0.3,
                    "response_format": {"type": "json_object"},
                },
            )
            resp.raise_for_status()
            import json
            raw = resp.json()["choices"][0]["message"]["content"]
            try:
                return json.loads(raw)
            except json.JSONDecodeError:
                return {"feedback": raw, "safety_flag": False, "nutrition_estimate": "N/A", "form_notes": "N/A"}

    # ── Intent detection ─────────────────────────────────────

    def _detect_intent(self, text: str, language: str) -> QueryIntent:
        if language not in ("en", ""):
            return QueryIntent.MULTILINGUAL

        t = text.lower()
        if any(k in t for k in ("food", "eat", "diet", "meal", "calori", "protein", "carb", "vegetable", "fruit")):
            return QueryIntent.NUTRITION
        if any(k in t for k in ("meditat", "breath", "mindful", "stress", "anxi", "calm", "relax", "panic")):
            return QueryIntent.MINDFULNESS
        if any(k in t for k in ("exercis", "workout", "run", "gym", "squat", "push-up", "lift", "walk", "yoga")):
            return QueryIntent.EXERCISE
        if any(k in t for k in ("sleep", "insomnia", "tired", "rest", "nap", "bedtime", "wake")):
            return QueryIntent.SLEEP
        if len(text) > 400:
            return QueryIntent.COMPLEX
        return QueryIntent.GENERAL

    def _get_fallback(self, intent: QueryIntent) -> str:
        mapping = {
            QueryIntent.NUTRITION: "nutrition",
            QueryIntent.EXERCISE: "exercise",
            QueryIntent.MINDFULNESS: "stress",
            QueryIntent.SLEEP: "sleep",
        }
        key = mapping.get(intent, "general")
        return _FALLBACK_TIPS[key]


# ── Singleton ────────────────────────────────────────────────

_orchestrator: AIOrchestrator | None = None


def get_orchestrator() -> AIOrchestrator:
    global _orchestrator
    if _orchestrator is None:
        _orchestrator = AIOrchestrator()
    return _orchestrator
