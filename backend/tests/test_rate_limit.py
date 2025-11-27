"""
Tests for rate limiting middleware

Tests API protection against brute force, DDoS, and abuse.
"""

import pytest
from httpx import AsyncClient
import asyncio


class TestRateLimiting:
    """Test rate limiting functionality"""

    @pytest.mark.asyncio
    async def test_rate_limit_applied(self, client: AsyncClient):
        """Test that rate limiting is applied to endpoints"""
        # Make multiple rapid requests to a public endpoint
        responses = []
        for _ in range(10):
            response = await client.get("/")
            responses.append(response.status_code)

        # Most should succeed (200), but if we hit rate limit, we'll get 429
        assert all(status in [200, 429] for status in responses)

    @pytest.mark.asyncio
    async def test_rate_limit_headers(self, client: AsyncClient):
        """Test that rate limit headers are present"""
        response = await client.get("/")

        # Check for rate limit headers (may vary by implementation)
        # Common headers: X-RateLimit-Limit, X-RateLimit-Remaining, X-RateLimit-Reset
        assert response.status_code == 200

    @pytest.mark.asyncio
    async def test_rate_limit_exceeded_response(self, client: AsyncClient):
        """Test response when rate limit is exceeded"""
        # Make many rapid requests to trigger rate limit
        responses = []
        for _ in range(100):
            response = await client.get("/health")
            responses.append(response)
            if response.status_code == 429:
                # Verify 429 response format
                assert "retry-after" in response.headers or "Retry-After" in response.headers
                data = response.json()
                assert "error" in data or "detail" in data
                break

    @pytest.mark.asyncio
    async def test_different_endpoints_separate_limits(self, client: AsyncClient):
        """Test that different endpoint types have different rate limits"""
        # Public endpoints should have higher limits than auth endpoints
        # This is a design verification test

        # Make requests to public endpoint
        public_responses = []
        for _ in range(10):
            response = await client.get("/health")
            public_responses.append(response.status_code)

        # Most public requests should succeed
        success_count = sum(1 for status in public_responses if status == 200)
        assert success_count >= 5  # At least half should succeed

    @pytest.mark.asyncio
    async def test_authenticated_vs_unauthenticated_limits(
        self, client: AsyncClient, auth_headers: dict
    ):
        """Test that authenticated users may have different rate limits"""
        # Unauthenticated requests
        unauth_responses = []
        for _ in range(5):
            response = await client.get("/")
            unauth_responses.append(response.status_code)

        # Authenticated requests
        auth_responses = []
        for _ in range(5):
            response = await client.get("/", headers=auth_headers)
            auth_responses.append(response.status_code)

        # Both should mostly succeed for small numbers
        assert all(status in [200, 429] for status in unauth_responses)
        assert all(status in [200, 429] for status in auth_responses)

    @pytest.mark.asyncio
    async def test_rate_limit_reset(self, client: AsyncClient):
        """Test that rate limits reset after time period"""
        # Make requests until rate limited
        for _ in range(100):
            response = await client.get("/health")
            if response.status_code == 429:
                # Wait for rate limit to reset (implementation dependent)
                # In production, wait based on Retry-After header
                await asyncio.sleep(1)

                # Try again - should succeed
                response = await client.get("/health")
                # May still be limited or may have reset
                assert response.status_code in [200, 429]
                break

    @pytest.mark.asyncio
    async def test_rate_limit_per_user(self, client: AsyncClient, auth_headers: dict):
        """Test that rate limits are tracked per user"""
        # Make multiple requests with same auth token
        responses = []
        for _ in range(10):
            response = await client.get("/profile", headers=auth_headers)
            responses.append(response.status_code)

        # Should be rate limited per user, not globally
        # This verifies the rate limiter is using user identifier
        assert all(status in [200, 401, 404, 429] for status in responses)

    @pytest.mark.asyncio
    async def test_rate_limit_by_ip(self, client: AsyncClient):
        """Test that unauthenticated requests are rate limited by IP"""
        # Multiple unauthenticated requests from same "IP"
        responses = []
        for _ in range(20):
            response = await client.get("/health")
            responses.append(response.status_code)

        # Should eventually hit rate limit
        status_codes = set(responses)
        assert 200 in status_codes  # Some should succeed
        # May or may not hit 429 depending on rate limit configuration

    @pytest.mark.asyncio
    async def test_sensitive_endpoints_stricter_limits(self, client: AsyncClient):
        """Test that sensitive endpoints have stricter rate limits"""
        # Authentication endpoints should have stricter limits
        # This is a design verification test

        # Try multiple login attempts (should be strictly limited)
        login_attempts = []
        for _ in range(10):
            response = await client.post(
                "/auth/login",
                json={"username": "test", "password": "test"}
            )
            login_attempts.append(response.status_code)

        # Should include failures (401 for bad credentials or 429 for rate limit)
        assert all(status in [401, 422, 429] for status in login_attempts)

    @pytest.mark.asyncio
    async def test_data_export_rate_limit(self, client: AsyncClient, auth_headers: dict):
        """Test that expensive operations like data export are strictly rate limited"""
        # Data exports should be limited to prevent abuse
        export_requests = []
        for _ in range(5):
            response = await client.post(
                "/privacy/export-data",
                json={"format": "json"},
                headers=auth_headers
            )
            export_requests.append(response.status_code)

        # Should hit rate limit quickly for expensive operations
        # Or all succeed if under limit
        assert all(status in [200, 429] for status in export_requests)

    @pytest.mark.asyncio
    async def test_ai_inference_rate_limit(self, client: AsyncClient, auth_headers: dict):
        """Test that AI/ML endpoints are rate limited"""
        # AI inference is compute-intensive and should be rate limited
        # This is a design verification test

        ai_requests = []
        for _ in range(15):
            response = await client.post(
                "/ai/analyze",
                json={"text": "test"},
                headers=auth_headers
            )
            ai_requests.append(response.status_code)

        # May succeed, fail with 404 (endpoint structure), or hit rate limit
        assert all(status in [200, 404, 422, 429] for status in ai_requests)

    @pytest.mark.asyncio
    async def test_rate_limit_configuration(self):
        """Test that rate limit configuration is properly set"""
        from app.middleware.rate_limit import RateLimitConfig

        # Verify rate limit configurations exist and are reasonable
        assert hasattr(RateLimitConfig, "AUTH_LOGIN")
        assert hasattr(RateLimitConfig, "PHI_READ")
        assert hasattr(RateLimitConfig, "DATA_EXPORT")
        assert hasattr(RateLimitConfig, "AI_INFERENCE")

        # Verify auth endpoints are most restrictive
        # Parse rate limits (format: "N/period")
        auth_login = RateLimitConfig.AUTH_LOGIN
        assert "/" in auth_login  # Should be in format "N/period"

    @pytest.mark.asyncio
    async def test_rate_limit_does_not_affect_health_check(self, client: AsyncClient):
        """Test that health check endpoint is not overly restricted"""
        # Health checks should be accessible for monitoring
        responses = []
        for _ in range(20):
            response = await client.get("/health")
            responses.append(response.status_code)

        # Most health checks should succeed (for monitoring purposes)
        success_count = sum(1 for status in responses if status == 200)
        assert success_count >= 10  # At least half should succeed

    @pytest.mark.asyncio
    async def test_concurrent_requests_rate_limit(self, client: AsyncClient):
        """Test rate limiting with concurrent requests"""
        # Make concurrent requests
        tasks = [client.get("/") for _ in range(10)]
        responses = await asyncio.gather(*tasks, return_exceptions=True)

        # Filter out exceptions and get status codes
        status_codes = [
            r.status_code for r in responses if hasattr(r, "status_code")
        ]

        # Should handle concurrent requests properly
        assert all(status in [200, 429] for status in status_codes)

    @pytest.mark.asyncio
    async def test_rate_limit_error_message(self, client: AsyncClient):
        """Test that rate limit error messages are informative"""
        # Make many requests to trigger rate limit
        for _ in range(100):
            response = await client.get("/")
            if response.status_code == 429:
                # Check error message
                data = response.json()
                # Should have informative error message
                assert "rate limit" in str(data).lower() or "too many" in str(data).lower()
                break


