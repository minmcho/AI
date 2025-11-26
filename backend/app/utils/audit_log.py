"""
HIPAA-compliant audit logging system

This module provides comprehensive audit logging for all PHI access and modifications.
HIPAA requires detailed audit trails of who accessed what data, when, and why.

Audit Log Requirements:
- User identification
- Date and time of access
- Type of access (create, read, update, delete)
- Description of data accessed
- Source of access (IP address, device)
- Outcome of the access attempt
"""

from sqlalchemy import Column, Integer, String, DateTime, JSON, Text, Index
from sqlalchemy.sql import func
from datetime import datetime
from enum import Enum
from typing import Optional, Dict, Any
from app.db.database import Base
import json


class AuditAction(str, Enum):
    """Types of actions that can be audited"""
    # PHI Access
    PHI_READ = "phi_read"
    PHI_CREATE = "phi_create"
    PHI_UPDATE = "phi_update"
    PHI_DELETE = "phi_delete"
    PHI_EXPORT = "phi_export"

    # Authentication
    LOGIN_SUCCESS = "login_success"
    LOGIN_FAILURE = "login_failure"
    LOGOUT = "logout"
    PASSWORD_CHANGE = "password_change"
    PASSWORD_RESET = "password_reset"

    # Data Subject Rights (GDPR)
    DATA_EXPORT_REQUEST = "data_export_request"
    DATA_DELETE_REQUEST = "data_delete_request"
    CONSENT_GRANTED = "consent_granted"
    CONSENT_REVOKED = "consent_revoked"

    # Sharing
    DATA_SHARED = "data_shared"
    DATA_UNSHARED = "data_unshared"

    # Administrative
    ACCOUNT_CREATED = "account_created"
    ACCOUNT_DELETED = "account_deleted"
    ACCOUNT_LOCKED = "account_locked"
    ACCOUNT_UNLOCKED = "account_unlocked"


class AuditLog(Base):
    """
    HIPAA-compliant audit log table

    Stores immutable audit records for compliance and security monitoring.
    """
    __tablename__ = "audit_logs"

    id = Column(Integer, primary_key=True, index=True)

    # Who
    user_id = Column(Integer, index=True, nullable=True)  # NULL for anonymous/system actions
    username = Column(String, index=True, nullable=True)
    actor_type = Column(String)  # user, system, admin, api_client

    # What
    action = Column(String, nullable=False, index=True)  # AuditAction enum value
    resource_type = Column(String, nullable=False, index=True)  # user, meal_plan, medical_record, etc.
    resource_id = Column(String, index=True)  # ID of the resource accessed
    description = Column(Text)  # Human-readable description

    # Details
    changes = Column(JSON)  # Before/after values (PHI must be masked)
    metadata = Column(JSON)  # Additional context

    # When
    timestamp = Column(DateTime(timezone=True), server_default=func.now(), nullable=False, index=True)

    # Where/How
    ip_address = Column(String)  # Source IP address
    user_agent = Column(String)  # Browser/device info
    request_id = Column(String, index=True)  # Correlation ID for request tracing

    # Outcome
    success = Column(Integer, default=1)  # 1=success, 0=failure
    error_message = Column(Text)  # If failed, why?

    # HIPAA-specific
    phi_accessed = Column(Integer, default=0)  # 1=PHI was accessed, 0=no PHI
    legal_basis = Column(String)  # GDPR: legal basis for processing (consent, contract, etc.)

    # Indexes for fast querying
    __table_args__ = (
        Index('idx_user_timestamp', 'user_id', 'timestamp'),
        Index('idx_action_timestamp', 'action', 'timestamp'),
        Index('idx_resource', 'resource_type', 'resource_id'),
        Index('idx_phi_access', 'phi_accessed', 'timestamp'),
    )


