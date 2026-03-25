"""
Item classification service.

Two-stage pipeline:
1. Embedding-based zero-shot classification using cosine similarity against
   category centroid embeddings (fast, no model training required).
2. Claude reasoning-based classification for ambiguous items or when
   high-confidence assignment is needed.

Categories are defined per domain (cargo vs. inventory) and include
subcategories aligned with HS code chapters.
"""
from __future__ import annotations

import json
import os
from typing import Any

import numpy as np

from .vector_store import embed_text
from .reasoning_cache import reason_about_classification

# ── Category taxonomy ─────────────────────────────────────────────────────────

CARGO_CATEGORIES = {
    "Electronics": [
        "Consumer electronics", "Industrial electronics", "Semiconductors",
        "Computers & peripherals", "Telecommunications equipment",
    ],
    "Apparel & Textiles": [
        "Clothing & accessories", "Footwear", "Fabrics & yarn",
        "Home textiles", "Industrial textiles",
    ],
    "Chemicals": [
        "Industrial chemicals", "Pharmaceutical chemicals",
        "Agricultural chemicals", "Plastics & polymers", "Paints & coatings",
    ],
    "Machinery": [
        "Industrial machinery", "Construction equipment",
        "Agricultural machinery", "HVAC & refrigeration", "Precision instruments",
    ],
    "Food & Beverage": [
        "Fresh produce", "Processed foods", "Beverages",
        "Frozen foods", "Dry goods & grains",
    ],
    "Pharmaceuticals": [
        "Medicines & vaccines", "Medical devices",
        "Diagnostics", "Biologics",
    ],
    "Automotive": [
        "Vehicles", "Auto parts & accessories",
        "Tyres & rubber", "Lubricants & fluids",
    ],
    "Raw Materials": [
        "Metals & alloys", "Minerals & ores",
        "Timber & wood products", "Paper & pulp",
    ],
    "Hazardous Materials": [
        "Flammables", "Explosives", "Toxic substances",
        "Radioactive materials", "Corrosives",
    ],
    "Other": ["General cargo", "Samples", "Personal effects", "Unclassified"],
}


async def classify_item(
    description: str,
    sku: str | None = None,
    hs_code: str | None = None,
    use_reasoning: bool = False,
) -> dict[str, Any]:
    """
    Classify a single cargo/inventory item.

    Returns:
        {category, sub_category, confidence, method, hs_code_suggestion}
    """
    # Stage 1: HS code lookup (instant if provided)
    if hs_code:
        cat, sub = _hs_code_to_category(hs_code)
        if cat:
            return {
                "category": cat,
                "sub_category": sub,
                "confidence": 0.95,
                "method": "hs_code",
                "hs_code_suggestion": hs_code,
            }

    # Stage 2: Embedding-based similarity
    emb_result = await _embed_classify(description)

    if emb_result["confidence"] >= 0.75 and not use_reasoning:
        return emb_result

    # Stage 3: Claude reasoning for low-confidence or explicit request
    if use_reasoning or emb_result["confidence"] < 0.6:
        claude_result = await _claude_classify(description, sku, hs_code)
        if claude_result:
            return claude_result

    return emb_result


async def batch_classify(
    items: list[dict[str, Any]],
) -> list[dict[str, Any]]:
    """
    Classify a batch of items. Uses Claude reasoning for the whole batch
    to amortise prompt-cache benefits.

    Each item dict should have: description, sku (optional), hs_code (optional).
    """
    results = []
    # First pass: fast embedding classification
    unresolved = []
    for item in items:
        result = await classify_item(
            item.get("description", ""),
            item.get("sku"),
            item.get("hs_code"),
            use_reasoning=False,
        )
        result["item_id"] = item.get("id")
        if result["confidence"] < 0.7:
            unresolved.append(item)
        results.append(result)

    # Second pass: Claude batch reasoning for unresolved items
    if unresolved:
        claude_result = await reason_about_classification(unresolved)
        # Parse and merge Claude results
        try:
            parsed = json.loads(claude_result.content)
            if isinstance(parsed, list):
                for cr in parsed:
                    item_id = cr.get("id") or cr.get("item_id")
                    for r in results:
                        if r.get("item_id") == item_id:
                            r.update({
                                "category": cr.get("category", r["category"]),
                                "sub_category": cr.get("sub_category", r["sub_category"]),
                                "confidence": max(r["confidence"], cr.get("confidence", 0)),
                                "method": "claude_batch",
                            })
        except Exception:
            pass  # Keep embedding results on parse failure

    return results


# ── Internal helpers ──────────────────────────────────────────────────────────

