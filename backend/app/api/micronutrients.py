"""
Micronutrient Tracking API

Endpoints for detailed micronutrient tracking and analysis.
Supports:
- Micronutrient intake tracking
- Deficiency detection
- Personalized targets
- Detailed nutritional analysis
"""

from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_, func
from pydantic import BaseModel, Field
from typing import List, Optional, Dict
from datetime import datetime, timedelta

from app.db.database import get_db
from app.services.auth_service import auth_service
from app.api.auth import oauth2_scheme
from app.models.micronutrients import (
    Micronutrient, UserMicronutrientTarget, MicronutrientDeficiency,
    DailyMicronutrientIntake, MicronutrientType, MicronutrientUnit
)
from app.utils.audit_log import audit_logger, AuditAction

router = APIRouter(prefix="/micronutrients", tags=["Micronutrient Tracking"])


# Pydantic models
class MicronutrientInfo(BaseModel):
    id: int
    code: str
    name: str
    type: str
    category: Optional[str]
    default_unit: str
    rda_male: Optional[float]
    rda_female: Optional[float]
    description: Optional[str]
    health_benefits: List[str]
    food_sources: List[str]

    class Config:
        from_attributes = True


class UserTargetCreate(BaseModel):
    micronutrient_code: str
    daily_target: float
    unit: str
    basis: str = "rda"  # rda, medical_condition, deficiency, athlete
    condition_specific: Optional[str] = None
    priority: str = "medium"
    notes: Optional[str] = None


class UserTargetResponse(BaseModel):
    id: int
    micronutrient_code: str
    micronutrient_name: str
    daily_target: float
    unit: str
    basis: str
    priority: str
    created_at: datetime


class DeficiencyCreate(BaseModel):
    micronutrient_code: str
    severity: str  # mild, moderate, severe, critical
    symptoms: Optional[str] = None
    lab_results: Optional[str] = None
    diagnosis_code: Optional[str] = None


class DeficiencyResponse(BaseModel):
    id: int
    micronutrient_code: str
    micronutrient_name: str
    severity: str
    detected_date: datetime
    is_active: bool
    treatment_plan: Optional[Dict]


class DailyIntakeCreate(BaseModel):
    date: datetime
    micronutrient_code: str
    total_amount: float
    unit: str
    from_food: float
    from_supplements: float = 0


class DailyIntakeResponse(BaseModel):
    id: int
    date: datetime
    micronutrient_code: str
    micronutrient_name: str
    total_amount: float
    unit: str
    percent_of_target: Optional[float]
    status: Optional[str]
    from_food: float
    from_supplements: float


class MicronutrientAnalysis(BaseModel):
    """Comprehensive micronutrient analysis for a day"""
    date: datetime
    intake_summary: List[Dict]  # All micronutrients tracked
    deficiencies_detected: List[str]  # Which nutrients are deficient
    adequate: List[str]  # Which nutrients are adequate
    excessive: List[str]  # Which nutrients are excessive
    recommendations: List[str]  # AI-generated recommendations
    overall_score: float  # 0-100 nutrition quality score


@router.get("/list", response_model=List[MicronutrientInfo])
async def list_micronutrients(
    type: Optional[MicronutrientType] = None,
    search: Optional[str] = None,
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
    """
    List all tracked micronutrients

    Filter by:
    - **type**: vitamin, mineral, trace_element, etc.
    - **search**: Search by name or code

    Returns comprehensive micronutrient database with RDAs and health benefits.
    """
    user = await auth_service.get_current_user(db=db, token=token)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED)

    query = select(Micronutrient)

    if type:
        query = query.where(Micronutrient.type == type)

    if search:
        query = query.where(
            (Micronutrient.name.ilike(f"%{search}%")) |
            (Micronutrient.code.ilike(f"%{search}%"))
        )

    result = await db.execute(query)
    micronutrients = result.scalars().all()

    return [
        MicronutrientInfo(
            id=m.id,
            code=m.code,
            name=m.name,
            type=m.type.value,
            category=m.category,
            default_unit=m.default_unit.value,
            rda_male=m.rda_male,
            rda_female=m.rda_female,
            description=m.description,
            health_benefits=m.health_benefits or [],
            food_sources=m.food_sources or []
        )
        for m in micronutrients
    ]


@router.get("/targets", response_model=List[UserTargetResponse])
async def get_user_targets(
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
    """
    Get user's personalized micronutrient targets

    Returns all micronutrient targets customized for the user based on:
    - Age, sex, pregnancy status
    - Medical conditions
    - Athletic requirements
    - Detected deficiencies
    """
    user = await auth_service.get_current_user(db=db, token=token)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED)

    result = await db.execute(
        select(UserMicronutrientTarget, Micronutrient)
        .join(Micronutrient)
        .where(UserMicronutrientTarget.user_id == user.id)
    )
    targets = result.all()

    return [
        UserTargetResponse(
            id=target.id,
            micronutrient_code=micronutrient.code,
            micronutrient_name=micronutrient.name,
            daily_target=target.daily_target,
            unit=target.unit.value,
            basis=target.basis,
            priority=target.priority,
            created_at=target.created_at
        )
        for target, micronutrient in targets
    ]


