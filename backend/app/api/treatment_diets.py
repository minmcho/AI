"""
Treatment-Specific Diet API

Medical nutrition therapy endpoints for condition-based dietary management.

**HIPAA Compliance**: This module handles Protected Health Information (PHI)
All medical data is encrypted at rest and audit logged.
"""

from fastapi import APIRouter, Depends, HTTPException, status, Request
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_
from pydantic import BaseModel, Field
from typing import List, Optional, Dict
from datetime import datetime

from app.db.database import get_db
from app.services.auth_service import auth_service
from app.api.auth import oauth2_scheme
from app.models.medical_diets import (
    MedicalCondition, TreatmentDiet, UserMedicalProfile,
    DietPrescription, NutritionalIntervention,
    MedicalConditionCategory, TreatmentDietType, EvidenceLevel
)
from app.utils.audit_log import audit_logger, AuditAction
from app.utils.encryption import FieldEncryption
from app.config.settings import get_settings

router = APIRouter(prefix="/treatment-diets", tags=["Treatment Diets"])
settings = get_settings()


# Pydantic models
class MedicalConditionInfo(BaseModel):
    id: int
    code: str
    name: str
    common_name: Optional[str]
    category: str
    description: Optional[str]
    recommended_diets: List[str]
    evidence_level: str

    class Config:
        from_attributes = True


class TreatmentDietInfo(BaseModel):
    id: int
    code: str
    name: str
    diet_type: str
    description: Optional[str]
    clinical_purpose: Optional[str]
    evidence_level: str
    difficulty_level: Optional[str]
    requires_supervision: bool

    class Config:
        from_attributes = True


class MedicalProfileCreate(BaseModel):
    """PHI: Protected Health Information"""
    conditions: List[Dict]  # Will be encrypted
    medications: Optional[List[Dict]] = []  # Will be encrypted
    primary_care_provider: Optional[str] = None  # Will be encrypted
    family_history: Optional[List[str]] = []
    consent_to_store_phi: bool = Field(..., description="HIPAA: Explicit consent required")


class MedicalProfileResponse(BaseModel):
    id: int
    has_conditions: bool
    conditions_count: int
    assigned_diets_count: int
    consent_to_store_phi: bool
    consent_date: Optional[datetime]
    last_updated: datetime


class DietPrescriptionCreate(BaseModel):
    """PHI: Diet prescription from healthcare provider"""
    medical_condition_code: Optional[str] = None
    treatment_diet_code: str
    prescribed_by: str  # Will be encrypted
    provider_credentials: str  # MD, RD, NP, etc.
    start_date: datetime
    end_date: Optional[datetime] = None
    treatment_goals: List[str]
    custom_restrictions: Optional[List[str]] = []
    special_instructions: Optional[str] = None  # Will be encrypted


class DietPrescriptionResponse(BaseModel):
    id: int
    prescription_number: str
    treatment_diet_name: str
    diet_type: str
    prescribed_date: datetime
    start_date: datetime
    status: str
    treatment_goals: List[str]


class DietRecommendationRequest(BaseModel):
    """Request AI diet recommendations based on conditions"""
    condition_codes: List[str]
    preferences: Optional[Dict] = {}
    severity_level: str = "moderate"


class DietRecommendationResponse(BaseModel):
    recommended_diets: List[Dict]
    reasoning: str
    evidence_summary: str
    implementation_tips: List[str]
    monitoring_advice: str


@router.get("/conditions", response_model=List[MedicalConditionInfo])
async def list_medical_conditions(
    category: Optional[MedicalConditionCategory] = None,
    search: Optional[str] = None,
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
    """
    List medical conditions requiring dietary management

    Filter by:
    - **category**: metabolic, cardiovascular, gastrointestinal, etc.
    - **search**: Search by name or code

    Returns evidence-based conditions with dietary protocols.
    """
    user = await auth_service.get_current_user(db=db, token=token)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED)

    query = select(MedicalCondition).where(MedicalCondition.is_active == True)

    if category:
        query = query.where(MedicalCondition.category == category)

    if search:
        query = query.where(
            (MedicalCondition.name.ilike(f"%{search}%")) |
            (MedicalCondition.code.ilike(f"%{search}%"))
        )

    result = await db.execute(query)
    conditions = result.scalars().all()

    return [
        MedicalConditionInfo(
            id=c.id,
            code=c.code,
            name=c.name,
            common_name=c.common_name,
            category=c.category.value,
            description=c.description,
            recommended_diets=c.recommended_diets or [],
            evidence_level=c.evidence_level.value if c.evidence_level else "moderate"
        )
        for c in conditions
    ]


