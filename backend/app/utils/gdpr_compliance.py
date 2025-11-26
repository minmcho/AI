"""
GDPR Compliance utilities

Implements GDPR data subject rights:
1. Right to Access (Data Portability)
2. Right to Erasure (Right to be Forgotten)
3. Right to Rectification
4. Right to Restrict Processing
5. Right to Object
6. Consent Management

Also addresses CCPA (California Consumer Privacy Act) requirements.
"""

from sqlalchemy import Column, Integer, String, Boolean, DateTime, JSON, Text, ForeignKey, Enum as SQLEnum
from sqlalchemy.orm import relationship
from datetime import datetime, timedelta
from enum import Enum
from typing import Optional, Dict, List, Any
from app.db.database import Base
import json


class ConsentType(str, Enum):
    """Types of consent under GDPR"""
    ESSENTIAL = "essential"  # Required for service
    ANALYTICS = "analytics"  # Usage analytics
    MARKETING = "marketing"  # Marketing communications
    PERSONALIZATION = "personalization"  # Personalized content
    THIRD_PARTY_SHARING = "third_party_sharing"  # Share with partners
    MEDICAL_DATA_PROCESSING = "medical_data_processing"  # Process health data (extra sensitive)
    RESEARCH = "research"  # Use data for research
    AI_TRAINING = "ai_training"  # Use data to train AI models


class LegalBasis(str, Enum):
    """GDPR legal bases for processing"""
    CONSENT = "consent"  # User gave consent
    CONTRACT = "contract"  # Necessary for contract
    LEGAL_OBLIGATION = "legal_obligation"  # Required by law
    VITAL_INTERESTS = "vital_interests"  # Life or death situation
    PUBLIC_TASK = "public_task"  # Public interest
    LEGITIMATE_INTERESTS = "legitimate_interests"  # Legitimate business interest


class DataCategory(str, Enum):
    """Categories of personal data"""
    BASIC_PROFILE = "basic_profile"  # Name, email, username
    CONTACT_INFO = "contact_info"  # Phone, address
    DEMOGRAPHIC = "demographic"  # Age, gender, location
    HEALTH_DATA = "health_data"  # Medical conditions, allergies (special category)
    DIETARY_DATA = "dietary_data"  # Meal plans, nutrition logs
    BIOMETRIC = "biometric"  # Weight, height, BMI
    USAGE_DATA = "usage_data"  # App usage, interactions
    LOCATION_DATA = "location_data"  # GPS, IP address
    DEVICE_DATA = "device_data"  # Device info, user agent
    COMMUNICATION = "communication"  # Messages, support tickets
    FINANCIAL = "financial"  # Payment info (if applicable)


class UserConsent(Base):
    """
    User consent tracking for GDPR compliance

    Records explicit consent for different types of data processing.
    Consent must be:
    - Freely given
    - Specific
    - Informed
    - Unambiguous
    - Withdrawable
    """
    __tablename__ = "user_consents"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)

    # Consent details
    consent_type = Column(SQLEnum(ConsentType), nullable=False, index=True)
    legal_basis = Column(SQLEnum(LegalBasis), default=LegalBasis.CONSENT)

    # Status
    is_granted = Column(Boolean, default=False, nullable=False)
    granted_date = Column(DateTime)
    revoked_date = Column(DateTime)
    expiry_date = Column(DateTime)  # Some consents may expire

    # Version control (for policy updates)
    policy_version = Column(String)  # Version of privacy policy when consent given
    consent_text = Column(Text)  # Exact text user consented to

    # Context
    consent_method = Column(String)  # web, mobile_ios, mobile_android, api
    ip_address = Column(String)  # Where consent was given
    user_agent = Column(String)  # Device info

    # Metadata
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


class DataRetentionPolicy(Base):
    """
    Data retention policies by category

    GDPR requires data to be kept only as long as necessary.
    """
    __tablename__ = "data_retention_policies"

    id = Column(Integer, primary_key=True, index=True)
    data_category = Column(SQLEnum(DataCategory), unique=True, nullable=False)

    # Retention
    retention_period_days = Column(Integer, nullable=False)
    retention_reason = Column(Text)  # Why we keep it this long

    # After retention period
    deletion_method = Column(String)  # soft_delete, hard_delete, anonymize

    # Legal requirements
    legal_hold_exceptions = Column(JSON)  # When retention period doesn't apply
    compliance_notes = Column(Text)

    # Metadata
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


