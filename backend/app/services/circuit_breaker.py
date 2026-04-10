"""
Async Circuit Breaker — protects AI service calls.

States:
  CLOSED   — normal operation, calls pass through.
  OPEN     — too many failures; all calls raise CircuitOpenError immediately.
  HALF_OPEN — one probe call allowed to test recovery.
"""
from __future__ import annotations

import asyncio
import logging
import time
from enum import Enum
from typing import Any, Callable, Coroutine, TypeVar

logger = logging.getLogger(__name__)

T = TypeVar("T")


class CircuitState(str, Enum):
    CLOSED = "closed"
    OPEN = "open"
    HALF_OPEN = "half_open"


class CircuitOpenError(Exception):
    """Raised when the circuit breaker is OPEN and rejects the call."""


class CircuitBreaker:
    """
    Thread-safe async circuit breaker.

    Usage::

        cb = CircuitBreaker(name="llama4", failure_threshold=5, recovery_timeout=60)

        async def fetch():
            return await cb.call(llama_client.complete, prompt=prompt)
    """

    def __init__(
        self,
        name: str,
        failure_threshold: int = 5,
        recovery_timeout: float = 60.0,
        expected_exception: type[Exception] = Exception,
    ) -> None:
        self.name = name
        self.failure_threshold = failure_threshold
        self.recovery_timeout = recovery_timeout
        self.expected_exception = expected_exception

        self._state = CircuitState.CLOSED
        self._failure_count = 0
        self._last_failure_time: float | None = None
        self._lock = asyncio.Lock()

    # ── Public interface ─────────────────────────────────────

    @property
    def state(self) -> CircuitState:
        return self._state

    @property
    def is_open(self) -> bool:
        return self._state == CircuitState.OPEN

    async def call(
        self,
        func: Callable[..., Coroutine[Any, Any, T]],
        *args: Any,
        **kwargs: Any,
    ) -> T:
        await self._before_call()
        try:
            result = await func(*args, **kwargs)
            await self._on_success()
            return result
        except self.expected_exception as exc:
            await self._on_failure()
            raise

    async def reset(self) -> None:
        async with self._lock:
            self._state = CircuitState.CLOSED
            self._failure_count = 0
            self._last_failure_time = None
            logger.info("[CB:%s] manually reset → CLOSED", self.name)

    # ── Internal state transitions ───────────────────────────

    async def _before_call(self) -> None:
        async with self._lock:
            if self._state == CircuitState.OPEN:
                elapsed = time.monotonic() - (self._last_failure_time or 0)
                if elapsed >= self.recovery_timeout:
                    self._state = CircuitState.HALF_OPEN
                    logger.info("[CB:%s] OPEN → HALF_OPEN (probe attempt)", self.name)
                else:
                    raise CircuitOpenError(
                        f"Circuit {self.name!r} is OPEN. Retry in "
                        f"{self.recovery_timeout - elapsed:.1f}s"
                    )

    async def _on_success(self) -> None:
        async with self._lock:
            if self._state == CircuitState.HALF_OPEN:
                logger.info("[CB:%s] HALF_OPEN → CLOSED (recovery confirmed)", self.name)
            self._state = CircuitState.CLOSED
            self._failure_count = 0

    async def _on_failure(self) -> None:
        async with self._lock:
            self._failure_count += 1
            self._last_failure_time = time.monotonic()
            logger.warning(
                "[CB:%s] failure %d/%d", self.name, self._failure_count, self.failure_threshold
            )
            if self._failure_count >= self.failure_threshold:
                self._state = CircuitState.OPEN
                logger.error("[CB:%s] OPEN — circuit tripped", self.name)

    def __repr__(self) -> str:
        return (
            f"<CircuitBreaker name={self.name!r} state={self._state.value} "
            f"failures={self._failure_count}/{self.failure_threshold}>"
        )