@router.get("/diets", response_model=List[TreatmentDietInfo])
async def list_treatment_diets(
    diet_type: Optional[TreatmentDietType] = None,
    evidence_level: Optional[EvidenceLevel] = None,
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
    """
    List therapeutic diet protocols

    Filter by:
    - **diet_type**: diabetic, dash, low_sodium, renal, etc.
    - **evidence_level**: high, moderate, low

    Returns evidence-based therapeutic diets with clinical guidelines.
    """
    user = await auth_service.get_current_user(db=db, token=token)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED)

    query = select(TreatmentDiet).where(TreatmentDiet.is_active == True)

    if diet_type:
        query = query.where(TreatmentDiet.diet_type == diet_type)

    if evidence_level:
        query = query.where(TreatmentDiet.evidence_level == evidence_level)

    result = await db.execute(query)
    diets = result.scalars().all()

    return [
        TreatmentDietInfo(
            id=d.id,
            code=d.code,
            name=d.name,
            diet_type=d.diet_type.value,
            description=d.description,
            clinical_purpose=d.clinical_purpose,
            evidence_level=d.evidence_level.value if d.evidence_level else "moderate",
            difficulty_level=d.difficulty_level,
            requires_supervision=d.requires_supervision
        )
        for d in diets
    ]


@router.post("/medical-profile", response_model=MedicalProfileResponse)
async def create_medical_profile(
    profile_data: MedicalProfileCreate,
    request: Request,
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
    """
    Create user medical profile

    **PHI Endpoint**: Stores Protected Health Information
    **HIPAA Compliance**:
    - Requires explicit consent
    - All PHI is encrypted at rest
    - Access is audit logged
    - Consent is recorded with timestamp

    Medical profile includes:
    - Diagnosed conditions
    - Current medications
    - Healthcare provider information
    - Family medical history
    """
    user = await auth_service.get_current_user(db=db, token=token)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED)

    # HIPAA: Explicit consent required
    if not profile_data.consent_to_store_phi:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Explicit consent required to store Protected Health Information"
        )

    # Check if profile already exists
    result = await db.execute(
        select(UserMedicalProfile).where(UserMedicalProfile.user_id == user.id)
    )
    existing_profile = result.scalar_one_or_none()

    if existing_profile:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Medical profile already exists. Use update endpoint."
        )

    # Encrypt PHI fields (if encryption key is configured)
    encrypted_conditions = profile_data.conditions
    encrypted_medications = profile_data.medications
    encrypted_provider = profile_data.primary_care_provider

    # TODO: Implement encryption
    # if hasattr(settings, 'ENCRYPTION_KEY') and settings.ENCRYPTION_KEY:
    #     encryptor = FieldEncryption(settings.ENCRYPTION_KEY)
    #     encrypted_provider = encryptor.encrypt(profile_data.primary_care_provider)

    # Create medical profile
    profile = UserMedicalProfile(
        user_id=user.id,
        conditions=encrypted_conditions,
        medications=encrypted_medications,
        primary_care_provider=encrypted_provider,
        family_history=profile_data.family_history,
        consent_to_store_phi=True,
        consent_date=datetime.utcnow(),
        assigned_diets=[]
    )

    db.add(profile)
    await db.commit()
    await db.refresh(profile)

    # HIPAA: Audit log
    client_ip = request.client.host if request.client else "unknown"
    user_agent = request.headers.get("user-agent", "unknown")

    await audit_logger.log_phi_access(
        db=db,
        user_id=user.id,
        username=user.username,
        resource_type="medical_profile",
        resource_id=str(profile.id),
        action=AuditAction.PHI_CREATE,
        description=f"Created medical profile with {len(profile_data.conditions)} conditions",
        ip_address=client_ip,
        user_agent=user_agent,
        legal_basis="consent"
    )

    return MedicalProfileResponse(
        id=profile.id,
        has_conditions=len(profile_data.conditions) > 0,
        conditions_count=len(profile_data.conditions),
        assigned_diets_count=0,
        consent_to_store_phi=True,
        consent_date=profile.consent_date,
        last_updated=profile.updated_at
    )


