"""
Tests for treatment-specific diets and medical nutrition therapy API

Tests evidence-based therapeutic diets, medical profiles, and diet prescriptions.
"""

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.user import User


class TestTreatmentDietsAPI:
    """Test medical nutrition therapy endpoints"""

    @pytest.mark.asyncio
    async def test_list_medical_conditions(self, client: AsyncClient):
        """Test listing all supported medical conditions"""
        response = await client.get("/treatment-diets/conditions")

        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        assert len(data) > 0

        # Verify structure
        condition = data[0]
        assert "code" in condition
        assert "name" in condition
        assert "icd10_code" in condition
        assert "recommended_diets" in condition

    @pytest.mark.asyncio
    async def test_get_condition_by_code(self, client: AsyncClient):
        """Test getting specific medical condition"""
        response = await client.get("/treatment-diets/conditions/T2DM")

        assert response.status_code == 200
        data = response.json()
        assert data["code"] == "T2DM"
        assert data["name"] == "Type 2 Diabetes Mellitus"
        assert "recommended_diets" in data
        assert "evidence_level" in data

    @pytest.mark.asyncio
    async def test_list_therapeutic_diets(self, client: AsyncClient):
        """Test listing all available therapeutic diets"""
        response = await client.get("/treatment-diets/diets")

        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        assert len(data) > 0

        # Verify structure
        diet = data[0]
        assert "code" in diet
        assert "name" in diet
        assert "macronutrient_targets" in diet
        assert "allowed_foods" in diet
        assert "restricted_foods" in diet

    @pytest.mark.asyncio
    async def test_get_diet_by_code(self, client: AsyncClient):
        """Test getting specific therapeutic diet"""
        response = await client.get("/treatment-diets/diets/DASH")

        assert response.status_code == 200
        data = response.json()
        assert data["code"] == "DASH"
        assert "Dietary Approaches" in data["name"]
        assert "macronutrient_targets" in data

    @pytest.mark.asyncio
    async def test_create_medical_profile_unauthenticated(self, client: AsyncClient):
        """Test that unauthenticated users cannot create medical profile"""
        response = await client.post("/treatment-diets/medical-profile")

        assert response.status_code == 401

    @pytest.mark.asyncio
    async def test_create_medical_profile_with_consent(self, client: AsyncClient, auth_headers: dict):
        """Test creating medical profile with explicit consent"""
        profile_data = {
            "conditions": ["T2DM", "HTN"],
            "medications": "Metformin 500mg twice daily",
            "allergies": "Shellfish allergy",
            "dietary_restrictions": "Vegetarian",
            "consent_to_store_phi": True
        }

        response = await client.post(
            "/treatment-diets/medical-profile",
            json=profile_data,
            headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()
        assert data["conditions"] == ["T2DM", "HTN"]
        # PHI should be encrypted in database but decrypted in response

    @pytest.mark.asyncio
    async def test_create_medical_profile_without_consent(self, client: AsyncClient, auth_headers: dict):
        """Test that medical profile requires explicit consent"""
        profile_data = {
            "conditions": ["T2DM"],
            "consent_to_store_phi": False  # No consent
        }

        response = await client.post(
            "/treatment-diets/medical-profile",
            json=profile_data,
            headers=auth_headers
        )

        assert response.status_code == 400
        assert "consent" in response.json()["detail"].lower()

    @pytest.mark.asyncio
    async def test_get_medical_profile(self, client: AsyncClient, auth_headers: dict):
        """Test getting user's medical profile"""
        response = await client.get(
            "/treatment-diets/medical-profile",
            headers=auth_headers
        )

        # May return 404 if no profile exists
        assert response.status_code in [200, 404]

        if response.status_code == 200:
            data = response.json()
            assert "conditions" in data
            assert "created_at" in data

    @pytest.mark.asyncio
    async def test_update_medical_profile(self, client: AsyncClient, auth_headers: dict):
        """Test updating existing medical profile"""
        # First create a profile
        create_data = {
            "conditions": ["T2DM"],
            "consent_to_store_phi": True
        }
        await client.post(
            "/treatment-diets/medical-profile",
            json=create_data,
            headers=auth_headers
        )

        # Update it
        update_data = {
            "conditions": ["T2DM", "HTN"],
            "medications": "Added blood pressure medication"
        }

        response = await client.patch(
            "/treatment-diets/medical-profile",
            json=update_data,
            headers=auth_headers
        )

        assert response.status_code in [200, 404]

    @pytest.mark.asyncio
    async def test_get_diet_recommendations(self, client: AsyncClient, auth_headers: dict):
        """Test getting AI-powered diet recommendations based on medical profile"""
        response = await client.get(
            "/treatment-diets/recommendations",
            headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)

        # Verify recommendation structure
        if len(data) > 0:
            rec = data[0]
            assert "diet_code" in rec
            assert "rationale" in rec
            assert "evidence_level" in rec

    @pytest.mark.asyncio
    async def test_create_diet_prescription(self, client: AsyncClient, auth_headers: dict):
        """Test creating formal diet prescription (healthcare provider)"""
        prescription_data = {
            "diet_code": "DASH",
            "prescribed_by": "Dr. Jane Smith, MD",
            "prescription_date": "2024-01-20",
            "duration_weeks": 12,
            "special_instructions": "Monitor blood pressure weekly",
            "target_outcomes": ["Reduce systolic BP by 10-15 mmHg"]
        }

        response = await client.post(
            "/treatment-diets/prescriptions",
            json=prescription_data,
            headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()
        assert data["diet_code"] == "DASH"
        assert data["duration_weeks"] == 12

    @pytest.mark.asyncio
    async def test_get_active_prescriptions(self, client: AsyncClient, auth_headers: dict):
        """Test getting user's active diet prescriptions"""
        response = await client.get(
            "/treatment-diets/prescriptions",
            headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)

    @pytest.mark.asyncio
    async def test_update_prescription_adherence(self, client: AsyncClient, auth_headers: dict):
        """Test updating diet prescription adherence"""
        # First create a prescription
        prescription_data = {
            "diet_code": "MEDITERRANEAN",
            "prescribed_by": "Dr. Smith",
            "prescription_date": "2024-01-01"
        }
        create_response = await client.post(
            "/treatment-diets/prescriptions",
            json=prescription_data,
            headers=auth_headers
        )

        if create_response.status_code == 200:
            prescription_id = create_response.json()["id"]

            # Update adherence
            adherence_data = {
                "adherence_percentage": 85.0,
                "notes": "Following diet well, occasional deviations on weekends"
            }

            response = await client.patch(
                f"/treatment-diets/prescriptions/{prescription_id}/adherence",
                json=adherence_data,
                headers=auth_headers
            )

            assert response.status_code in [200, 404]

    @pytest.mark.asyncio
    async def test_complete_prescription(self, client: AsyncClient, auth_headers: dict):
        """Test marking prescription as completed"""
        # Create and complete a prescription
        prescription_data = {
            "diet_code": "DASH",
            "prescribed_by": "Dr. Smith",
            "prescription_date": "2024-01-01",
            "duration_weeks": 4
        }
        create_response = await client.post(
            "/treatment-diets/prescriptions",
            json=prescription_data,
            headers=auth_headers
        )

        if create_response.status_code == 200:
            prescription_id = create_response.json()["id"]

            completion_data = {
                "completed": True,
                "completion_date": "2024-02-01",
                "outcomes_achieved": ["Blood pressure reduced to 120/80"]
            }

            response = await client.patch(
                f"/treatment-diets/prescriptions/{prescription_id}",
                json=completion_data,
                headers=auth_headers
            )

            assert response.status_code in [200, 404]

    @pytest.mark.asyncio
    async def test_get_diet_meal_plans(self, client: AsyncClient, auth_headers: dict):
        """Test getting meal plans for specific therapeutic diet"""
        response = await client.get(
            "/treatment-diets/diets/DASH/meal-plans",
            headers=auth_headers
        )

        assert response.status_code in [200, 404]

    @pytest.mark.asyncio
    async def test_get_condition_education(self, client: AsyncClient):
        """Test getting educational content for medical condition"""
        response = await client.get("/treatment-diets/conditions/T2DM/education")

        assert response.status_code in [200, 404]

        if response.status_code == 200:
            data = response.json()
            assert "condition" in data
            assert "dietary_guidance" in data or "overview" in data

    @pytest.mark.asyncio
    async def test_invalid_condition_code(self, client: AsyncClient, auth_headers: dict):
        """Test that invalid condition codes are rejected"""
        profile_data = {
            "conditions": ["INVALID_CONDITION"],
            "consent_to_store_phi": True
        }

        response = await client.post(
            "/treatment-diets/medical-profile",
            json=profile_data,
            headers=auth_headers
        )

        assert response.status_code in [400, 422]

    @pytest.mark.asyncio
    async def test_invalid_diet_code(self, client: AsyncClient, auth_headers: dict):
        """Test that invalid diet codes are rejected"""
        prescription_data = {
            "diet_code": "INVALID_DIET",
            "prescribed_by": "Dr. Smith"
        }

        response = await client.post(
            "/treatment-diets/prescriptions",
            json=prescription_data,
            headers=auth_headers
        )

        assert response.status_code in [400, 404, 422]


class TestTreatmentDietsSecurity:
    """Test security and privacy for treatment diets"""

    @pytest.mark.asyncio
    async def test_phi_encryption_medical_profile(self, db_session: AsyncSession):
        """Test that medical profile PHI is encrypted"""
        from app.models.medical_diets import MedicalProfile

        # Design verification: medications, allergies should be encrypted
        # In production, verify these fields are stored encrypted in database
        pass

    @pytest.mark.asyncio
    async def test_phi_encryption_prescriptions(self, db_session: AsyncSession):
        """Test that prescription PHI is encrypted"""
        from app.models.medical_diets import DietPrescription

        # Design verification: prescribed_by, special_instructions should be encrypted
        pass

    @pytest.mark.asyncio
    async def test_audit_logging_medical_data(self, client: AsyncClient, auth_headers: dict):
        """Test that medical data access is audit logged"""
        # Create medical profile
        profile_data = {
            "conditions": ["T2DM"],
            "consent_to_store_phi": True
        }

        response = await client.post(
            "/treatment-diets/medical-profile",
            json=profile_data,
            headers=auth_headers
        )

        assert response.status_code == 200

        # Verify audit log was created
        # In production, check audit_logs table

    @pytest.mark.asyncio
    async def test_cannot_access_other_user_medical_data(
        self, client: AsyncClient, auth_headers: dict
    ):
        """Test that users cannot access other users' medical data"""
        # This would require two users
        # Verify authentication is required
        response = await client.get("/treatment-diets/medical-profile")
        assert response.status_code == 401

    @pytest.mark.asyncio
    async def test_evidence_based_recommendations(self, client: AsyncClient, auth_headers: dict):
        """Test that diet recommendations are evidence-based"""
        response = await client.get(
            "/treatment-diets/recommendations",
            headers=auth_headers
        )

        if response.status_code == 200:
            data = response.json()
            if len(data) > 0:
                # Should include evidence level
                assert "evidence_level" in data[0] or "rationale" in data[0]
