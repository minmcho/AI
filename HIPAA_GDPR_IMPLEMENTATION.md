# HIPAA & GDPR Compliance Implementation Guide

## Overview

This document describes the comprehensive HIPAA (Health Insurance Portability and Accountability Act) and GDPR (General Data Protection Regulation) compliance features implemented in NutriVision AI backend.

**Implementation Date:** November 2025
**Compliance Frameworks:** HIPAA, GDPR, CCPA, iOS App Store Privacy
**Author:** Claude AI Development Team

---

## Table of Contents

1. [Features Implemented](#features-implemented)
2. [HIPAA Compliance](#hipaa-compliance)
3. [GDPR Compliance](#gdpr-compliance)
4. [Micronutrient Tracking](#micronutrient-tracking)
5. [Treatment-Specific Diets](#treatment-specific-diets)
6. [Architecture](#architecture)
7. [API Endpoints](#api-endpoints)
8. [Setup Instructions](#setup-instructions)
9. [Security Best Practices](#security-best-practices)
10. [iOS Integration](#ios-integration)

---

## Features Implemented

### 🔒 Security & Compliance
- ✅ **Field-level encryption** for PHI/PII using AES-256-GCM
- ✅ **Comprehensive audit logging** for all PHI access
- ✅ **GDPR consent management** with version tracking
- ✅ **Data portability** (export in JSON/CSV/PDF)
- ✅ **Right to be forgotten** (data deletion with verification)
- ✅ **HIPAA-compliant** access controls and audit trails

### 🏥 Medical Features
- ✅ **Micronutrient tracking** (vitamins, minerals, trace elements)
- ✅ **Treatment-specific diets** for medical conditions
- ✅ **Medical nutrition therapy** (MNT) protocols
- ✅ **Deficiency detection** and monitoring
- ✅ **Evidence-based dietary recommendations**
- ✅ **Clinical guidelines** integration

### 📱 iOS & Mobile
- ✅ **App Store privacy compliance**
- ✅ **Account deletion API**
- ✅ **Privacy dashboard**
- ✅ **Consent management UI**

---

## HIPAA Compliance

### Protected Health Information (PHI)

**Definition**: Any individually identifiable health information including:
- Medical conditions and diagnoses
- Treatment plans and prescriptions
- Lab results and test data
- Healthcare provider information
- Medical record numbers

### Implementation

#### 1. Encryption at Rest
```python
from app.utils.encryption import FieldEncryption

# Initialize encryptor
encryptor = FieldEncryption(settings.ENCRYPTION_KEY)

# Encrypt PHI field
encrypted_condition = encryptor.encrypt(
    "Type 2 Diabetes",
    associated_data=f"user_{user_id}"
)
```

**Encrypted Fields:**
- `UserMedicalProfile.conditions`
- `UserMedicalProfile.medications`
- `UserMedicalProfile.primary_care_provider`
- `MicronutrientDeficiency.symptoms`
- `MicronutrientDeficiency.lab_results`
- `DietPrescription.prescribed_by`
- `DietPrescription.special_instructions`

#### 2. Audit Logging
```python
from app.utils.audit_log import audit_logger, AuditAction

# Log PHI access
await audit_logger.log_phi_access(
    db=db,
    user_id=user.id,
    username=user.username,
    resource_type="medical_profile",
    resource_id=str(profile.id),
    action=AuditAction.PHI_READ,
    description="Viewed medical profile",
    ip_address=client_ip,
    user_agent=user_agent,
    legal_basis="medical_care"
)
```

**Audit Log Includes:**
- Who accessed PHI
- When access occurred
- What was accessed
- Why it was accessed (legal basis)
- Where access originated (IP address)
- How it was accessed (device info)

#### 3. Access Controls
- Role-based access control (RBAC)
- Minimum necessary standard
- Authentication required for all PHI endpoints
- Session management with token expiration

#### 4. Data Retention
```python
# Configuration
DATA_RETENTION_DAYS = 2555  # 7 years (HIPAA requirement)
AUDIT_LOG_RETENTION_DAYS = 2190  # 6 years (HIPAA requirement)
```

### HIPAA Administrative Safeguards

✅ **Security Management Process**
- Risk analysis conducted
- Risk management strategies implemented
- Sanction policy for violations
- Information system activity review

✅ **Assigned Security Responsibility**
- Privacy Officer designated
- Security Officer designated
- Contact: compliance@nutrivision.ai

✅ **Workforce Security**
- Access authorization procedures
- Workforce clearance procedures
- Termination procedures

### HIPAA Technical Safeguards

✅ **Access Control**
- Unique user identification (user IDs)
- Emergency access procedure
- Automatic logoff (token expiration)
- Encryption and decryption (AES-256-GCM)

✅ **Audit Controls**
- Comprehensive audit logging
- Tamper-proof audit trails
- Regular audit log review

✅ **Integrity Controls**
- Data validation
- Error detection
- Checksums for data integrity

✅ **Transmission Security**
- HTTPS/TLS encryption
- Network security measures

---

## GDPR Compliance

### Data Subject Rights

#### 1. Right to Access (Article 15)
```
GET /privacy/dashboard
GET /privacy/audit-logs
```
Users can view all their personal data and how it's being processed.

#### 2. Right to Data Portability (Article 20)
```
POST /privacy/export-data
GET /privacy/export-data/{request_id}
```
Users can export their data in machine-readable format (JSON, CSV, PDF).

**Export Includes:**
- Profile information
- Health data
- Meal plans and nutrition logs
- Consent records
- Audit logs

#### 3. Right to Erasure (Article 17)
```
POST /privacy/delete-data
```
Users can request complete account and data deletion.

**Process:**
1. User submits deletion request
2. Identity verification required
3. Legal hold check
4. Data anonymization or deletion
5. Confirmation sent to user

#### 4. Right to Rectification (Article 16)
```
PUT /profile
PUT /medical-profile
```
Users can update incorrect personal data.

#### 5. Right to Restrict Processing (Article 18)
Users can limit how their data is used through consent management.

#### 6. Right to Object (Article 21)
Users can opt-out of specific data processing activities.

### Consent Management

```python
from app.utils.gdpr_compliance import ConsentType

# Available consent types
ConsentType.ESSENTIAL  # Required for service
ConsentType.ANALYTICS  # Usage analytics
ConsentType.MARKETING  # Marketing communications
ConsentType.PERSONALIZATION  # Personalized content
ConsentType.THIRD_PARTY_SHARING  # Share with partners
ConsentType.MEDICAL_DATA_PROCESSING  # Process health data
ConsentType.RESEARCH  # Use data for research
ConsentType.AI_TRAINING  # Use data to train AI
```

**Consent Properties:**
- ✅ Freely given
- ✅ Specific
- ✅ Informed
- ✅ Unambiguous
- ✅ Withdrawable

**Consent Recording:**
- Timestamp
- IP address
- User agent
- Policy version
- Exact consent text

### Legal Bases for Processing

```python
class LegalBasis(str, Enum):
    CONSENT = "consent"  # User gave consent
    CONTRACT = "contract"  # Necessary for contract
    LEGAL_OBLIGATION = "legal_obligation"  # Required by law
    VITAL_INTERESTS = "vital_interests"  # Life or death
    PUBLIC_TASK = "public_task"  # Public interest
    LEGITIMATE_INTERESTS = "legitimate_interests"  # Business interest
```

### Data Categories

```python
class DataCategory(str, Enum):
    BASIC_PROFILE = "basic_profile"
    CONTACT_INFO = "contact_info"
    DEMOGRAPHIC = "demographic"
    HEALTH_DATA = "health_data"  # Special category under GDPR
    DIETARY_DATA = "dietary_data"
    BIOMETRIC = "biometric"
    USAGE_DATA = "usage_data"
    LOCATION_DATA = "location_data"
    DEVICE_DATA = "device_data"
```

### Privacy by Design

✅ **Data Minimization**
- Collect only necessary data
- Delete data when no longer needed
- Pseudonymization where possible

✅ **Purpose Limitation**
- Data used only for stated purposes
- Consent required for new purposes

✅ **Storage Limitation**
- Automatic data expiration
- Retention policies enforced

✅ **Transparency**
- Clear privacy policy
- Privacy dashboard
- Audit logs accessible to users

---

## Micronutrient Tracking

### Overview

Comprehensive tracking of vitamins, minerals, and micronutrients for:
- Detailed nutritional analysis
- Deficiency detection
- Treatment planning
- Research and health insights

### Tracked Micronutrients

#### Vitamins - Fat Soluble
- Vitamin A (Retinol)
- Vitamin D (Calciferol)
- Vitamin E (Tocopherol)
- Vitamin K

#### Vitamins - Water Soluble
- Vitamin B1 (Thiamine)
- Vitamin B2 (Riboflavin)
- Vitamin B3 (Niacin)
- Vitamin B5 (Pantothenic Acid)
- Vitamin B6 (Pyridoxine)
- Vitamin B7 (Biotin)
- Vitamin B9 (Folate)
- Vitamin B12 (Cobalamin)
- Vitamin C (Ascorbic Acid)

#### Minerals - Major
- Calcium (Ca)
- Magnesium (Mg)
- Phosphorus (P)
- Potassium (K)
- Sodium (Na)
- Chloride (Cl)
- Sulfur (S)

#### Minerals - Trace Elements
- Iron (Fe)
- Zinc (Zn)
- Copper (Cu)
- Manganese (Mn)
- Selenium (Se)
- Iodine (I)
- Chromium (Cr)
- Molybdenum (Mo)
- Fluoride (F)

#### Other Nutrients
- Omega-3 Fatty Acids
- Omega-6 Fatty Acids
- Essential Amino Acids

### Features

**1. Personalized Targets**
```
POST /micronutrients/targets
```
Set customized daily targets based on:
- Age, sex, pregnancy status
- Medical conditions
- Athletic requirements
- Detected deficiencies

**2. Deficiency Tracking**
```
POST /micronutrients/deficiencies
GET /micronutrients/deficiencies
```
Record and monitor nutrient deficiencies with:
- Severity levels
- Lab results
- Symptoms
- Treatment plans

**3. Daily Intake Logging**
```
POST /micronutrients/intake/daily
```
Track micronutrient consumption from:
- Food
- Supplements
- Fortified foods

**4. Analysis & Insights**
```
GET /micronutrients/analysis/daily
```
Comprehensive analysis including:
- Deficiency detection
- Adequacy assessment
- Excessive intake warnings
- AI-generated recommendations
- Nutrition quality score

### Example API Usage

```python
# Set personalized vitamin D target
response = requests.post("/micronutrients/targets", json={
    "micronutrient_code": "VIT_D",
    "daily_target": 2000,
    "unit": "iu",
    "basis": "deficiency",
    "priority": "high",
    "notes": "Vitamin D deficiency detected in recent labs"
})

# Log daily intake
response = requests.post("/micronutrients/intake/daily", json={
    "date": "2025-11-26T00:00:00",
    "micronutrient_code": "VIT_D",
    "total_amount": 1500,
    "unit": "iu",
    "from_food": 300,
    "from_supplements": 1200
})
```

---

## Treatment-Specific Diets

### Overview

Evidence-based therapeutic diets for medical conditions.

### Supported Conditions

#### Metabolic
- Type 2 Diabetes (ICD-10: E11)
- Type 1 Diabetes (ICD-10: E10)
- Metabolic Syndrome
- Prediabetes

#### Cardiovascular
- Hypertension (ICD-10: I10)
- Heart Disease
- High Cholesterol
- Atherosclerosis

#### Gastrointestinal
- Irritable Bowel Syndrome (ICD-10: K58)
- Inflammatory Bowel Disease
- Celiac Disease
- GERD

#### Renal
- Chronic Kidney Disease (ICD-10: N18)
- Acute Kidney Injury
- Dialysis patients

#### Autoimmune
- Rheumatoid Arthritis
- Lupus
- Multiple Sclerosis

### Therapeutic Diets

**Metabolic**
- Diabetic Diet (low glycemic index, carb controlled)
- Ketogenic Diet (very low carb, high fat)
- Low Glycemic Diet

**Cardiovascular**
- DASH Diet (Dietary Approaches to Stop Hypertension)
- Mediterranean Diet
- Low Sodium Diet
- Heart-Healthy Diet

**Renal**
- Renal Diet (low protein, potassium, phosphorus)
- Dialysis Diet
- Low Phosphorus Diet
- Low Potassium Diet

**Gastrointestinal**
- Low FODMAP Diet (for IBS)
- IBD-Friendly Diet
- Anti-Inflammatory Diet
- Bland Diet

**Other**
- Gout-Friendly Diet (low purine)
- PCOS-Friendly Diet
- Anti-Cancer Diet
- Thyroid Support Diet

### Evidence Levels

```python
class EvidenceLevel(str, Enum):
    HIGH = "high"  # Multiple RCTs, meta-analyses
    MODERATE = "moderate"  # Some RCTs, observational studies
    LOW = "low"  # Expert opinion, case studies
    EMERGING = "emerging"  # New research
```

### Diet Prescriptions

**Creating a Prescription:**
```
POST /treatment-diets/prescriptions
```

**Prescription Includes:**
- Medical condition
- Treatment diet
- Prescribing provider
- Treatment goals
- Custom restrictions
- Monitoring requirements

### Example API Usage

```python
# Get AI diet recommendations for diabetes and hypertension
response = requests.post("/treatment-diets/recommendations/ai", json={
    "condition_codes": ["E11", "I10"],
    "preferences": {
        "difficulty": "moderate",
        "cultural_preference": "Mediterranean"
    },
    "severity_level": "moderate"
})

# Create formal diet prescription
response = requests.post("/treatment-diets/prescriptions", json={
    "medical_condition_code": "E11",
    "treatment_diet_code": "diabetic",
    "prescribed_by": "Dr. Jane Smith, RD",
    "provider_credentials": "RD, CDE",
    "start_date": "2025-11-26T00:00:00",
    "treatment_goals": [
        "Lower HbA1c below 7%",
        "Achieve 5% weight loss",
        "Improve insulin sensitivity"
    ],
    "custom_restrictions": ["Limit carbs to 45g per meal"]
})
```

---

## Architecture

### Database Models

**Core Tables:**
- `users` - User profiles
- `user_medical_profiles` - Medical history (PHI encrypted)
- `micronutrients` - Master micronutrient database
- `user_micronutrient_targets` - Personalized targets
- `micronutrient_deficiencies` - Deficiency records (PHI encrypted)
- `daily_micronutrient_intake` - Daily tracking
- `medical_conditions` - Supported conditions
- `treatment_diets` - Therapeutic diet protocols
- `diet_prescriptions` - Formal prescriptions (PHI encrypted)
- `user_consents` - GDPR consent records
- `audit_logs` - HIPAA audit trail
- `data_export_requests` - GDPR export requests
- `data_deletion_requests` - GDPR deletion requests

### Security Layers

```
┌─────────────────────────────────────────────────┐
│           Application Layer (FastAPI)            │
├─────────────────────────────────────────────────┤
│     Authentication (JWT) & Authorization         │
├─────────────────────────────────────────────────┤
│              Audit Logging Middleware            │
├─────────────────────────────────────────────────┤
│          Field-Level Encryption (PHI)            │
├─────────────────────────────────────────────────┤
│              Database (PostgreSQL)               │
├─────────────────────────────────────────────────┤
│          Encryption at Rest (Disk)               │
└─────────────────────────────────────────────────┘
```

---

## API Endpoints

### Micronutrients

| Method | Endpoint | Description | PHI |
|--------|----------|-------------|-----|
| GET | `/micronutrients/list` | List all micronutrients | No |
| GET | `/micronutrients/targets` | Get user's targets | Yes |
| POST | `/micronutrients/targets` | Set personalized target | Yes |
| POST | `/micronutrients/deficiencies` | Record deficiency | **Yes** |
| GET | `/micronutrients/deficiencies` | Get deficiencies | **Yes** |
| POST | `/micronutrients/intake/daily` | Log daily intake | Yes |
| GET | `/micronutrients/analysis/daily` | Daily analysis | Yes |

### Treatment Diets

| Method | Endpoint | Description | PHI |
|--------|----------|-------------|-----|
| GET | `/treatment-diets/conditions` | List medical conditions | No |
| GET | `/treatment-diets/diets` | List therapeutic diets | No |
| POST | `/treatment-diets/medical-profile` | Create medical profile | **Yes** |
| GET | `/treatment-diets/medical-profile` | Get profile summary | **Yes** |
| POST | `/treatment-diets/prescriptions` | Create prescription | **Yes** |
| GET | `/treatment-diets/prescriptions` | Get prescriptions | **Yes** |
| POST | `/treatment-diets/recommendations/ai` | Get AI recommendations | Yes |

### Privacy & Compliance

| Method | Endpoint | Description | GDPR |
|--------|----------|-------------|------|
| GET | `/privacy/consents` | Get consent records | ✅ |
| POST | `/privacy/consents` | Grant/revoke consent | ✅ |
| POST | `/privacy/export-data` | Request data export | ✅ |
| GET | `/privacy/export-data/{id}` | Download export | ✅ |
| POST | `/privacy/delete-data` | Request deletion | ✅ |
| GET | `/privacy/audit-logs` | Get audit logs | ✅ |
| GET | `/privacy/dashboard` | Privacy dashboard | ✅ |
| POST | `/privacy/privacy-policy/accept` | Accept policy | ✅ |
| GET | `/privacy/compliance/report` | Compliance status | ✅ |

---

## Setup Instructions

### 1. Generate Encryption Key

```bash
python -c "from app.utils.encryption import generate_encryption_key; print(generate_encryption_key())"
```

Copy the output to `.env`:
```bash
ENCRYPTION_KEY=your-generated-key-here
```

### 2. Configure Environment

Create `.env` file based on `.env.example`:
```bash
cp backend/.env.example backend/.env
```

Update required fields:
- `ENCRYPTION_KEY` (generated above)
- `SECRET_KEY` (generate with `openssl rand -hex 32`)
- `DATABASE_URL`
- Privacy officer emails

### 3. Run Database Migrations

```bash
# Initialize Alembic (if not done)
cd backend
alembic init alembic

# Create initial migration
alembic revision --autogenerate -m "Add HIPAA/GDPR compliance tables"

# Apply migrations
alembic upgrade head
```

### 4. Populate Micronutrients

```python
from app.models.micronutrients import ESSENTIAL_MICRONUTRIENTS
from app.db.database import AsyncSessionLocal

async def populate_micronutrients():
    async with AsyncSessionLocal() as session:
        for nutrient_data in ESSENTIAL_MICRONUTRIENTS:
            nutrient = Micronutrient(**nutrient_data)
            session.add(nutrient)
        await session.commit()
```

### 5. Test Encryption

```python
from app.utils.encryption import FieldEncryption
from app.config.settings import get_settings

settings = get_settings()
encryptor = FieldEncryption(settings.ENCRYPTION_KEY)

# Test encryption
encrypted = encryptor.encrypt("Sensitive Health Data")
decrypted = encryptor.decrypt(encrypted)

print(f"Encrypted: {encrypted}")
print(f"Decrypted: {decrypted}")
assert decrypted == "Sensitive Health Data"
```

### 6. Enable Audit Logging

Audit logging is enabled by default:
```python
ENABLE_AUDIT_LOGGING=True
```

All PHI access is automatically logged to `audit_logs` table.

---

## Security Best Practices

### 1. Encryption Keys

**DO:**
- ✅ Generate strong 256-bit keys
- ✅ Store keys in secure environment variables
- ✅ Use different keys for dev/staging/production
- ✅ Rotate keys periodically
- ✅ Use key management service (AWS KMS, Azure Key Vault)

**DON'T:**
- ❌ Hardcode keys in code
- ❌ Commit keys to version control
- ❌ Share keys via email/chat
- ❌ Use weak or short keys
- ❌ Reuse keys across environments

### 2. Access Control

**Principles:**
- Minimum necessary access
- Least privilege
- Role-based access control (RBAC)
- Regular access reviews

### 3. Audit Logging

**Best Practices:**
- Log all PHI access
- Include contextual information
- Store logs securely
- Retain for required period (6 years for HIPAA)
- Monitor logs regularly
- Alert on suspicious activity

### 4. Data Retention

**Policy:**
```python
# Health data: 7 years (HIPAA requirement)
DATA_RETENTION_DAYS = 2555

# Audit logs: 6 years (HIPAA requirement)
AUDIT_LOG_RETENTION_DAYS = 2190

# User data: Until deletion request
# Export data: 72 hours
```

### 5. Incident Response

**If PHI breach suspected:**
1. Immediately notify Privacy Officer
2. Investigate and contain
3. Document incident
4. Notify affected individuals (if >500: within 60 days)
5. Report to HHS if required
6. Implement corrective measures

### 6. Regular Security Assessments

- Annual risk assessments
- Quarterly vulnerability scans
- Penetration testing
- Code security reviews
- Dependency updates

---

## iOS Integration

### App Store Privacy Requirements

**Privacy Labels Supported:**
- ✅ Data used to track you
- ✅ Data linked to you
- ✅ Data not linked to you

**Data Practices:**
```json
{
  "health_data": {
    "collected": true,
    "linked_to_user": true,
    "used_for_tracking": false,
    "purposes": ["App Functionality", "Analytics"],
    "data_types": [
      "Health & Fitness",
      "Sensitive Info - Medical Records"
    ]
  },
  "account_deletion": {
    "available": true,
    "method": "In-App & Web"
  }
}
```

### Swift Integration Example

```swift
// Request data export
func exportUserData() {
    let url = URL(string: "\(baseURL)/privacy/export-data")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let body: [String: Any] = [
        "export_format": "json",
        "include_metadata": true
    ]
    request.httpBody = try? JSONSerialization.data(withJSONObject: body)

    URLSession.shared.dataTask(with: request) { data, response, error in
        // Handle response
    }.resume()
}

// Delete account
func deleteAccount() {
    let url = URL(string: "\(baseURL)/privacy/delete-data")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let body: [String: Any] = [
        "scope": "full",
        "confirmation": true,
        "reason": "User requested account deletion"
    ]
    request.httpBody = try? JSONSerialization.data(withJSONObject: body)

    URLSession.shared.dataTask(with: request) { data, response, error in
        // Handle response and logout
    }.resume()
}
```

---

## Compliance Checklist

### HIPAA

- [x] PHI encrypted at rest (AES-256-GCM)
- [x] PHI encrypted in transit (HTTPS/TLS)
- [x] Audit logging for all PHI access
- [x] Unique user identification
- [x] Access controls implemented
- [x] Data retention policies defined
- [x] Breach notification procedures
- [x] Business Associate Agreements (BAA) ready
- [x] Privacy Officer designated
- [x] Security Officer designated
- [ ] Annual risk assessment (TODO)
- [ ] Workforce training (TODO)

### GDPR

- [x] Lawful basis for processing
- [x] Consent management system
- [x] Right to access implemented
- [x] Right to data portability implemented
- [x] Right to erasure implemented
- [x] Right to rectification implemented
- [x] Data breach notification ready
- [x] Privacy by design
- [x] Data minimization
- [x] Purpose limitation
- [x] Storage limitation
- [x] DPO contact information
- [ ] Data Protection Impact Assessment (TODO)
- [ ] Records of processing activities (TODO)

### iOS App Store

- [x] Privacy policy URL configured
- [x] Data collection disclosure
- [x] Account deletion API
- [x] Data export API
- [x] Privacy labels support
- [x] Consent tracking

---

## Support & Contact

**Privacy Questions:**
- Email: privacy@nutrivision.ai
- Data Protection Officer: dpo@nutrivision.ai

**Security Issues:**
- Email: security@nutrivision.ai
- Bug Bounty: security@nutrivision.ai

**HIPAA Compliance:**
- Privacy Officer: compliance@nutrivision.ai

---

## License & Legal

This implementation guide is provided for informational purposes only and does not constitute legal advice. Consult with qualified legal counsel for compliance with HIPAA, GDPR, and other applicable regulations.

**Copyright © 2025 NutriVision AI. All rights reserved.**