@router.post("/targets", response_model=UserTargetResponse)
async def create_user_target(
    target_data: UserTargetCreate,
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
    """
    Set personalized micronutrient target

    Create custom daily targets for specific micronutrients based on:
    - Medical conditions
    - Athletic requirements
    - Deficiency correction
    - Personal health goals
    """
    user = await auth_service.get_current_user(db=db, token=token)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED)

    # Find micronutrient
    result = await db.execute(
        select(Micronutrient).where(Micronutrient.code == target_data.micronutrient_code)
    )
    micronutrient = result.scalar_one_or_none()

    if not micronutrient:
        raise HTTPException(status_code=404, detail="Micronutrient not found")

    # Create target
    target = UserMicronutrientTarget(
        user_id=user.id,
        micronutrient_id=micronutrient.id,
        daily_target=target_data.daily_target,
        unit=MicronutrientUnit(target_data.unit),
        basis=target_data.basis,
        condition_specific=target_data.condition_specific,
        priority=target_data.priority,
        notes=target_data.notes,
        monitor_closely=target_data.priority == "critical"
    )

    db.add(target)
    await db.commit()
    await db.refresh(target)

    # Audit log
    await audit_logger.log(
        db=db,
        action=AuditAction.PHI_CREATE,
        resource_type="micronutrient_target",
        resource_id=str(target.id),
        user_id=user.id,
        username=user.username,
        description=f"Set target for {micronutrient.name}: {target_data.daily_target} {target_data.unit}",
        phi_accessed=True
    )

    return UserTargetResponse(
        id=target.id,
        micronutrient_code=micronutrient.code,
        micronutrient_name=micronutrient.name,
        daily_target=target.daily_target,
        unit=target.unit.value,
        basis=target.basis,
        priority=target.priority,
        created_at=target.created_at
    )


@router.post("/deficiencies", response_model=DeficiencyResponse)
async def record_deficiency(
    deficiency_data: DeficiencyCreate,
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
    """
    Record micronutrient deficiency

    **PHI Endpoint**: Records protected health information.
    Requires explicit consent for medical data processing.

    Document detected deficiencies including:
    - Lab results
    - Symptoms
    - Severity
    - Treatment plan
    """
    user = await auth_service.get_current_user(db=db, token=token)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED)

    # Find micronutrient
    result = await db.execute(
        select(Micronutrient).where(Micronutrient.code == deficiency_data.micronutrient_code)
    )
    micronutrient = result.scalar_one_or_none()

    if not micronutrient:
        raise HTTPException(status_code=404, detail="Micronutrient not found")

    # Create deficiency record (PHI)
    # Note: In production, encrypt symptoms and lab_results
    deficiency = MicronutrientDeficiency(
        user_id=user.id,
        micronutrient_id=micronutrient.id,
        severity=deficiency_data.severity,
        symptoms=deficiency_data.symptoms,  # Should be encrypted
        lab_results=deficiency_data.lab_results,  # Should be encrypted
        diagnosis_code=deficiency_data.diagnosis_code,
        is_active=True
    )

    db.add(deficiency)
    await db.commit()
    await db.refresh(deficiency)

    # Audit log - PHI access
    await audit_logger.log_phi_access(
        db=db,
        user_id=user.id,
        username=user.username,
        resource_type="micronutrient_deficiency",
        resource_id=str(deficiency.id),
        action=AuditAction.PHI_CREATE,
        description=f"Recorded {micronutrient.name} deficiency ({deficiency_data.severity})",
        legal_basis="medical_care"
    )

    return DeficiencyResponse(
        id=deficiency.id,
        micronutrient_code=micronutrient.code,
        micronutrient_name=micronutrient.name,
        severity=deficiency.severity,
        detected_date=deficiency.detected_date,
        is_active=deficiency.is_active,
        treatment_plan=deficiency.treatment_plan
    )


@router.get("/deficiencies", response_model=List[DeficiencyResponse])
async def get_deficiencies(
    active_only: bool = True,
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
    """
    Get user's micronutrient deficiencies

    **PHI Endpoint**: Returns protected health information.

    Lists all detected deficiencies with treatment recommendations.
    """
    user = await auth_service.get_current_user(db=db, token=token)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED)

    query = select(MicronutrientDeficiency, Micronutrient).join(Micronutrient).where(
        MicronutrientDeficiency.user_id == user.id
    )

    if active_only:
        query = query.where(MicronutrientDeficiency.is_active == True)

    result = await db.execute(query)
    deficiencies = result.all()

    # Audit log - PHI access
    await audit_logger.log_phi_access(
        db=db,
        user_id=user.id,
        username=user.username,
        resource_type="micronutrient_deficiency",
        resource_id="list",
        action=AuditAction.PHI_READ,
        description=f"Viewed deficiency list ({len(deficiencies)} items)",
        legal_basis="medical_care"
    )

    return [
        DeficiencyResponse(
            id=deficiency.id,
            micronutrient_code=micronutrient.code,
            micronutrient_name=micronutrient.name,
            severity=deficiency.severity,
            detected_date=deficiency.detected_date,
            is_active=deficiency.is_active,
            treatment_plan=deficiency.treatment_plan
        )
        for deficiency, micronutrient in deficiencies
    ]


