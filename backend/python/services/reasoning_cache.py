"""
Claude reasoning service with prompt caching.

Uses Anthropic's cache_control feature to cache large system prompts so that
repeated reasoning calls (e.g. defect analysis, route optimisation, anomaly
explanation) do not re-tokenise the same context on every request.

Extended thinking (budget_tokens) is enabled for complex multi-step reasoning.
"""
from __future__ import annotations

import hashlib
import json
import os
import time
from dataclasses import dataclass, field
from typing import Any

import anthropic

_client = anthropic.AsyncAnthropic(api_key=os.environ.get("ANTHROPIC_API_KEY", ""))

MODEL = "claude-opus-4-6"

# ── System prompts cached with cache_control ──────────────────────────────────

CARGO_SYSTEM_PROMPT = """
You are CargoTrack AI, an expert logistics and supply-chain analyst with deep
knowledge of:
- International shipping, customs, and trade regulations (Incoterms 2020)
- Cargo classification (HS codes, hazmat classes, temperature-sensitive goods)
- Defect analysis for physical goods (damage, contamination, mislabelling)
- Inventory management (ABC analysis, EOQ, safety stock, reorder points)
- Route optimisation and carrier selection
- Anomaly detection in tracking data (delays, deviations, missing scans)
- Quality control processes and ISO 9001 compliance
- Multi-modal transport (sea, air, rail, road)

When analysing defects:
1. Identify defect type, probable cause, and severity
2. Recommend immediate action (quarantine, rework, disposal, re-inspection)
3. Suggest root-cause prevention measures
4. Estimate financial impact where possible

When analysing shipment anomalies:
1. Compare against historical baselines for the route and carrier
2. Identify risk factors (weather, port congestion, customs flags)
3. Recommend proactive communication steps
4. Provide probability estimate for on-time delivery

Always be concise, structured, and actionable. Use bullet points for
recommendations.
""".strip()

INVENTORY_SYSTEM_PROMPT = """
You are CargoTrack AI, an expert inventory and warehouse management analyst.
You specialise in:
- Demand forecasting and safety stock calculations
- ABC/XYZ inventory classification
- Cycle-count strategies and variance analysis
- Bin/shelf optimisation and slotting
- Replenishment policy design (min/max, reorder-point, JIT)
- Multi-location inventory balancing
- Slow-moving and obsolete (SLOB) stock identification

Provide structured, data-driven recommendations. When stock levels are
critical, prioritise urgency and business continuity in your advice.
""".strip()


@dataclass
class ReasoningResult:
    content: str
    thinking: str | None
    model: str
    cache_hit: bool
    input_tokens: int
    output_tokens: int
    cache_read_tokens: int
    cache_write_tokens: int
    latency_ms: int
    metadata: dict[str, Any] = field(default_factory=dict)


async def reason_about_defect(
    defect_info: dict[str, Any],
    budget_tokens: int = 8000,
) -> ReasoningResult:
    """
    Run Claude extended thinking on a defect detection result.
    The large system prompt is cache_control'd so subsequent calls are fast.
    """
    user_message = json.dumps({
        "task": "defect_analysis",
        "defect": defect_info,
    }, indent=2)

    return await _call_claude(
        system_prompt=CARGO_SYSTEM_PROMPT,
        user_message=user_message,
        budget_tokens=budget_tokens,
        query_type="defect_analysis",
    )


async def reason_about_shipment(
    shipment_data: dict[str, Any],
    budget_tokens: int = 6000,
) -> ReasoningResult:
    """Analyse a shipment for anomalies, delays, and risk factors."""
    user_message = json.dumps({
        "task": "shipment_analysis",
        "shipment": shipment_data,
    }, indent=2)

    return await _call_claude(
        system_prompt=CARGO_SYSTEM_PROMPT,
        user_message=user_message,
        budget_tokens=budget_tokens,
        query_type="shipment_analysis",
    )


async def reason_about_inventory(
    inventory_data: dict[str, Any],
    budget_tokens: int = 5000,
) -> ReasoningResult:
    """Generate inventory optimisation recommendations."""
    user_message = json.dumps({
        "task": "inventory_optimisation",
        "inventory": inventory_data,
    }, indent=2)

    return await _call_claude(
        system_prompt=INVENTORY_SYSTEM_PROMPT,
        user_message=user_message,
        budget_tokens=budget_tokens,
        query_type="inventory_optimisation",
    )


async def reason_about_classification(
    items: list[dict[str, Any]],
    budget_tokens: int = 4000,
) -> ReasoningResult:
    """Classify and categorise a list of cargo/inventory items."""
    user_message = json.dumps({
        "task": "item_classification",
        "items": items[:50],  # cap at 50 items per call
    }, indent=2)

    return await _call_claude(
        system_prompt=CARGO_SYSTEM_PROMPT,
        user_message=user_message,
        budget_tokens=budget_tokens,
        query_type="item_classification",
    )


# ── Core Claude call with prompt caching + extended thinking ──────────────────

async def _call_claude(
    system_prompt: str,
    user_message: str,
    budget_tokens: int,
    query_type: str,
) -> ReasoningResult:
    """
    Call Claude with:
    - cache_control on the system prompt (ephemeral cache, up to 5 min TTL)
    - Extended thinking enabled (budget_tokens controls depth)
    - Streaming disabled for simplicity (use streaming for UI feedback)
    """
    t0 = time.monotonic()

    # Check if API key is available
    if not os.environ.get("ANTHROPIC_API_KEY"):
        return ReasoningResult(
            content="[Demo mode — ANTHROPIC_API_KEY not set]",
            thinking=None,
            model=MODEL,
            cache_hit=False,
            input_tokens=0,
            output_tokens=0,
            cache_read_tokens=0,
            cache_write_tokens=0,
            latency_ms=0,
        )

    response = await _client.messages.create(
        model=MODEL,
        max_tokens=budget_tokens + 4096,  # thinking + output
        thinking={
            "type": "enabled",
            "budget_tokens": budget_tokens,
        },
        system=[
            {
                "type": "text",
                "text": system_prompt,
                # Prompt caching: Anthropic caches this block for ~5 minutes.
                # On cache hit, cache_read_input_tokens > 0 in usage.
                "cache_control": {"type": "ephemeral"},
            }
        ],
        messages=[
            {"role": "user", "content": user_message}
        ],
    )

    latency_ms = int((time.monotonic() - t0) * 1000)

    # Extract thinking and text blocks
    thinking_text: str | None = None
    answer_text = ""
    for block in response.content:
        if block.type == "thinking":
            thinking_text = block.thinking
        elif block.type == "text":
            answer_text += block.text

    usage = response.usage
    cache_read = getattr(usage, "cache_read_input_tokens", 0) or 0
    cache_write = getattr(usage, "cache_creation_input_tokens", 0) or 0

    return ReasoningResult(
        content=answer_text,
        thinking=thinking_text,
        model=response.model,
        cache_hit=cache_read > 0,
        input_tokens=usage.input_tokens,
        output_tokens=usage.output_tokens,
        cache_read_tokens=cache_read,
        cache_write_tokens=cache_write,
        latency_ms=latency_ms,
        metadata={"query_type": query_type, "stop_reason": response.stop_reason},
    )


def cache_key(system_prompt: str, query_type: str) -> str:
    """Deterministic key for tracking cache entries in the DB."""
    h = hashlib.sha256(f"{MODEL}:{query_type}:{system_prompt[:200]}".encode()).hexdigest()
    return h[:32]
