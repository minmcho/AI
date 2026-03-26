"""
NLLB-200 open-source translation agent.

Uses facebook/nllb-200-distilled-600M for accurate Myanmar ↔ multi-language
translation without any cloud API dependency.

Model is lazy-loaded on first request and cached in memory.
GPU is used automatically when available, otherwise CPU.
"""

from __future__ import annotations

import asyncio
import logging
from concurrent.futures import ThreadPoolExecutor
from typing import Optional

import torch
from transformers import AutoModelForSeq2SeqLM, AutoTokenizer

log = logging.getLogger(__name__)

# ── Model config ──────────────────────────────────────────────────────────────

MODEL_NAME = "facebook/nllb-200-distilled-600M"

# NLLB-200 BCP-47-style language codes  (display name -> NLLB token)
SUPPORTED_LANGUAGES: dict[str, str] = {
    "Myanmar": "mya_Mymr",
    "English": "eng_Latn",
    "Chinese (Simplified)": "zho_Hans",
    "Chinese (Traditional)": "zho_Hant",
    "Thai": "tha_Thai",
    "Japanese": "jpn_Jpan",
    "Korean": "kor_Hang",
    "French": "fra_Latn",
    "Spanish": "spa_Latn",
    "German": "deu_Latn",
    "Portuguese": "por_Latn",
    "Arabic": "arb_Arab",
    "Hindi": "hin_Deva",
    "Vietnamese": "vie_Latn",
    "Indonesian": "ind_Latn",
    "Russian": "rus_Cyrl",
    "Malay": "zsm_Latn",
}

# Reverse lookup: NLLB code -> display name
LANG_CODE_TO_NAME: dict[str, str] = {v: k for k, v in SUPPORTED_LANGUAGES.items()}

# ── Singleton model state ─────────────────────────────────────────────────────

_tokenizer: Optional[AutoTokenizer] = None
_model: Optional[AutoModelForSeq2SeqLM] = None
_device: Optional[str] = None
_executor = ThreadPoolExecutor(max_workers=2)


def _load_model() -> tuple[AutoTokenizer, AutoModelForSeq2SeqLM, str]:
    global _tokenizer, _model, _device
    if _model is not None:
        return _tokenizer, _model, _device

    log.info("Loading NLLB-200 model: %s", MODEL_NAME)
    device = "cuda" if torch.cuda.is_available() else "cpu"
    dtype = torch.float16 if device == "cuda" else torch.float32

    tokenizer = AutoTokenizer.from_pretrained(MODEL_NAME)
    model = AutoModelForSeq2SeqLM.from_pretrained(MODEL_NAME, torch_dtype=dtype).to(device)
    model.eval()

    _tokenizer, _model, _device = tokenizer, model, device
    log.info("NLLB-200 loaded on %s", device)
    return tokenizer, model, device


# ── Synchronous translation (runs in thread pool) ─────────────────────────────

def _translate_sync(
    text: str,
    source_lang: str,
    target_lang: str,
    max_new_tokens: int = 512,
    num_beams: int = 4,
) -> str:
    tokenizer, model, device = _load_model()

    tokenizer.src_lang = source_lang
    inputs = tokenizer(
        text,
        return_tensors="pt",
        padding=True,
        truncation=True,
        max_length=512,
    ).to(device)

    forced_bos_token_id = tokenizer.convert_tokens_to_ids(target_lang)

    with torch.no_grad():
        output_ids = model.generate(
            **inputs,
            forced_bos_token_id=forced_bos_token_id,
            max_new_tokens=max_new_tokens,
            num_beams=num_beams,
            early_stopping=True,
            no_repeat_ngram_size=3,
        )

    return tokenizer.decode(output_ids[0], skip_special_tokens=True)


# ── Async wrappers ────────────────────────────────────────────────────────────

async def translate_text(
    text: str,
    source_lang: str = "mya_Mymr",
    target_lang: str = "eng_Latn",
    max_new_tokens: int = 512,
    num_beams: int = 4,
) -> str:
    """Translate *text* from *source_lang* to *target_lang* asynchronously."""
    loop = asyncio.get_event_loop()
    return await loop.run_in_executor(
        _executor,
        _translate_sync,
        text,
        source_lang,
        target_lang,
        max_new_tokens,
        num_beams,
    )


async def translate_to_multiple(
    text: str,
    source_lang: str,
    target_langs: list[str],
) -> dict[str, str]:
    """Translate *text* into every language in *target_langs* concurrently."""
    tasks = {
        lang: asyncio.create_task(translate_text(text, source_lang, lang))
        for lang in target_langs
    }
    results: dict[str, str] = {}
    for lang, task in tasks.items():
        try:
            results[lang] = await task
        except Exception as exc:
            log.warning("Translation to %s failed: %s", lang, exc)
            results[lang] = ""
    return results


def is_model_loaded() -> bool:
    return _model is not None