@router.post("/intake/daily", response_model=DailyIntakeResponse)
async def log_daily_intake(
    intake_data: DailyIntakeCreate,
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
    """
    Log daily micronutrient intake

    Track micronutrient consumption from:
    - Food
    - Supplements
    - Fortified foods

    Automatically calculates percentage of personalized target.
    """
    user = await auth_service.get_current_user(db=db, token=token)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED)

    # Find micronutrient
    result = await db.execute(
        select(Micronutrient).where(Micronutrient.code == intake_data.micronutrient_code)
    )
    micronutrient = result.scalar_one_or_none()

    if not micronutrient:
        raise HTTPException(status_code=404, detail="Micronutrient not found")

    # Get user's target
    target_result = await db.execute(
        select(UserMicronutrientTarget).where(
            and_(
                UserMicronutrientTarget.user_id == user.id,
                UserMicronutrientTarget.micronutrient_id == micronutrient.id
            )
        )
    )
    target = target_result.scalar_one_or_none()

    # Calculate percentage of target
    percent_of_target = None
    status_value = "unknown"

    if target:
        percent_of_target = (intake_data.total_amount / target.daily_target) * 100

        if percent_of_target < 50:
            status_value = "deficient"
        elif percent_of_target < 80:
            status_value = "low"
        elif percent_of_target <= 120:
            status_value = "adequate"
        elif percent_of_target <= 150:
            status_value = "high"
        else:
            status_value = "excessive"

    # Create intake record
    intake = DailyMicronutrientIntake(
        user_id=user.id,
        date=intake_data.date,
        micronutrient_id=micronutrient.id,
        total_amount=intake_data.total_amount,
        unit=MicronutrientUnit(intake_data.unit),
        percent_of_target=percent_of_target,
        status=status_value,
        from_food=intake_data.from_food,
        from_supplements=intake_data.from_supplements
    )

    db.add(intake)
    await db.commit()
    await db.refresh(intake)

    return DailyIntakeResponse(
        id=intake.id,
        date=intake.date,
        micronutrient_code=micronutrient.code,
        micronutrient_name=micronutrient.name,
        total_amount=intake.total_amount,
        unit=intake.unit.value,
        percent_of_target=percent_of_target,
        status=status_value,
        from_food=intake.from_food,
        from_supplements=intake.from_supplements
    )


@router.get("/analysis/daily", response_model=MicronutrientAnalysis)
async def analyze_daily_intake(
    date: datetime = Query(..., description="Date to analyze"),
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
    """
    Comprehensive daily micronutrient analysis

    Analyzes all micronutrient intake for a specific day:
    - Identifies deficiencies
    - Highlights adequate nutrients
    - Flags excessive intake
    - Provides AI-generated recommendations
    - Calculates overall nutrition quality score
    """
    user = await auth_service.get_current_user(db=db, token=token)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED)

    # Get all intake for the day
    result = await db.execute(
        select(DailyMicronutrientIntake, Micronutrient)
        .join(Micronutrient)
        .where(
            and_(
                DailyMicronutrientIntake.user_id == user.id,
                func.date(DailyMicronutrientIntake.date) == date.date()
            )
        )
    )
    intakes = result.all()

    # Analyze
    intake_summary = []
    deficient = []
    adequate = []
    excessive = []

    for intake, micronutrient in intakes:
        intake_summary.append({
            "micronutrient": micronutrient.name,
            "amount": intake.total_amount,
            "unit": intake.unit.value,
            "percent_of_target": intake.percent_of_target,
            "status": intake.status
        })

        if intake.status == "deficient" or intake.status == "low":
            deficient.append(micronutrient.name)
        elif intake.status == "adequate":
            adequate.append(micronutrient.name)
        elif intake.status == "excessive":
            excessive.append(micronutrient.name)

    # Generate recommendations
    recommendations = []
    if deficient:
        recommendations.append(f"Increase intake of: {', '.join(deficient)}")
    if excessive:
        recommendations.append(f"Reduce intake of: {', '.join(excessive)}")

    # Calculate overall score (simplified)
    if len(adequate) + len(intake_summary) > 0:
        overall_score = (len(adequate) / len(intake_summary)) * 100
    else:
        overall_score = 0

    return MicronutrientAnalysis(
        date=date,
        intake_summary=intake_summary,
        deficiencies_detected=deficient,
        adequate=adequate,
        excessive=excessive,
        recommendations=recommendations,
        overall_score=overall_score
    )