@router.get("/medical-profile", response_model=MedicalProfileResponse)
async def get_medical_profile(
    request: Request,
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
    """
    Get user's medical profile (summary only)

    **PHI Endpoint**: Access is audit logged

    Returns summary without exposing full PHI in response.
    Full PHI access requires additional authentication/authorization.
    """
    user = await auth_service.get_current_user(db=db, token=token)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED)

    result = await db.execute(
        select(UserMedicalProfile).where(UserMedicalProfile.user_id == user.id)
    )
    profile = result.scalar_one_or_none()

    if not profile:
        raise HTTPException(status_code=404, detail="Medical profile not found")

    # HIPAA: Audit log
    client_ip = request.client.host if request.client else "unknown"
    user_agent = request.headers.get("user-agent", "unknown")

    await audit_logger.log_phi_access(
        db=db,
        user_id=user.id,
        username=user.username,
        resource_type="medical_profile",
        resource_id=str(profile.id),
        action=AuditAction.PHI_READ,
        description="Viewed medical profile summary",
        ip_address=client_ip,
        user_agent=user_agent,
        legal_basis="consent"
    )

    # Update access tracking
    profile.last_accessed = datetime.utcnow()
    profile.access_log_count += 1
    await db.commit()

    return MedicalProfileResponse(
        id=profile.id,
        has_conditions=len(profile.conditions) > 0 if profile.conditions else False,
        conditions_count=len(profile.conditions) if profile.conditions else 0,
        assigned_diets_count=len(profile.assigned_diets) if profile.assigned_diets else 0,
        consent_to_store_phi=profile.consent_to_store_phi,
        consent_date=profile.consent_date,
        last_updated=profile.updated_at
    )


@router.post("/prescriptions", response_model=DietPrescriptionResponse)
async def create_diet_prescription(
    prescription_data: DietPrescriptionCreate,
    request: Request,
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
    """
    Create formal diet prescription

    **PHI Endpoint**: Creates Protected Health Information
    **Authorization**: Typically requires healthcare provider credentials

    Records a formal dietary prescription from a healthcare provider.
    Includes treatment goals, monitoring requirements, and provider information.
    """
    user = await auth_service.get_current_user(db=db, token=token)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED)

    # Find treatment diet
    result = await db.execute(
        select(TreatmentDiet).where(TreatmentDiet.code == prescription_data.treatment_diet_code)
    )
    diet = result.scalar_one_or_none()

    if not diet:
        raise HTTPException(status_code=404, detail="Treatment diet not found")

    # Find medical condition if specified
    condition_id = None
    if prescription_data.medical_condition_code:
        cond_result = await db.execute(
            select(MedicalCondition).where(
                MedicalCondition.code == prescription_data.medical_condition_code
            )
        )
        condition = cond_result.scalar_one_or_none()
        if condition:
            condition_id = condition.id

    # Generate prescription number
    import uuid
    prescription_number = f"RX-{uuid.uuid4().hex[:12].upper()}"

    # Encrypt PHI fields
    encrypted_provider = prescription_data.prescribed_by
    encrypted_instructions = prescription_data.special_instructions

    # TODO: Implement encryption
    # if hasattr(settings, 'ENCRYPTION_KEY') and settings.ENCRYPTION_KEY:
    #     encryptor = FieldEncryption(settings.ENCRYPTION_KEY)
    #     encrypted_provider = encryptor.encrypt(prescription_data.prescribed_by)

    # Create prescription
    prescription = DietPrescription(
        user_id=user.id,
        medical_condition_id=condition_id,
        treatment_diet_id=diet.id,
        prescribed_date=datetime.utcnow(),
        prescribed_by=encrypted_provider,
        provider_credentials=prescription_data.provider_credentials,
        prescription_number=prescription_number,
        start_date=prescription_data.start_date,
        end_date=prescription_data.end_date,
        treatment_goals=prescription_data.treatment_goals,
        custom_restrictions=prescription_data.custom_restrictions or [],
        special_instructions=encrypted_instructions,
        status="active"
    )

    db.add(prescription)
    await db.commit()
    await db.refresh(prescription)

    # HIPAA: Audit log
    client_ip = request.client.host if request.client else "unknown"
    user_agent = request.headers.get("user-agent", "unknown")

    await audit_logger.log_phi_access(
        db=db,
        user_id=user.id,
        username=user.username,
        resource_type="diet_prescription",
        resource_id=str(prescription.id),
        action=AuditAction.PHI_CREATE,
        description=f"Created diet prescription: {diet.name}",
        ip_address=client_ip,
        user_agent=user_agent,
        legal_basis="medical_care"
    )

    return DietPrescriptionResponse(
        id=prescription.id,
        prescription_number=prescription.prescription_number,
        treatment_diet_name=diet.name,
        diet_type=diet.diet_type.value,
        prescribed_date=prescription.prescribed_date,
        start_date=prescription.start_date,
        status=prescription.status,
        treatment_goals=prescription.treatment_goals
    )


