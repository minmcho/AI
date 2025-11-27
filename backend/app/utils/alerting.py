"""
Alerting and notification system for critical events

Monitors and alerts on:
- HIPAA compliance violations
- System health issues
- Security incidents
- Data breaches
- Failed backups
"""

import logging
from datetime import datetime
from typing import Dict, Any, Optional, List
from enum import Enum
from pydantic import BaseModel


class AlertSeverity(str, Enum):
    """Alert severity levels"""
    INFO = "info"
    WARNING = "warning"
    ERROR = "error"
    CRITICAL = "critical"


class AlertType(str, Enum):
    """Types of alerts"""
    HIPAA_VIOLATION = "hipaa_violation"
    SECURITY_INCIDENT = "security_incident"
    SYSTEM_HEALTH = "system_health"
    DATA_BREACH = "data_breach"
    BACKUP_FAILURE = "backup_failure"
    ENCRYPTION_ERROR = "encryption_error"
    AUDIT_LOG_FAILURE = "audit_log_failure"
    UNAUTHORIZED_PHI_ACCESS = "unauthorized_phi_access"
    RATE_LIMIT_EXCEEDED = "rate_limit_exceeded"
    DATABASE_ERROR = "database_error"


class Alert(BaseModel):
    """Alert model"""
    severity: AlertSeverity
    alert_type: AlertType
    message: str
    timestamp: datetime
    details: Optional[Dict[str, Any]] = None
    resolved: bool = False
    resolved_at: Optional[datetime] = None


class AlertingService:
    """
    Alerting service for critical events

    In production, integrate with:
    - Email notifications (SMTP)
    - SMS alerts (Twilio, SNS)
    - Slack/Discord webhooks
    - PagerDuty for on-call rotations
    - CloudWatch/DataDog for monitoring dashboards
    """

    def __init__(self):
        self.logger = logging.getLogger(__name__)
        self.active_alerts: List[Alert] = []

    def send_alert(
        self,
        severity: AlertSeverity,
        alert_type: AlertType,
        message: str,
        details: Optional[Dict[str, Any]] = None
    ) -> Alert:
        """
        Send an alert

        Args:
            severity: Alert severity level
            alert_type: Type of alert
            message: Human-readable alert message
            details: Additional context and data

        Returns:
            Alert object
        """
        alert = Alert(
            severity=severity,
            alert_type=alert_type,
            message=message,
            timestamp=datetime.utcnow(),
            details=details or {}
        )

        # Log the alert
        log_level = {
            AlertSeverity.INFO: logging.INFO,
            AlertSeverity.WARNING: logging.WARNING,
            AlertSeverity.ERROR: logging.ERROR,
            AlertSeverity.CRITICAL: logging.CRITICAL
        }[severity]

        self.logger.log(
            log_level,
            f"[{alert_type.value}] {message}",
            extra={"alert": alert.dict()}
        )

        # Store active alert
        self.active_alerts.append(alert)

        # In production, send actual notifications
        self._send_notification(alert)

        return alert

    def _send_notification(self, alert: Alert):
        """
        Send notification through configured channels

        In production, implement:
        - Email for WARNING and above
        - SMS for ERROR and above
        - PagerDuty for CRITICAL
        """
        if alert.severity == AlertSeverity.CRITICAL:
            self.logger.critical(f"CRITICAL ALERT: {alert.message}")
            # TODO: Send to PagerDuty
            # TODO: Send SMS to on-call engineer

        if alert.severity in [AlertSeverity.ERROR, AlertSeverity.CRITICAL]:
            # TODO: Send email to security team
            # TODO: Post to Slack #alerts channel
            pass

    def alert_hipaa_violation(self, violation_type: str, user_id: Optional[int] = None, details: Dict[str, Any] = None):
        """Alert on potential HIPAA violation"""
        return self.send_alert(
            severity=AlertSeverity.CRITICAL,
            alert_type=AlertType.HIPAA_VIOLATION,
            message=f"HIPAA compliance violation detected: {violation_type}",
            details={
                "violation_type": violation_type,
                "user_id": user_id,
                **(details or {})
            }
        )

    def alert_security_incident(self, incident_type: str, details: Dict[str, Any] = None):
        """Alert on security incident"""
        return self.send_alert(
            severity=AlertSeverity.CRITICAL,
            alert_type=AlertType.SECURITY_INCIDENT,
            message=f"Security incident detected: {incident_type}",
            details={
                "incident_type": incident_type,
                **(details or {})
            }
        )

    def alert_data_breach(self, affected_records: int, breach_type: str, details: Dict[str, Any] = None):
        """Alert on potential data breach"""
        return self.send_alert(
            severity=AlertSeverity.CRITICAL,
            alert_type=AlertType.DATA_BREACH,
            message=f"CRITICAL: Potential data breach detected affecting {affected_records} records",
            details={
                "affected_records": affected_records,
                "breach_type": breach_type,
                **(details or {})
            }
        )

    def alert_unauthorized_phi_access(self, user_id: int, resource_type: str, resource_id: int):
        """Alert on unauthorized PHI access attempt"""
        return self.send_alert(
            severity=AlertSeverity.ERROR,
            alert_type=AlertType.UNAUTHORIZED_PHI_ACCESS,
            message=f"Unauthorized PHI access attempt by user {user_id}",
            details={
                "user_id": user_id,
                "resource_type": resource_type,
                "resource_id": resource_id
            }
        )

    def alert_encryption_error(self, error_message: str, details: Dict[str, Any] = None):
        """Alert on encryption/decryption failure"""
        return self.send_alert(
            severity=AlertSeverity.CRITICAL,
            alert_type=AlertType.ENCRYPTION_ERROR,
            message=f"Encryption system error: {error_message}",
            details=details
        )

    def alert_audit_log_failure(self, error_message: str, details: Dict[str, Any] = None):
        """Alert on audit logging failure (HIPAA violation)"""
        return self.send_alert(
            severity=AlertSeverity.CRITICAL,
            alert_type=AlertType.AUDIT_LOG_FAILURE,
            message=f"CRITICAL: Audit logging failure - {error_message}",
            details=details
        )

    def alert_backup_failure(self, backup_type: str, error_message: str):
        """Alert on backup failure"""
        return self.send_alert(
            severity=AlertSeverity.ERROR,
            alert_type=AlertType.BACKUP_FAILURE,
            message=f"Backup failure ({backup_type}): {error_message}",
            details={"backup_type": backup_type, "error": error_message}
        )

    def alert_system_health(self, component: str, status: str, details: Dict[str, Any] = None):
        """Alert on system health degradation"""
        severity = AlertSeverity.ERROR if status == "unhealthy" else AlertSeverity.WARNING

        return self.send_alert(
            severity=severity,
            alert_type=AlertType.SYSTEM_HEALTH,
            message=f"System health {status}: {component}",
            details={
                "component": component,
                "status": status,
                **(details or {})
            }
        )

    def alert_database_error(self, error_type: str, error_message: str):
        """Alert on database errors"""
        return self.send_alert(
            severity=AlertSeverity.CRITICAL,
            alert_type=AlertType.DATABASE_ERROR,
            message=f"Database error ({error_type}): {error_message}",
            details={"error_type": error_type, "error": error_message}
        )

    def resolve_alert(self, alert: Alert, resolution_notes: Optional[str] = None):
        """Mark an alert as resolved"""
        alert.resolved = True
        alert.resolved_at = datetime.utcnow()

        self.logger.info(
            f"Alert resolved: {alert.message}",
            extra={"resolution_notes": resolution_notes}
        )

    def get_active_alerts(self, severity: Optional[AlertSeverity] = None) -> List[Alert]:
        """Get active (unresolved) alerts, optionally filtered by severity"""
        active = [a for a in self.active_alerts if not a.resolved]

        if severity:
            active = [a for a in active if a.severity == severity]

        return active

    def get_critical_alerts(self) -> List[Alert]:
        """Get all active critical alerts"""
        return self.get_active_alerts(severity=AlertSeverity.CRITICAL)