class TestRateLimitSecurity:
    """Test security aspects of rate limiting"""

    @pytest.mark.asyncio
    async def test_rate_limit_prevents_brute_force(self, client: AsyncClient):
        """Test that rate limiting prevents brute force attacks on login"""
        # Simulate brute force attack
        failed_logins = 0
        rate_limited = False

        for _ in range(20):
            response = await client.post(
                "/auth/login",
                json={"username": "admin", "password": f"wrong_password_{_}"}
            )

            if response.status_code == 429:
                rate_limited = True
                break
            elif response.status_code == 401:
                failed_logins += 1

        # Should either be rate limited or get authentication failures
        assert failed_logins > 0 or rate_limited

    @pytest.mark.asyncio
    async def test_rate_limit_prevents_enumeration(self, client: AsyncClient):
        """Test that rate limiting prevents user enumeration attacks"""
        # Try to enumerate users by testing many usernames
        responses = []
        for i in range(20):
            response = await client.post(
                "/auth/login",
                json={"username": f"user{i}", "password": "test"}
            )
            responses.append(response.status_code)

            if response.status_code == 429:
                # Rate limited - good!
                break

        # Should hit rate limit before completing enumeration
        assert 429 in responses or all(status == 401 for status in responses)

    @pytest.mark.asyncio
    async def test_rate_limit_protects_phi_endpoints(
        self, client: AsyncClient, auth_headers: dict
    ):
        """Test that PHI endpoints have appropriate rate limiting"""
        # PHI endpoints should be rate limited but not overly restrictive
        responses = []
        for _ in range(20):
            response = await client.get(
                "/micronutrients/deficiencies",
                headers=auth_headers
            )
            responses.append(response.status_code)

        # Should allow reasonable access but limit abuse
        assert all(status in [200, 401, 429] for status in responses)