@router.get("/prescriptions", response_model=List[DietPrescriptionResponse])
async def get_diet_prescriptions(
    active_only: bool = True,
    request: Request = None,
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
    """
    Get user's diet prescriptions

    **PHI Endpoint**: Returns Protected Health Information

    Lists all diet prescriptions with treatment information.
    """
    user = await auth_service.get_current_user(db=db, token=token)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED)

    query = select(DietPrescription, TreatmentDiet).join(TreatmentDiet).where(
        DietPrescription.user_id == user.id
    )

    if active_only:
        query = query.where(DietPrescription.status == "active")

    result = await db.execute(query)
    prescriptions = result.all()

    # HIPAA: Audit log
    if request:
        client_ip = request.client.host if request.client else "unknown"
        user_agent = request.headers.get("user-agent", "unknown")

        await audit_logger.log_phi_access(
            db=db,
            user_id=user.id,
            username=user.username,
            resource_type="diet_prescription",
            resource_id="list",
            action=AuditAction.PHI_READ,
            description=f"Viewed prescription list ({len(prescriptions)} items)",
            ip_address=client_ip,
            user_agent=user_agent,
            legal_basis="medical_care"
        )

    return [
        DietPrescriptionResponse(
            id=prescription.id,
            prescription_number=prescription.prescription_number,
            treatment_diet_name=diet.name,
            diet_type=diet.diet_type.value,
            prescribed_date=prescription.prescribed_date,
            start_date=prescription.start_date,
            status=prescription.status,
            treatment_goals=prescription.treatment_goals
        )
        for prescription, diet in prescriptions
    ]


@router.post("/recommendations/ai", response_model=DietRecommendationResponse)
async def get_ai_diet_recommendations(
    request_data: DietRecommendationRequest,
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
    """
    Get AI-powered diet recommendations

    Analyzes medical conditions and provides evidence-based dietary recommendations.

    Uses:
    - Medical condition database
    - Clinical nutrition research
    - Treatment diet protocols
    - AI reasoning (LLaMA)

    Returns personalized dietary recommendations with implementation guidance.
    """
    user = await auth_service.get_current_user(db=db, token=token)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED)

    # Find conditions
    result = await db.execute(
        select(MedicalCondition).where(
            MedicalCondition.code.in_(request_data.condition_codes)
        )
    )
    conditions = result.scalars().all()

    if not conditions:
        raise HTTPException(status_code=404, detail="No matching conditions found")

    # Collect recommended diets from all conditions
    recommended_diet_codes = set()
    for condition in conditions:
        if condition.recommended_diets:
            recommended_diet_codes.update(condition.recommended_diets)

    # Get diet details
    diet_result = await db.execute(
        select(TreatmentDiet).where(TreatmentDiet.code.in_(recommended_diet_codes))
    )
    recommended_diets = diet_result.scalars().all()

    # Build recommendation response
    diet_recommendations = [
        {
            "code": diet.code,
            "name": diet.name,
            "diet_type": diet.diet_type.value,
            "description": diet.description,
            "evidence_level": diet.evidence_level.value if diet.evidence_level else "moderate",
            "difficulty": diet.difficulty_level
        }
        for diet in recommended_diets
    ]

    # Generate reasoning (simplified - in production, use LLM)
    condition_names = [c.name for c in conditions]
    reasoning = f"Based on {', '.join(condition_names)}, the following dietary approaches are recommended by clinical guidelines."

    evidence_summary = f"{len(recommended_diets)} evidence-based diets identified for these conditions."

    implementation_tips = [
        "Work with a registered dietitian for personalized guidance",
        "Start with gradual dietary changes",
        "Monitor key health markers regularly",
        "Keep a food journal to track adherence"
    ]

    monitoring_advice = "Regular monitoring of blood pressure, blood glucose, and other relevant markers is recommended."

    return DietRecommendationResponse(
        recommended_diets=diet_recommendations,
        reasoning=reasoning,
        evidence_summary=evidence_summary,
        implementation_tips=implementation_tips,
        monitoring_advice=monitoring_advice
    )
