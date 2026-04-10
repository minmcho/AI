"""
VitalPath Safety Validator
==========================
Pre- and post-processing safety checks for all AI inputs/outputs.

Safety hierarchy (highest → lowest priority):
  1. CRISIS      — self-harm / emergency keywords → immediate escalation
  2. BLOCKED     — medical diagnosis / treatment claims in AI output → regenerate
  3. PII_FOUND   — personal identifiers in user input → redact before forwarding
  4. SAFE        — no issues detected
"""
from __future__ import annotations

import hashlib
import logging
import re
from dataclasses import dataclass, field
from enum import Enum
from typing import Optional

logger = logging.getLogger(__name__)


class SafetyLevel(str, Enum):
    SAFE = "safe"
    PII_FOUND = "pii_found"
    WARNING = "warning"
    BLOCKED = "blocked"
    CRISIS = "crisis"


@dataclass
class SafetyResult:
    level: SafetyLevel
    reason: Optional[str] = None
    masked_content: Optional[str] = None
    crisis_hash: Optional[str] = None          # SHA-256 of original crisis text (audit only)
    matched_pattern: Optional[str] = None


# ─────────────────────────── Pattern sets ───────────────────

_CRISIS_PATTERNS = [
    # Self-harm / suicide
    r"\b(suicide|suicidal|kill\s+myself|end\s+my\s+life|take\s+my\s+life)\b",
    r"\b(hurt\s+myself|harm\s+myself|self[‐\-–—]harm|cut\s+myself)\b",
    r"\b(want\s+to\s+die|don'?t\s+want\s+to\s+(live|be\s+alive|exist))\b",
    r"\b(overdose|od'?ing|od\s+on|too\s+many\s+pills)\b",
    # Medical emergencies
    r"\b(chest\s+pain|heart\s+attack|can'?t\s+breathe|difficulty\s+breathing)\b",
    r"\b(stroke|seizure|unconscious|passed\s+out|fainted)\b",
]

_MEDICAL_CLAIM_PATTERNS = [
    # Diagnosis
    r"\b(you\s+have|you\s+are\s+suffering\s+from|you\s+are\s+diagnosed)\b",
    r"\b(symptoms\s+indicate|this\s+(is|looks\s+like)\s+a\s+(disease|condition|disorder))\b",
    # Treatment / prescribing
    r"\b(prescribe|take\s+this\s+medication|drug\s+dosage|clinical\s+dose)\b",
    r"\b(cure|treat(ment)?\s+for\s+your|heal\s+your\s+(disease|condition))\b",
    r"\b(fda[‐\-–—]?approved\s+for|medically\s+proven\s+to)\b",
    # Direct medical advice
    r"\b(stop\s+(taking|your)\s+medication|reduce\s+your\s+dose)\b",
    r"\b(you\s+(should|must|need\s+to)\s+(take|use|inject)\s+[a-z]+\s*(mg|ml|units?))\b",
]

_PII_PATTERNS = [
    (r"\b\d{3}[-.\s]?\d{3}[-.\s]?\d{4}\b", "[PHONE REDACTED]"),
    (r"\b[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}\b", "[EMAIL REDACTED]"),
    (r"\b\d{3}-\d{2}-\d{4}\b", "[SSN REDACTED]"),
    (r"\b\d{16}\b", "[CARD REDACTED]"),  # Credit card (simplified)
    (r"\b(passport|id\s+no\.?)\s*:?\s*[A-Z0-9]{6,12}\b", "[ID REDACTED]"),
]

# ─────────────────────────── Validator ──────────────────────

class SafetyValidator:
    """
    Stateless, re-usable safety validator.
    Compile regexes once at init for performance.
    """

    def __init__(self) -> None:
        self._crisis_re = [
            re.compile(p, re.IGNORECASE | re.UNICODE) for p in _CRISIS_PATTERNS
        ]
        self._medical_re = [
            re.compile(p, re.IGNORECASE | re.UNICODE) for p in _MEDICAL_CLAIM_PATTERNS
        ]
        self._pii_re = [
            (re.compile(p, re.IGNORECASE), replacement)
            for p, replacement in _PII_PATTERNS
        ]

    # ── Public API ───────────────────────────────────────────

    def validate_input(self, text: str) -> SafetyResult:
        """
        Scan user input before forwarding to AI.
        Returns CRISIS immediately if detected (short-circuit).
        """
        # 1. Crisis check — highest priority
        for pattern in self._crisis_re:
            match = pattern.search(text)
            if match:
                crisis_hash = hashlib.sha256(text.encode("utf-8")).hexdigest()
                logger.critical(
                    "CRISIS detected | pattern=%s | hash=%s", pattern.pattern[:40], crisis_hash
                )
                return SafetyResult(
                    level=SafetyLevel.CRISIS,
                    reason="Crisis keyword detected",
                    crisis_hash=crisis_hash,
                    matched_pattern=match.group(0),
                )

        # 2. PII redaction
        masked, pii_found = self._redact_pii(text)
        if pii_found:
            return SafetyResult(
                level=SafetyLevel.PII_FOUND,
                reason="PII detected and redacted",
                masked_content=masked,
            )

        return SafetyResult(level=SafetyLevel.SAFE, masked_content=text)

    def validate_output(self, text: str) -> SafetyResult:
        """
        Scan AI-generated output before returning to user.
        Blocks responses containing prohibited medical claims.
        """
        for pattern in self._medical_re:
            match = pattern.search(text)
            if match:
                logger.warning(
                    "Medical claim blocked | pattern=%s | match=%r",
                    pattern.pattern[:40],
                    match.group(0),
                )
                return SafetyResult(
                    level=SafetyLevel.BLOCKED,
                    reason="Prohibited medical claim detected in AI output",
                    matched_pattern=match.group(0),
                )
        return SafetyResult(level=SafetyLevel.SAFE)

    def contains_crisis(self, text: str) -> bool:
        """Quick boolean check used by streaming interceptors."""
        return any(p.search(text) for p in self._crisis_re)

    # ── Helpers ──────────────────────────────────────────────

    def _redact_pii(self, text: str) -> tuple[str, bool]:
        found = False
        for pattern, replacement in self._pii_re:
            new_text, count = pattern.subn(replacement, text)
            if count > 0:
                text = new_text
                found = True
        return text, found


# ─────────────────── Crisis resources ───────────────────────

CRISIS_RESOURCES: dict[str, dict] = {
    "en": {"country": "US", "hotline": "988", "name": "Suicide & Crisis Lifeline", "url": "https://988lifeline.org"},
    "my": {"country": "Myanmar", "hotline": "09-256-778-603", "name": "Myanmar Mental Health Helpline", "url": ""},
    "th": {"country": "Thailand", "hotline": "1323", "name": "Department of Mental Health Hotline", "url": ""},
    "ja": {"country": "Japan", "hotline": "0120-783-556", "name": "Inochi-no-Denwa", "url": "https://www.inochi-no-denwa.jp"},
    "ko": {"country": "Korea", "hotline": "1393", "name": "Korea Suicide Prevention Hotline", "url": ""},
    "zh": {"country": "China", "hotline": "400-161-9995", "name": "Beijing Suicide Research & Prevention Center", "url": ""},
}


def get_crisis_resources(language: str) -> dict:
    return CRISIS_RESOURCES.get(language, CRISIS_RESOURCES["en"])
