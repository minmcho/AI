"""
Rate limiting middleware for API protection

Implements rate limiting to prevent:
- Brute force attacks on authentication endpoints
- DDoS attacks
- Resource exhaustion
- API abuse

Uses slowapi (FastAPI-compatible rate limiting library)
"""

from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
from fastapi import Request, Response
from typing import Callable


def get_user_identifier(request: Request) -> str:
    """
    Get unique identifier for rate limiting

    Priority:
    1. User ID from JWT token (if authenticated)
    2. IP address (for unauthenticated requests)

    This allows per-user rate limiting for authenticated users
    and per-IP rate limiting for anonymous users.
    """
    # Try to get user from token
    auth_header = request.headers.get("authorization", "")
    if auth_header.startswith("Bearer "):
        # In production, decode token and get user_id
        # For now, use IP + token as identifier
        return f"user:{auth_header[:50]}"

    # Fall back to IP address
    return get_remote_address(request)


# Initialize limiter
limiter = Limiter(
    key_func=get_user_identifier,
    default_limits=["200/hour", "50/minute"],  # Default rate limits
    storage_uri="memory://",  # Use in-memory storage (for production, use Redis)
    strategy="fixed-window",
)


# Rate limit configurations for different endpoint types
class RateLimitConfig:
    """Predefined rate limit configurations"""

    # Authentication endpoints (most restrictive)
    AUTH_LOGIN = "5/minute"  # 5 login attempts per minute
    AUTH_REGISTER = "3/hour"  # 3 registrations per hour
    AUTH_PASSWORD_RESET = "3/hour"  # 3 password reset requests per hour
    AUTH_REFRESH_TOKEN = "10/minute"  # 10 token refreshes per minute

    # PHI access endpoints (moderate)
    PHI_READ = "100/minute"  # 100 PHI reads per minute
    PHI_WRITE = "50/minute"  # 50 PHI writes per minute

    # Data export (restrictive - expensive operation)
    DATA_EXPORT = "2/hour"  # 2 data exports per hour
    DATA_DELETE = "1/day"  # 1 deletion request per day

    # AI/ML endpoints (moderate - compute intensive)
    AI_INFERENCE = "30/minute"  # 30 AI requests per minute
    IMAGE_ANALYSIS = "20/minute"  # 20 image analyses per minute

    # Standard CRUD operations
    STANDARD_READ = "200/minute"  # 200 reads per minute
    STANDARD_WRITE = "100/minute"  # 100 writes per minute

    # Public endpoints
    PUBLIC_READ = "300/minute"  # 300 reads per minute


# Custom rate limit exceeded handler
async def custom_rate_limit_handler(request: Request, exc: RateLimitExceeded):
    """
    Custom handler for rate limit exceeded

    Returns informative error with retry-after header
    """
    return Response(
        content='{"error": "Rate limit exceeded", "message": "Too many requests. Please try again later."}',
        status_code=429,
        headers={
            "Content-Type": "application/json",
            "Retry-After": str(exc.detail),
            "X-RateLimit-Limit": str(exc.headers.get("X-RateLimit-Limit", "unknown")),
            "X-RateLimit-Remaining": "0",
            "X-RateLimit-Reset": str(exc.headers.get("X-RateLimit-Reset", "unknown")),
        },
    )


def apply_rate_limits(app):
    """
    Apply rate limiting to FastAPI app

    Usage:
        from app.middleware.rate_limit import apply_rate_limits
        apply_rate_limits(app)
    """
    # Add rate limiter to app state
    app.state.limiter = limiter

    # Add custom exception handler
    app.add_exception_handler(RateLimitExceeded, custom_rate_limit_handler)

    return limiter