class AuditLogger:
    """Service for creating audit log entries"""

    @staticmethod
    async def log(
        db,
        action: AuditAction,
        resource_type: str,
        resource_id: Optional[str] = None,
        user_id: Optional[int] = None,
        username: Optional[str] = None,
        description: Optional[str] = None,
        changes: Optional[Dict] = None,
        metadata: Optional[Dict] = None,
        ip_address: Optional[str] = None,
        user_agent: Optional[str] = None,
        request_id: Optional[str] = None,
        success: bool = True,
        error_message: Optional[str] = None,
        phi_accessed: bool = False,
        legal_basis: Optional[str] = None
    ):
        """
        Create an audit log entry

        Args:
            db: Database session
            action: Type of action performed
            resource_type: Type of resource (e.g., 'user', 'medical_record')
            resource_id: ID of the resource
            user_id: ID of user performing action
            username: Username of user
            description: Human-readable description
            changes: Dictionary of changes (will be sanitized)
            metadata: Additional context
            ip_address: Source IP
            user_agent: User agent string
            request_id: Request correlation ID
            success: Whether action succeeded
            error_message: Error details if failed
            phi_accessed: Whether PHI was involved
            legal_basis: GDPR legal basis (consent, contract, etc.)
        """
        # Sanitize changes to remove sensitive data
        sanitized_changes = None
        if changes:
            sanitized_changes = AuditLogger._sanitize_phi(changes)

        log_entry = AuditLog(
            user_id=user_id,
            username=username,
            actor_type="user" if user_id else "system",
            action=action.value,
            resource_type=resource_type,
            resource_id=str(resource_id) if resource_id else None,
            description=description,
            changes=sanitized_changes,
            metadata=metadata,
            ip_address=ip_address,
            user_agent=user_agent,
            request_id=request_id,
            success=1 if success else 0,
            error_message=error_message,
            phi_accessed=1 if phi_accessed else 0,
            legal_basis=legal_basis
        )

        db.add(log_entry)
        await db.commit()

        return log_entry

    @staticmethod
    def _sanitize_phi(data: Dict) -> Dict:
        """
        Sanitize PHI from audit logs

        Only log metadata about changes, not actual PHI values.
        """
        sanitized = {}

        # Fields that should be masked
        phi_fields = {
            'medical_condition', 'diagnosis', 'medication', 'ssn',
            'medical_record_number', 'insurance_id', 'treatment_plan',
            'lab_results', 'prescription', 'medical_notes'
        }

        for key, value in data.items():
            if key.lower() in phi_fields:
                # Log that field changed, but not the value
                sanitized[key] = "[PHI-REDACTED]"
            elif isinstance(value, dict):
                sanitized[key] = AuditLogger._sanitize_phi(value)
            elif isinstance(value, list):
                sanitized[key] = f"[List with {len(value)} items]"
            else:
                sanitized[key] = value

        return sanitized

    @staticmethod
    async def log_phi_access(
        db,
        user_id: int,
        username: str,
        resource_type: str,
        resource_id: str,
        action: AuditAction,
        description: str,
        ip_address: Optional[str] = None,
        user_agent: Optional[str] = None,
        legal_basis: str = "consent"
    ):
        """
        Convenience method for logging PHI access

        Args:
            db: Database session
            user_id: User accessing PHI
            username: Username
            resource_type: Type of PHI resource
            resource_id: ID of resource
            action: Action performed
            description: What was accessed
            ip_address: Source IP
            user_agent: User agent
            legal_basis: Legal basis for access
        """
        await AuditLogger.log(
            db=db,
            action=action,
            resource_type=resource_type,
            resource_id=resource_id,
            user_id=user_id,
            username=username,
            description=description,
            ip_address=ip_address,
            user_agent=user_agent,
            phi_accessed=True,
            legal_basis=legal_basis,
            success=True
        )

    @staticmethod
    async def log_login_attempt(
        db,
        username: str,
        success: bool,
        ip_address: str,
        user_agent: str,
        error_message: Optional[str] = None,
        user_id: Optional[int] = None
    ):
        """Log authentication attempts for security monitoring"""
        action = AuditAction.LOGIN_SUCCESS if success else AuditAction.LOGIN_FAILURE

        await AuditLogger.log(
            db=db,
            action=action,
            resource_type="authentication",
            user_id=user_id,
            username=username,
            description=f"Login attempt for {username}",
            ip_address=ip_address,
            user_agent=user_agent,
            success=success,
            error_message=error_message
        )

    @staticmethod
    async def log_data_export(
        db,
        user_id: int,
        username: str,
        export_format: str,
        ip_address: str,
        user_agent: str
    ):
        """Log GDPR data export requests"""
        await AuditLogger.log(
            db=db,
            action=AuditAction.DATA_EXPORT_REQUEST,
            resource_type="user_data",
            resource_id=str(user_id),
            user_id=user_id,
            username=username,
            description=f"User requested data export in {export_format} format",
            metadata={"export_format": export_format},
            ip_address=ip_address,
            user_agent=user_agent,
            phi_accessed=True,
            legal_basis="data_subject_rights"
        )

    @staticmethod
    async def log_data_deletion(
        db,
        user_id: int,
        username: str,
        ip_address: str,
        user_agent: str,
        reason: Optional[str] = None
    ):
        """Log GDPR right to be forgotten requests"""
        await AuditLogger.log(
            db=db,
            action=AuditAction.DATA_DELETE_REQUEST,
            resource_type="user_data",
            resource_id=str(user_id),
            user_id=user_id,
            username=username,
            description=f"User requested account deletion",
            metadata={"reason": reason} if reason else None,
            ip_address=ip_address,
            user_agent=user_agent,
            phi_accessed=True,
            legal_basis="data_subject_rights"
        )


# Singleton instance
audit_logger = AuditLogger()