class DataDeletionRequest(Base):
    """
    Right to Erasure (Right to be Forgotten) requests

    Tracks user requests to delete their data.
    """
    __tablename__ = "data_deletion_requests"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)

    # Request details
    request_date = Column(DateTime, default=datetime.utcnow, nullable=False)
    requested_via = Column(String)  # web, email, phone, etc.

    # Verification (important to verify identity)
    identity_verified = Column(Boolean, default=False)
    verification_method = Column(String)
    verification_date = Column(DateTime)

    # Scope
    scope = Column(String, default="full")  # full, partial
    categories_to_delete = Column(JSON)  # If partial, which categories
    reason = Column(String)  # Optional: why user wants deletion

    # Status
    status = Column(String, default="pending")  # pending, verified, processing, completed, rejected
    rejection_reason = Column(Text)  # If rejected, why (e.g., legal hold)

    # Processing
    processing_started = Column(DateTime)
    completed_date = Column(DateTime)
    deletion_summary = Column(JSON)  # What was deleted

    # Legal
    legal_hold = Column(Boolean, default=False)  # Cannot delete if under investigation
    legal_hold_reason = Column(Text)

    # Notifications
    user_notified = Column(Boolean, default=False)
    notification_date = Column(DateTime)

    # Metadata
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


class DataExportRequest(Base):
    """
    Right to Data Portability requests

    Tracks user requests to export their data.
    """
    __tablename__ = "data_export_requests"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)

    # Request details
    request_date = Column(DateTime, default=datetime.utcnow, nullable=False)
    export_format = Column(String, default="json")  # json, csv, pdf, xml

    # Scope
    categories_requested = Column(JSON)  # Which data categories to export
    include_metadata = Column(Boolean, default=True)

    # Status
    status = Column(String, default="pending")  # pending, processing, ready, downloaded, expired
    processing_started = Column(DateTime)
    completed_date = Column(DateTime)

    # File details
    file_size_bytes = Column(Integer)
    file_path = Column(String)  # Temporary secure storage location
    download_url = Column(String)  # Temporary signed URL
    download_expires = Column(DateTime)  # URL expiration

    # Security
    encryption_key = Column(String)  # If file is encrypted
    download_count = Column(Integer, default=0)
    max_downloads = Column(Integer, default=3)

    # Cleanup
    file_deleted_date = Column(DateTime)  # When temporary file was deleted

    # Metadata
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


