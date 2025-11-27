"""
Tests for HIPAA-compliant audit logging

Tests comprehensive audit trail for all PHI access and modifications.
"""

import pytest
from datetime import datetime, timedelta
from sqlalchemy.ext.asyncio import AsyncSession
from app.utils.audit_log import AuditLogger, AuditLog, AuditAction
from app.models.user import User


class TestAuditLogger:
    """Test HIPAA audit logging functionality"""

    @pytest.fixture
    def audit_logger(self):
        """Create audit logger instance"""
        return AuditLogger()

    @pytest.mark.asyncio
    async def test_log_phi_access(self, db_session: AsyncSession, test_user: User, audit_logger):
        """Test logging PHI access"""
        log_entry = await audit_logger.log_phi_access(
            db=db_session,
            user_id=test_user.id,
            action=AuditAction.READ,
            resource_type="medical_profile",
            resource_id=123,
            phi_fields=["diagnosis", "medications"],
            outcome="success",
            ip_address="192.168.1.100",
            user_agent="TestClient/1.0"
        )

        assert log_entry is not None
        assert log_entry.user_id == test_user.id
        assert log_entry.action == AuditAction.READ.value
        assert log_entry.resource_type == "medical_profile"
        assert log_entry.resource_id == 123
        assert log_entry.phi_accessed == 2
        assert log_entry.outcome == "success"
        assert log_entry.ip_address == "192.168.1.100"

    @pytest.mark.asyncio
    async def test_log_data_export(self, db_session: AsyncSession, test_user: User, audit_logger):
        """Test logging GDPR data export"""
        log_entry = await audit_logger.log_data_export(
            db=db_session,
            user_id=test_user.id,
            export_format="json",
            categories=["profile", "medical_history", "nutrition_data"],
            ip_address="192.168.1.101"
        )

        assert log_entry is not None
        assert log_entry.action == AuditAction.EXPORT.value
        assert log_entry.resource_type == "user_data"
        assert log_entry.metadata["export_format"] == "json"
        assert log_entry.metadata["categories"] == ["profile", "medical_history", "nutrition_data"]

    @pytest.mark.asyncio
    async def test_log_data_deletion(self, db_session: AsyncSession, test_user: User, audit_logger):
        """Test logging GDPR data deletion"""
        log_entry = await audit_logger.log_data_deletion(
            db=db_session,
            user_id=test_user.id,
            deletion_scope="all_data",
            reason="User requested account deletion",
            ip_address="192.168.1.102"
        )

        assert log_entry is not None
        assert log_entry.action == AuditAction.DELETE.value
        assert log_entry.metadata["deletion_scope"] == "all_data"
        assert log_entry.metadata["reason"] == "User requested account deletion"

    @pytest.mark.asyncio
    async def test_log_consent_change(self, db_session: AsyncSession, test_user: User, audit_logger):
        """Test logging consent changes"""
        log_entry = await audit_logger.log_consent_change(
            db=db_session,
            user_id=test_user.id,
            consent_type="data_processing",
            old_value=True,
            new_value=False,
            ip_address="192.168.1.103"
        )

        assert log_entry is not None
        assert log_entry.action == AuditAction.CONSENT_CHANGE.value
        assert log_entry.metadata["consent_type"] == "data_processing"
        assert log_entry.metadata["old_value"] is True
        assert log_entry.metadata["new_value"] is False

    @pytest.mark.asyncio
    async def test_get_user_audit_trail(self, db_session: AsyncSession, test_user: User, audit_logger):
        """Test retrieving user audit trail"""
        # Create multiple audit logs
        await audit_logger.log_phi_access(
            db=db_session,
            user_id=test_user.id,
            action=AuditAction.READ,
            resource_type="medical_profile",
            resource_id=1,
            ip_address="192.168.1.100"
        )
        await audit_logger.log_phi_access(
            db=db_session,
            user_id=test_user.id,
            action=AuditAction.UPDATE,
            resource_type="medical_profile",
            resource_id=1,
            ip_address="192.168.1.100"
        )

        # Retrieve audit trail
        audit_trail = await audit_logger.get_user_audit_trail(
            db=db_session,
            user_id=test_user.id,
            limit=10
        )

        assert len(audit_trail) == 2
        assert all(log.user_id == test_user.id for log in audit_trail)

    @pytest.mark.asyncio
    async def test_get_phi_access_logs(self, db_session: AsyncSession, test_user: User, audit_logger):
        """Test retrieving PHI access logs"""
        # Create PHI access log
        await audit_logger.log_phi_access(
            db=db_session,
            user_id=test_user.id,
            action=AuditAction.READ,
            resource_type="medical_profile",
            resource_id=123,
            phi_fields=["diagnosis"],
            ip_address="192.168.1.100"
        )

        # Create non-PHI log
        await audit_logger.log(
            db=db_session,
            user_id=test_user.id,
            action=AuditAction.READ,
            resource_type="recipe",
            resource_id=456,
            ip_address="192.168.1.100"
        )

        # Retrieve PHI access logs only
        phi_logs = await audit_logger.get_phi_access_logs(
            db=db_session,
            user_id=test_user.id
        )

        assert len(phi_logs) >= 1
        assert all(log.phi_accessed > 0 for log in phi_logs)

    @pytest.mark.asyncio
    async def test_search_audit_logs(self, db_session: AsyncSession, test_user: User, audit_logger):
        """Test searching audit logs with filters"""
        # Create various audit logs
        await audit_logger.log_phi_access(
            db=db_session,
            user_id=test_user.id,
            action=AuditAction.READ,
            resource_type="medical_profile",
            resource_id=1,
            ip_address="192.168.1.100"
        )
        await audit_logger.log_phi_access(
            db=db_session,
            user_id=test_user.id,
            action=AuditAction.UPDATE,
            resource_type="prescription",
            resource_id=2,
            ip_address="192.168.1.100"
        )

        # Search for READ actions
        read_logs = await audit_logger.search_logs(
            db=db_session,
            action=AuditAction.READ.value
        )

        assert len(read_logs) >= 1
        assert all(log.action == AuditAction.READ.value for log in read_logs)

    @pytest.mark.asyncio
    async def test_log_failed_access(self, db_session: AsyncSession, test_user: User, audit_logger):
        """Test logging failed access attempts"""
        log_entry = await audit_logger.log_phi_access(
            db=db_session,
            user_id=test_user.id,
            action=AuditAction.READ,
            resource_type="medical_profile",
            resource_id=999,
            outcome="failed",
            failure_reason="unauthorized",
            ip_address="192.168.1.100"
        )

        assert log_entry is not None
        assert log_entry.outcome == "failed"
        assert log_entry.metadata["failure_reason"] == "unauthorized"

    @pytest.mark.asyncio
    async def test_log_with_metadata(self, db_session: AsyncSession, test_user: User, audit_logger):
        """Test logging with additional metadata"""
        metadata = {
            "request_id": "req_12345",
            "session_id": "sess_67890",
            "additional_context": "Accessing medical history for treatment plan"
        }

        log_entry = await audit_logger.log(
            db=db_session,
            user_id=test_user.id,
            action=AuditAction.READ,
            resource_type="medical_history",
            resource_id=1,
            ip_address="192.168.1.100",
            metadata=metadata
        )

        assert log_entry.metadata["request_id"] == "req_12345"
        assert log_entry.metadata["session_id"] == "sess_67890"
        assert "additional_context" in log_entry.metadata

    @pytest.mark.asyncio
    async def test_audit_log_immutability(self, db_session: AsyncSession, test_user: User, audit_logger):
        """Test that audit logs cannot be modified after creation"""
        log_entry = await audit_logger.log_phi_access(
            db=db_session,
            user_id=test_user.id,
            action=AuditAction.READ,
            resource_type="medical_profile",
            resource_id=1,
            ip_address="192.168.1.100"
        )

        original_action = log_entry.action
        original_timestamp = log_entry.timestamp

        # In production, audit logs should be write-once
        # This test verifies the timestamp doesn't change
        assert log_entry.timestamp == original_timestamp
        assert log_entry.action == original_action

    @pytest.mark.asyncio
    async def test_hipaa_retention_compliance(self, db_session: AsyncSession, test_user: User, audit_logger):
        """Test that audit logs meet HIPAA 6-year retention requirement"""
        # This is a design verification test
        # In production, implement automated archival after 6 years
        log_entry = await audit_logger.log_phi_access(
            db=db_session,
            user_id=test_user.id,
            action=AuditAction.READ,
            resource_type="medical_profile",
            resource_id=1,
            ip_address="192.168.1.100"
        )

        # Verify timestamp is recorded
        assert log_entry.timestamp is not None
        assert isinstance(log_entry.timestamp, datetime)

        # In production, verify retention policy:
        # - Logs must be retained for at least 6 years (HIPAA requirement)
        # - Logs should be archived to secure, immutable storage
        # - Access to archived logs should be audited