# Global alerting service instance
alerting_service = AlertingService()


# Configuration for alert thresholds and rules
class AlertConfig:
    """Alert configuration and thresholds"""

    # System health thresholds
    DISK_USAGE_WARNING = 85.0  # Alert at 85% disk usage
    DISK_USAGE_CRITICAL = 95.0  # Critical at 95%
    MEMORY_USAGE_WARNING = 80.0  # Alert at 80% memory
    MEMORY_USAGE_CRITICAL = 90.0  # Critical at 90%
    CPU_USAGE_WARNING = 75.0  # Alert at 75% CPU
    CPU_USAGE_CRITICAL = 90.0  # Critical at 90%

    # Response time thresholds (ms)
    RESPONSE_TIME_WARNING = 1000  # Warn if avg > 1s
    RESPONSE_TIME_CRITICAL = 5000  # Critical if avg > 5s

    # Error rate thresholds (%)
    ERROR_RATE_WARNING = 5.0  # Warn if > 5% errors
    ERROR_RATE_CRITICAL = 10.0  # Critical if > 10% errors

    # Database latency thresholds (ms)
    DB_LATENCY_WARNING = 500  # Warn if > 500ms
    DB_LATENCY_CRITICAL = 2000  # Critical if > 2s

    # Security thresholds
    FAILED_LOGIN_THRESHOLD = 5  # Alert after 5 failed logins from same IP
    RATE_LIMIT_VIOLATION_THRESHOLD = 10  # Alert after 10 rate limit violations

    # HIPAA compliance
    AUDIT_LOG_GAP_THRESHOLD_MINUTES = 60  # Alert if no audit logs for 1 hour
    PHI_ACCESS_WITHOUT_AUDIT_LOG = True  # Always alert (critical violation)

    # Backup and disaster recovery
    BACKUP_FAILURE_CONSECUTIVE_THRESHOLD = 2  # Alert after 2 consecutive failures
    BACKUP_AGE_WARNING_HOURS = 24  # Warn if no backup in 24 hours
    BACKUP_AGE_CRITICAL_HOURS = 48  # Critical if no backup in 48 hours