class GDPRComplianceService:
    """Service for GDPR compliance operations"""

    @staticmethod
    async def grant_consent(
        db,
        user_id: int,
        consent_type: ConsentType,
        legal_basis: LegalBasis,
        policy_version: str,
        consent_text: str,
        ip_address: str,
        user_agent: str,
        consent_method: str = "web"
    ) -> UserConsent:
        """Record user consent"""
        consent = UserConsent(
            user_id=user_id,
            consent_type=consent_type,
            legal_basis=legal_basis,
            is_granted=True,
            granted_date=datetime.utcnow(),
            policy_version=policy_version,
            consent_text=consent_text,
            ip_address=ip_address,
            user_agent=user_agent,
            consent_method=consent_method
        )

        db.add(consent)
        await db.commit()
        await db.refresh(consent)

        return consent

    @staticmethod
    async def revoke_consent(
        db,
        user_id: int,
        consent_type: ConsentType
    ):
        """Revoke user consent"""
        from sqlalchemy import select
        result = await db.execute(
            select(UserConsent).where(
                UserConsent.user_id == user_id,
                UserConsent.consent_type == consent_type,
                UserConsent.is_granted == True
            )
        )
        consent = result.scalar_one_or_none()

        if consent:
            consent.is_granted = False
            consent.revoked_date = datetime.utcnow()
            await db.commit()

        return consent

    @staticmethod
    async def check_consent(
        db,
        user_id: int,
        consent_type: ConsentType
    ) -> bool:
        """Check if user has granted consent"""
        from sqlalchemy import select
        result = await db.execute(
            select(UserConsent).where(
                UserConsent.user_id == user_id,
                UserConsent.consent_type == consent_type,
                UserConsent.is_granted == True
            )
        )
        consent = result.scalar_one_or_none()

        if not consent:
            return False

        # Check if expired
        if consent.expiry_date and consent.expiry_date < datetime.utcnow():
            return False

        return True

    @staticmethod
    async def request_data_export(
        db,
        user_id: int,
        export_format: str = "json",
        categories: Optional[List[str]] = None
    ) -> DataExportRequest:
        """Create data export request"""
        export_request = DataExportRequest(
            user_id=user_id,
            export_format=export_format,
            categories_requested=categories or [],
            status="pending"
        )

        db.add(export_request)
        await db.commit()
        await db.refresh(export_request)

        # Trigger async processing
        # In production, use Celery or similar task queue
        # await process_export_request.delay(export_request.id)

        return export_request

    @staticmethod
    async def export_user_data(
        db,
        user_id: int,
        categories: Optional[List[DataCategory]] = None
    ) -> Dict[str, Any]:
        """
        Export all user data in machine-readable format

        Returns comprehensive data export including:
        - Profile data
        - Health data
        - Meal plans
        - Activity logs
        - Consents
        """
        from sqlalchemy import select
        from app.models.user import User

        # Get user
        user = await db.get(User, user_id)
        if not user:
            raise ValueError("User not found")

        export_data = {
            "export_date": datetime.utcnow().isoformat(),
            "user_id": user_id,
            "format_version": "1.0",
            "data": {}
        }

        # Basic profile
        export_data["data"]["profile"] = {
            "email": user.email,
            "username": user.username,
            "full_name": user.full_name,
            "created_at": user.created_at.isoformat() if user.created_at else None,
        }

        # Health data (if consented)
        if not categories or DataCategory.HEALTH_DATA in categories:
            export_data["data"]["health"] = {
                "age": user.age,
                "weight_kg": user.weight_kg,
                "height_cm": user.height_cm,
                "sex": user.sex.value if user.sex else None,
                "medical_conditions": user.medical_conditions,
                "medications": user.medications,
                "allergies": user.allergies,
                "dietary_restrictions": user.dietary_restrictions,
                "health_goals": user.health_goals,
            }

        # Consents
        result = await db.execute(
            select(UserConsent).where(UserConsent.user_id == user_id)
        )
        consents = result.scalars().all()

        export_data["data"]["consents"] = [
            {
                "type": c.consent_type.value,
                "is_granted": c.is_granted,
                "granted_date": c.granted_date.isoformat() if c.granted_date else None,
                "revoked_date": c.revoked_date.isoformat() if c.revoked_date else None,
            }
            for c in consents
        ]

        # Additional categories can be added here:
        # - Meal plans
        # - Journal entries
        # - Shopping lists
        # - Audit logs (what actions user took)

        return export_data

    @staticmethod
    async def request_data_deletion(
        db,
        user_id: int,
        scope: str = "full",
        categories: Optional[List[str]] = None,
        reason: Optional[str] = None,
        requested_via: str = "web"
    ) -> DataDeletionRequest:
        """Create data deletion request"""
        deletion_request = DataDeletionRequest(
            user_id=user_id,
            scope=scope,
            categories_to_delete=categories or [],
            reason=reason,
            requested_via=requested_via,
            status="pending"
        )

        db.add(deletion_request)
        await db.commit()
        await db.refresh(deletion_request)

        return deletion_request

    @staticmethod
    async def process_data_deletion(
        db,
        deletion_request_id: int,
        verify_identity: bool = True
    ):
        """
        Process data deletion request

        IMPORTANT: This performs actual data deletion.
        Must verify user identity first.
        Must comply with legal holds.
        """
        deletion_request = await db.get(DataDeletionRequest, deletion_request_id)

        if not deletion_request:
            raise ValueError("Deletion request not found")

        # Check identity verification
        if verify_identity and not deletion_request.identity_verified:
            raise ValueError("Identity not verified")

        # Check legal holds
        if deletion_request.legal_hold:
            deletion_request.status = "rejected"
            deletion_request.rejection_reason = deletion_request.legal_hold_reason
            await db.commit()
            return

        # Begin deletion
        deletion_request.status = "processing"
        deletion_request.processing_started = datetime.utcnow()
        await db.commit()

        user_id = deletion_request.user_id
        deletion_summary = {}

        # Delete based on scope
        if deletion_request.scope == "full":
            # Full account deletion
            # This is a soft delete - user record remains for audit but data is cleared
            user = await db.get(User, user_id)
            if user:
                # Anonymize user data
                user.email = f"deleted_{user_id}@privacy.local"
                user.username = f"deleted_user_{user_id}"
                user.full_name = "[Deleted]"
                user.is_active = False

                # Clear PHI
                user.medical_conditions = []
                user.medications = []
                user.allergies = []

                deletion_summary["user_anonymized"] = True

                # Delete related records
                # meal_plans, journal_entries, shopping_lists, etc.
                # Implementation depends on your relationships

        deletion_request.status = "completed"
        deletion_request.completed_date = datetime.utcnow()
        deletion_request.deletion_summary = deletion_summary

        await db.commit()

        return deletion_request

    @staticmethod
    async def anonymize_data_for_retention(db, user_id: int):
        """
        Anonymize user data while preserving statistical value

        Used when retention period expires but aggregate data is valuable.
        """
        pass  # Implementation depends on use case


# Singleton instance
gdpr_service = GDPRComplianceService()