async def _embed_classify(description: str) -> dict[str, Any]:
    """Classify using cosine similarity to category prototype embeddings."""
    # Category prototypes are constructed from category + subcategory names
    best_cat = "Other"
    best_sub = "Unclassified"
    best_score = 0.0

    item_emb = np.array(await embed_text(description))
    if np.all(item_emb == 0):
        # Demo mode — rule-based fallback
        return _rule_based_classify(description)

    for cat, subs in CARGO_CATEGORIES.items():
        for sub in subs:
            prototype_text = f"{cat}: {sub} — {description[:100]}"
            proto_emb = np.array(await embed_text(prototype_text))
            if np.all(proto_emb == 0):
                continue
            score = float(
                np.dot(item_emb, proto_emb)
                / (np.linalg.norm(item_emb) * np.linalg.norm(proto_emb) + 1e-9)
            )
            if score > best_score:
                best_score = score
                best_cat = cat
                best_sub = sub

    return {
        "category": best_cat,
        "sub_category": best_sub,
        "confidence": min(best_score, 0.99),
        "method": "embedding",
        "hs_code_suggestion": None,
    }


def _rule_based_classify(description: str) -> dict[str, Any]:
    """Simple keyword-based fallback for demo mode."""
    desc_lower = description.lower()
    rules = [
        (["phone", "laptop", "computer", "chip", "circuit", "electronic"], "Electronics", "Consumer electronics"),
        (["shirt", "dress", "cloth", "fabric", "textile", "shoe", "boot"], "Apparel & Textiles", "Clothing & accessories"),
        (["chemical", "acid", "solvent", "polymer", "resin"], "Chemicals", "Industrial chemicals"),
        (["machine", "engine", "pump", "motor", "compressor"], "Machinery", "Industrial machinery"),
        (["food", "grain", "meat", "fruit", "vegetable", "beverage"], "Food & Beverage", "Processed foods"),
        (["medicine", "drug", "pharmaceutical", "vaccine", "medical"], "Pharmaceuticals", "Medicines & vaccines"),
        (["car", "vehicle", "auto", "tyre", "brake", "engine part"], "Automotive", "Auto parts & accessories"),
        (["metal", "steel", "aluminium", "copper", "ore", "mineral"], "Raw Materials", "Metals & alloys"),
        (["explosive", "flammable", "toxic", "hazmat", "dangerous"], "Hazardous Materials", "Toxic substances"),
    ]
    for keywords, cat, sub in rules:
        if any(kw in desc_lower for kw in keywords):
            return {"category": cat, "sub_category": sub, "confidence": 0.65,
                    "method": "rule_based", "hs_code_suggestion": None}
    return {"category": "Other", "sub_category": "General cargo", "confidence": 0.4,
            "method": "rule_based", "hs_code_suggestion": None}


async def _claude_classify(
    description: str,
    sku: str | None,
    hs_code: str | None,
) -> dict[str, Any] | None:
    """Use Claude to classify a single ambiguous item."""
    if not os.environ.get("ANTHROPIC_API_KEY"):
        return None

    items = [{"description": description, "sku": sku or "", "hs_code": hs_code or ""}]
    result = await reason_about_classification(items)

    try:
        parsed = json.loads(result.content)
        if isinstance(parsed, list) and parsed:
            parsed = parsed[0]
        if isinstance(parsed, dict):
            return {
                "category": parsed.get("category", "Other"),
                "sub_category": parsed.get("sub_category", "General cargo"),
                "confidence": parsed.get("confidence", 0.8),
                "method": "claude",
                "hs_code_suggestion": parsed.get("hs_code_suggestion"),
            }
    except Exception:
        pass
    return None


def _hs_code_to_category(hs_code: str) -> tuple[str | None, str | None]:
    """Map the first 2 HS code digits to a category."""
    chapter = hs_code[:2].lstrip("0") or "0"
    try:
        ch = int(chapter)
    except ValueError:
        return None, None

    mapping = {
        range(1, 6):    ("Food & Beverage", "Fresh produce"),
        range(6, 15):   ("Food & Beverage", "Processed foods"),
        range(15, 25):  ("Food & Beverage", "Dry goods & grains"),
        range(25, 28):  ("Raw Materials", "Minerals & ores"),
        range(28, 39):  ("Chemicals", "Industrial chemicals"),
        range(39, 41):  ("Chemicals", "Plastics & polymers"),
        range(41, 44):  ("Raw Materials", "Timber & wood products"),
        range(50, 64):  ("Apparel & Textiles", "Clothing & accessories"),
        range(64, 68):  ("Apparel & Textiles", "Footwear"),
        range(72, 84):  ("Raw Materials", "Metals & alloys"),
        range(84, 86):  ("Machinery", "Industrial machinery"),
        range(86, 90):  ("Automotive", "Vehicles"),
        range(90, 93):  ("Electronics", "Precision instruments"),
        range(84, 86):  ("Machinery", "Industrial machinery"),
        range(85, 86):  ("Electronics", "Industrial electronics"),
    }
    for rng, (cat, sub) in mapping.items():
        if ch in rng:
            return cat, sub
    return None, None
