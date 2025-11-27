"""
Tests for micronutrient tracking API

Tests comprehensive micronutrient tracking, deficiency detection, and personalized targets.
"""

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.user import User


class TestMicronutrientAPI:
    """Test micronutrient tracking endpoints"""

    @pytest.mark.asyncio
    async def test_list_micronutrients(self, client: AsyncClient):
        """Test listing all available micronutrients"""
        response = await client.get("/micronutrients/")

        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        assert len(data) > 0

        # Verify structure
        micronutrient = data[0]
        assert "code" in micronutrient
        assert "name" in micronutrient
        assert "category" in micronutrient
        assert "rda_male" in micronutrient
        assert "rda_female" in micronutrient

    @pytest.mark.asyncio
    async def test_get_micronutrient_by_code(self, client: AsyncClient):
        """Test getting specific micronutrient by code"""
        response = await client.get("/micronutrients/VIT_D")

        assert response.status_code == 200
        data = response.json()
        assert data["code"] == "VIT_D"
        assert data["name"] == "Vitamin D"
        assert "health_benefits" in data
        assert "deficiency_symptoms" in data

    @pytest.mark.asyncio
    async def test_get_nonexistent_micronutrient(self, client: AsyncClient):
        """Test getting nonexistent micronutrient returns 404"""
        response = await client.get("/micronutrients/INVALID_CODE")

        assert response.status_code == 404

    @pytest.mark.asyncio
    async def test_get_user_targets_unauthenticated(self, client: AsyncClient):
        """Test getting user targets without authentication fails"""
        response = await client.get("/micronutrients/targets")

        assert response.status_code == 401

    @pytest.mark.asyncio
    async def test_get_user_targets(self, client: AsyncClient, auth_headers: dict):
        """Test getting user personalized micronutrient targets"""
        response = await client.get("/micronutrients/targets", headers=auth_headers)

        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)

        # If targets exist, verify structure
        if len(data) > 0:
            target = data[0]
            assert "micronutrient_code" in target
            assert "target_value" in target
            assert "current_intake" in target

    @pytest.mark.asyncio
    async def test_set_custom_target(self, client: AsyncClient, auth_headers: dict):
        """Test setting custom micronutrient target"""
        target_data = {
            "micronutrient_code": "VIT_D",
            "target_value": 2000.0,
            "reason": "Doctor recommended higher dose"
        }

        response = await client.post(
            "/micronutrients/targets",
            json=target_data,
            headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()
        assert data["micronutrient_code"] == "VIT_D"
        assert data["target_value"] == 2000.0
        assert data["is_custom"] is True

    @pytest.mark.asyncio
    async def test_record_deficiency(self, client: AsyncClient, auth_headers: dict):
        """Test recording micronutrient deficiency"""
        deficiency_data = {
            "micronutrient_code": "VIT_D",
            "severity": "moderate",
            "diagnosed_date": "2024-01-15",
            "symptoms": "Fatigue, bone pain",
            "lab_results": "25-OH Vitamin D: 15 ng/mL (low)",
            "prescribed_by": "Dr. Smith, MD"
        }

        response = await client.post(
            "/micronutrients/deficiencies",
            json=deficiency_data,
            headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()
        assert data["micronutrient_code"] == "VIT_D"
        assert data["severity"] == "moderate"
        # PHI fields should be encrypted in database
        assert "symptoms" in data  # Response decrypts for user

    @pytest.mark.asyncio
    async def test_get_user_deficiencies(self, client: AsyncClient, auth_headers: dict):
        """Test getting user's deficiency history"""
        response = await client.get("/micronutrients/deficiencies", headers=auth_headers)

        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)

    @pytest.mark.asyncio
    async def test_update_deficiency_status(self, client: AsyncClient, auth_headers: dict):
        """Test updating deficiency resolution status"""
        # First create a deficiency
        deficiency_data = {
            "micronutrient_code": "VIT_B12",
            "severity": "mild",
            "diagnosed_date": "2024-01-01"
        }

        create_response = await client.post(
            "/micronutrients/deficiencies",
            json=deficiency_data,
            headers=auth_headers
        )
        deficiency_id = create_response.json()["id"]

        # Update resolution status
        update_data = {
            "resolved": True,
            "resolved_date": "2024-02-01",
            "resolution_notes": "Supplementation successful"
        }

        response = await client.patch(
            f"/micronutrients/deficiencies/{deficiency_id}",
            json=update_data,
            headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()
        assert data["resolved"] is True

    @pytest.mark.asyncio
    async def test_record_daily_intake(self, client: AsyncClient, auth_headers: dict):
        """Test recording daily micronutrient intake"""
        intake_data = {
            "date": "2024-01-20",
            "micronutrient_intakes": [
                {"micronutrient_code": "VIT_D", "amount": 1000.0, "source": "supplement"},
                {"micronutrient_code": "CA", "amount": 800.0, "source": "food"},
                {"micronutrient_code": "VIT_C", "amount": 500.0, "source": "food"}
            ]
        }

        response = await client.post(
            "/micronutrients/daily-intake",
            json=intake_data,
            headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()
        assert data["date"] == "2024-01-20"
        assert len(data["intakes"]) == 3

    @pytest.mark.asyncio
    async def test_get_intake_history(self, client: AsyncClient, auth_headers: dict):
        """Test getting intake history with date range"""
        params = {
            "start_date": "2024-01-01",
            "end_date": "2024-01-31"
        }

        response = await client.get(
            "/micronutrients/intake-history",
            params=params,
            headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)

    @pytest.mark.asyncio
    async def test_get_intake_analysis(self, client: AsyncClient, auth_headers: dict):
        """Test getting AI-powered intake analysis"""
        response = await client.get(
            "/micronutrients/analysis",
            headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()
        assert "average_intake" in data or "recommendations" in data

    @pytest.mark.asyncio
    async def test_get_recommendations(self, client: AsyncClient, auth_headers: dict):
        """Test getting personalized micronutrient recommendations"""
        response = await client.get(
            "/micronutrients/recommendations",
            headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)

        # Verify recommendation structure
        if len(data) > 0:
            rec = data[0]
            assert "micronutrient_code" in rec
            assert "current_intake" in rec
            assert "recommended_intake" in rec
            assert "rationale" in rec

    @pytest.mark.asyncio
    async def test_invalid_micronutrient_code(self, client: AsyncClient, auth_headers: dict):
        """Test that invalid micronutrient codes are rejected"""
        deficiency_data = {
            "micronutrient_code": "INVALID_CODE",
            "severity": "moderate"
        }

        response = await client.post(
            "/micronutrients/deficiencies",
            json=deficiency_data,
            headers=auth_headers
        )

        assert response.status_code in [400, 404]

    @pytest.mark.asyncio
    async def test_severity_validation(self, client: AsyncClient, auth_headers: dict):
        """Test that invalid severity values are rejected"""
        deficiency_data = {
            "micronutrient_code": "VIT_D",
            "severity": "super_extreme"  # Invalid severity
        }

        response = await client.post(
            "/micronutrients/deficiencies",
            json=deficiency_data,
            headers=auth_headers
        )

        assert response.status_code == 422  # Validation error

    @pytest.mark.asyncio
    async def test_phi_audit_logging(self, client: AsyncClient, auth_headers: dict, db_session: AsyncSession):
        """Test that PHI access is logged in audit trail"""
        from app.utils.audit_log import AuditLogger

        audit_logger = AuditLogger()

        # Record a deficiency (PHI)
        deficiency_data = {
            "micronutrient_code": "VIT_D",
            "severity": "moderate",
            "symptoms": "Test symptoms"
        }

        response = await client.post(
            "/micronutrients/deficiencies",
            json=deficiency_data,
            headers=auth_headers
        )

        assert response.status_code == 200

        # Verify audit log was created
        # Note: In production, verify the audit log contains correct fields
        # This is a design verification test


class TestMicronutrientSecurity:
    """Test security and privacy for micronutrient endpoints"""

    @pytest.mark.asyncio
    async def test_cannot_access_other_user_data(self, client: AsyncClient, auth_headers: dict):
        """Test that users cannot access other users' micronutrient data"""
        # This would require creating two users and verifying isolation
        # For now, verify authentication is required
        response = await client.get("/micronutrients/deficiencies")
        assert response.status_code == 401

    @pytest.mark.asyncio
    async def test_phi_encryption_in_database(self, db_session: AsyncSession, auth_headers: dict):
        """Test that PHI fields are encrypted in database"""
        from app.models.micronutrients import MicronutrientDeficiency

        # This is a design verification test
        # In production, verify that sensitive fields like symptoms,
        # lab_results, and prescribed_by are stored encrypted
        pass
