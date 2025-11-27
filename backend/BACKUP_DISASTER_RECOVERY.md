# Backup and Disaster Recovery Plan

## Overview

This document outlines the backup and disaster recovery (DR) strategy for the NutriVision AI backend, ensuring:
- **HIPAA Compliance**: 7-year data retention for PHI
- **Business Continuity**: Minimal downtime in case of disasters
- **Data Integrity**: Point-in-time recovery capabilities
- **Security**: Encrypted backups with access controls

## Backup Strategy

### 1. Database Backups

#### Full Database Backups
- **Frequency**: Daily at 2:00 AM UTC
- **Retention**:
  - Daily backups: 30 days
  - Weekly backups (Sunday): 1 year
  - Monthly backups (1st of month): 7 years (HIPAA requirement)
- **Storage**: Encrypted PostgreSQL dumps
- **Location**:
  - Primary: AWS S3 (encrypted, versioned)
  - Secondary: AWS S3 in different region (cross-region replication)

```bash
# Example backup command
pg_dump -h $DB_HOST -U $DB_USER -d nutrivision_db \
  | gzip | \
  gpg --encrypt --recipient backup@nutrivision.ai \
  > backup_$(date +%Y%m%d_%H%M%S).sql.gz.gpg

# Upload to S3
aws s3 cp backup_*.sql.gz.gpg s3://nutrivision-backups/database/full/ \
  --server-side-encryption AES256 \
  --storage-class STANDARD_IA
```

#### Incremental Backups (WAL Archiving)
- **Frequency**: Continuous (Write-Ahead Log streaming)
- **Retention**: 7 days
- **Purpose**: Point-in-time recovery (PITR)

```bash
# Enable WAL archiving in postgresql.conf
wal_level = replica
archive_mode = on
archive_command = 'aws s3 cp %p s3://nutrivision-backups/wal/%f'
```

### 2. PHI Data Backups (HIPAA Critical)

#### Audit Logs
- **Frequency**: Real-time replication + daily backup
- **Retention**: 6 years minimum (HIPAA requirement)
- **Storage**: Write-once, read-many (WORM) compliant storage
- **Encryption**: AES-256 encryption at rest

```python
# Automated audit log archival
async def archive_audit_logs():
    """
    Archive audit logs older than 30 days to long-term storage

    HIPAA requires 6-year retention of audit logs
    """
    # Export logs older than 30 days
    # Encrypt with archive encryption key
    # Upload to S3 Glacier for cost-effective long-term storage
    # Verify backup integrity
    pass
```

#### Medical Records (Encrypted Fields)
- All PHI is encrypted at field-level in database
- Backup encryption keys separately from data
- Store encryption keys in AWS KMS or HashiCorp Vault

### 3. Application Code and Configuration

#### Git Repository
- **Strategy**: All code in version control (GitHub)
- **Branches**: Protected main/production branches
- **Backup**: GitHub automatic backups + mirror to GitLab

#### Configuration Files
- **Frequency**: On change + daily
- **Storage**: S3 with versioning enabled
- **Encryption**: Server-side encryption (SSE-KMS)

```bash
# Backup configuration
tar -czf config_backup_$(date +%Y%m%d).tar.gz \
  .env.production \
  alembic.ini \
  docker-compose.yml

aws s3 cp config_backup_*.tar.gz \
  s3://nutrivision-backups/config/ \
  --server-side-encryption aws:kms \
  --sse-kms-key-id alias/nutrivision-backup-key
```

### 4. AI Models and Vector Databases

#### Model Artifacts
- **Frequency**: On model updates
- **Storage**: S3 with versioning
- **Retention**: Last 5 versions

#### ChromaDB (Vector Database)
- **Frequency**: Daily
- **Method**: Snapshot of entire collection
- **Retention**: 30 days

```python
# Backup ChromaDB
import chromadb
import shutil

def backup_chromadb():
    """Backup vector database"""
    # Create snapshot
    shutil.make_archive(
        f'chromadb_backup_{date.today()}',
        'gztar',
        '/path/to/chromadb/persist'
    )
    # Upload to S3
```

### 5. User-Generated Content

#### Meal Photos and Food Images
- **Storage**: S3 with lifecycle policies
- **Backup**: Cross-region replication
- **Retention**: 7 years (linked to user data retention)

## Disaster Recovery Procedures

### Recovery Time Objective (RTO)
- **Critical Services (API)**: 1 hour
- **Database**: 2 hours
- **Full System**: 4 hours

### Recovery Point Objective (RPO)
- **Database**: 15 minutes (via WAL archiving)
- **Audit Logs**: Real-time (replicated)
- **User Data**: 24 hours

### DR Scenarios and Procedures

#### Scenario 1: Database Corruption

**Detection:**
- Health check failures
- Query errors
- Data integrity violations

**Recovery Steps:**
```bash
# 1. Stop application
kubectl scale deployment nutrivision-api --replicas=0

# 2. Restore from latest full backup
aws s3 cp s3://nutrivision-backups/database/full/latest.sql.gz.gpg .
gpg --decrypt latest.sql.gz.gpg | gunzip | psql -h $DB_HOST -U $DB_USER nutrivision_db

# 3. Replay WAL logs for point-in-time recovery
pg_waldump /path/to/wal/archive

# 4. Verify data integrity
psql -c "SELECT COUNT(*) FROM audit_logs WHERE timestamp > NOW() - INTERVAL '1 day';"

# 5. Restart application
kubectl scale deployment nutrivision-api --replicas=3
```

#### Scenario 2: Complete Region Failure (AWS)

