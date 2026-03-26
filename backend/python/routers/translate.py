"""
Myanmar translation router — powered by facebook/nllb-200-distilled-600M.

Endpoints
---------
GET  /ai/translate/languages          → list all supported language codes
POST /ai/translate                    → single-target translation
POST /ai/translate/multi              → fan-out to multiple targets
GET  /ai/translate/model/status       → check whether model is warm
"""

from __future__ import annotations

import json
import logging

from fastapi import APIRouter, HTTPException
from fastapi.responses import StreamingResponse
from pydantic import BaseModel, Field, field_validator

from agents.nllb_agent import (
    LANG_CODE_TO_NAME,
    SUPPORTED_LANGUAGES,
    is_model_loaded,
    translate_text,
    translate_to_multiple,
)

log = logging.getLogger(__name__)
router = APIRouter()


# ── Request / Response schemas ────────────────────────────────────────────────

VALID_CODES = set(SUPPORTED_LANGUAGES.values())


class TranslateRequest(BaseModel):
    text: str = Field(..., min_length=1, max_length=2000)
    source_lang: str = Field("mya_Mymr", description="NLLB-200 language code")
    target_lang: str = Field("eng_Latn", description="NLLB-200 language code")

    @field_validator("source_lang", "target_lang")
    @classmethod
    def _valid_lang(cls, v: str) -> str:
        if v not in VALID_CODES:
            raise ValueError(f"Unsupported language code: {v}")
        return v


class MultiTranslateRequest(BaseModel):
    text: str = Field(..., min_length=1, max_length=2000)
    source_lang: str = Field("mya_Mymr")
    target_langs: list[str] = Field(..., min_length=1, max_length=16)

    @field_validator("source_lang")
    @classmethod
    def _valid_source(cls, v: str) -> str:
        if v not in VALID_CODES:
            raise ValueError(f"Unsupported language code: {v}")
        return v

    @field_validator("target_langs")
    @classmethod
    def _valid_targets(cls, codes: list[str]) -> list[str]:
        bad = [c for c in codes if c not in VALID_CODES]
        if bad:
            raise ValueError(f"Unsupported language codes: {bad}")
        return codes


class TranslateResponse(BaseModel):
    source_text: str
    translated_text: str
    source_lang: str
    source_lang_name: str
    target_lang: str
    target_lang_name: str


class MultiTranslateResponse(BaseModel):
    source_text: str
    source_lang: str
    translations: dict[str, str]  # lang_code -> translated text
    translation_names: dict[str, str]  # lang_code -> display name


# ── Routes ────────────────────────────────────────────────────────────────────

@router.get("/translate/languages")
async def list_languages():
    """Return all supported languages with their NLLB-200 codes."""
    return {
        "languages": [
            {"name": name, "code": code}
            for name, code in SUPPORTED_LANGUAGES.items()
        ]
    }


@router.get("/translate/model/status")
async def model_status():
    """Check whether the NLLB model is already loaded into memory."""
    return {"loaded": is_model_loaded()}


@router.post("/translate", response_model=TranslateResponse)
async def translate(req: TranslateRequest):
    """Translate text from source_lang to target_lang."""
    if req.source_lang == req.target_lang:
        raise HTTPException(status_code=400, detail="Source and target language must differ")

    translated = await translate_text(req.text, req.source_lang, req.target_lang)
    return TranslateResponse(
        source_text=req.text,
        translated_text=translated,
        source_lang=req.source_lang,
        source_lang_name=LANG_CODE_TO_NAME.get(req.source_lang, req.source_lang),
        target_lang=req.target_lang,
        target_lang_name=LANG_CODE_TO_NAME.get(req.target_lang, req.target_lang),
    )


@router.post("/translate/multi", response_model=MultiTranslateResponse)
async def translate_multi(req: MultiTranslateRequest):
    """Translate text from source_lang into multiple target languages concurrently."""
    target_langs = [t for t in req.target_langs if t != req.source_lang]
    if not target_langs:
        raise HTTPException(status_code=400, detail="No valid target languages (excluding source)")

    translations = await translate_to_multiple(req.text, req.source_lang, target_langs)
    return MultiTranslateResponse(
        source_text=req.text,
        source_lang=req.source_lang,
        translations=translations,
        translation_names={code: LANG_CODE_TO_NAME.get(code, code) for code in translations},
    )


@router.post("/translate/stream")
async def translate_stream(req: TranslateRequest):
    """
    Server-Sent Events stream for real-time translation feedback.
    Emits: loading → translating → done (with result).
    """
    if req.source_lang == req.target_lang:
        raise HTTPException(status_code=400, detail="Source and target language must differ")

    async def _generate():
        yield _sse({"status": "loading_model", "loaded": is_model_loaded()})
        yield _sse({"status": "translating"})
        try:
            translated = await translate_text(req.text, req.source_lang, req.target_lang)
            yield _sse({
                "status": "done",
                "source_text": req.text,
                "translated_text": translated,
                "source_lang": req.source_lang,
                "target_lang": req.target_lang,
                "target_lang_name": LANG_CODE_TO_NAME.get(req.target_lang, req.target_lang),
            })
        except Exception as exc:
            log.exception("Stream translation failed")
            yield _sse({"status": "error", "detail": str(exc)})

    return StreamingResponse(_generate(), media_type="text/event-stream")


# ── Helpers ───────────────────────────────────────────────────────────────────

def _sse(payload: dict) -> str:
    return f"data: {json.dumps(payload)}\n\n"