**Recovery Steps:**
1. **DNS Failover**: Update Route53 to point to secondary region
2. **Database**: Promote read replica to primary
3. **Application**: Deploy from latest Docker images in secondary region
4. **Verify**: Run health checks and smoke tests
5. **Monitor**: Observe metrics for 24 hours

```bash
# Promote read replica
aws rds promote-read-replica \
  --db-instance-identifier nutrivision-db-replica-us-west-2

# Update DNS
aws route53 change-resource-record-sets \
  --hosted-zone-id Z123456789 \
  --change-batch file://dns-failover.json
```

#### Scenario 3: Ransomware Attack

**Detection:**
- Unusual encryption activity
- Mass file modifications
- Failed backup verifications

**Response:**
```bash
# 1. ISOLATE immediately - disconnect from network
iptables -A INPUT -j DROP
iptables -A OUTPUT -j DROP

# 2. Preserve evidence for forensics
dd if=/dev/sda of=/mnt/forensics/sda_image.dd bs=64K conv=noerror,sync

# 3. Alert security team and authorities
curl -X POST https://alerts.nutrivision.ai/security/incident \
  -d '{"type": "ransomware", "severity": "critical"}'

# 4. Restore from known-good backup (before infection)
# Use backup from 24-48 hours before attack detected

# 5. Change ALL credentials and encryption keys
```

#### Scenario 4: Data Center Failure

**Recovery:**
1. Activate disaster recovery site
2. Restore database from S3 backups
3. Deploy application containers
4. Update load balancer configuration
5. Verify all services operational

### Backup Verification

#### Automated Verification
```python
async def verify_backup():
    """
    Verify backup integrity and restorability

    Runs daily on latest backup
    """
    # 1. Download latest backup
    backup_file = download_latest_backup()

    # 2. Decrypt and decompress
    decrypted = decrypt_backup(backup_file)

    # 3. Restore to test database
    restore_to_test_db(decrypted)

    # 4. Run integrity checks
    integrity_ok = verify_data_integrity()

    # 5. Alert if verification fails
    if not integrity_ok:
        send_alert("Backup verification failed!")

    return integrity_ok
```

#### Manual Verification (Monthly)
- Full restore test to staging environment
- Verify data integrity and completeness
- Test application functionality
- Document results in compliance log

## Encryption Key Management

### Key Storage
- **Production Keys**: AWS KMS (Hardware Security Module backed)
- **Backup Keys**: Separate KMS key for backup encryption
- **Key Rotation**: Quarterly rotation schedule

### Key Recovery
```bash
# Export encryption key for disaster recovery
aws kms get-public-key \
  --key-id alias/nutrivision-master-key \
  > master_key_public.pem

# Store in secure offline location (safe deposit box)
```

## Monitoring and Alerting

### Backup Monitoring
```python
from app.utils.alerting import alerting_service, AlertSeverity

# Alert on backup failure
if backup_failed:
    alerting_service.alert_backup_failure(
        backup_type="database_full",
        error_message="Backup process exited with code 1"
    )

# Alert on old backups
if last_backup_age > timedelta(hours=26):
    alerting_service.send_alert(
        severity=AlertSeverity.WARNING,
        alert_type=AlertType.BACKUP_FAILURE,
        message=f"No successful backup in {last_backup_age} hours"
    )
```

### Metrics to Monitor
- Backup success/failure rate
- Backup size trends
- Backup duration
- Restore test success rate
- Time since last successful backup
- Available storage capacity

## Compliance Requirements

### HIPAA
- ✅ 7-year retention of PHI and audit logs
- ✅ Encrypted backups (AES-256)
- ✅ Backup integrity verification
- ✅ Secure backup storage with access controls
- ✅ Backup restoration procedures documented
- ✅ Regular testing of backup restoration

### GDPR
- ✅ Ability to delete user data upon request
- ✅ Data portability from backups
- ✅ Backup retention policies documented
- ✅ Cross-border data transfer compliance (EU to US)

## Backup Schedule Summary

| Data Type | Frequency | Retention | Storage |
|-----------|-----------|-----------|---------|
| Full DB | Daily | 7 years | S3 Standard → Glacier |
| WAL Logs | Continuous | 7 days | S3 Standard |
| Audit Logs | Real-time | 6 years | S3 WORM |
| Config | On change | 1 year | S3 Versioned |
| AI Models | On update | Last 5 | S3 Versioned |
| User Photos | Real-time | 7 years | S3 + Cross-region |

## Runbook for Common Tasks

### Restore Single Table
```bash
pg_restore -h $DB_HOST -U $DB_USER \
  -d nutrivision_db \
  --table=users \
  backup_20240101.dump
```

### Restore Specific Time Point
```bash
# Restore to 2024-01-15 14:30:00
pg_restore_pitr \
  --target-time="2024-01-15 14:30:00" \
  --backup-location=s3://nutrivision-backups/database/full/latest.sql.gz.gpg \
  --wal-location=s3://nutrivision-backups/wal/
```

### Test Disaster Recovery
```bash
# Quarterly DR drill
./scripts/dr_drill.sh \
  --scenario=region_failure \
  --dry-run=false \
  --notify-team=true
```

## Contact Information

### On-Call Rotation
- **Primary**: DevOps Team (PagerDuty)
- **Secondary**: CTO
- **Escalation**: CEO + Legal (for data breaches)

### External Contacts
- **AWS Support**: Enterprise support line
- **Security Incident Response**: security@nutrivision.ai
- **Legal/Compliance**: legal@nutrivision.ai

## Review and Updates

- **Review Frequency**: Quarterly
- **Last Updated**: 2024-01-20
- **Next Review**: 2024-04-20
- **Owner**: DevOps Team Lead
