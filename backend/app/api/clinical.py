from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from pydantic import BaseModel
from typing import List, Optional
from datetime import date, datetime

from app.db.database import get_db
from app.models.clinical import (
    MedicalCondition, LabResult, NutrientDeficiency,
    TherapeuticDiet, MedicationNutrientInteraction, ClinicalAssessment
)
from app.services.auth_service import auth_service
from app.api.auth import oauth2_scheme

router = APIRouter(prefix="/clinical", tags=["Clinical Nutrition"])


# ============================================================================
# Pydantic Models
# ============================================================================

class MedicalConditionCreate(BaseModel):
    condition_name: str
    condition_type: Optional[str] = None
    severity: Optional[str] = None
    diagnosis_date: Optional[date] = None
    medications: List[str] = []
    dietary_restrictions: List[str] = []
    target_nutrients: dict = {}
    notes: Optional[str] = None


class MedicalConditionResponse(BaseModel):
    id: int
    condition_name: str
    condition_type: Optional[str]
    severity: Optional[str]
    diagnosis_date: Optional[date]
    is_active: bool
    medications: List[str]
    dietary_restrictions: List[str]
    created_at: datetime

    class Config:
        from_attributes = True


class LabResultCreate(BaseModel):
    test_name: str
    test_type: Optional[str] = None
    test_date: date
    result_value: float
    result_unit: str
    reference_range_low: Optional[float] = None
    reference_range_high: Optional[float] = None
    ordered_by: Optional[str] = None
    notes: Optional[str] = None


class LabResultResponse(BaseModel):
    id: int
    test_name: str
    test_type: Optional[str]
    test_date: date
    result_value: float
    result_unit: str
    reference_range_low: Optional[float]
    reference_range_high: Optional[float]
    status: Optional[str]
    flagged: bool
    created_at: datetime

    class Config:
        from_attributes = True


class NutrientDeficiencyCreate(BaseModel):
    nutrient_name: str
    severity: Optional[str] = None
    diagnosis_date: Optional[date] = None
    supplement_name: Optional[str] = None
    supplement_dosage: Optional[str] = None
    target_level: Optional[float] = None
    current_level: Optional[float] = None
    unit: Optional[str] = None
    symptoms: List[str] = []
    dietary_sources: List[str] = []


class NutrientDeficiencyResponse(BaseModel):
    id: int
    nutrient_name: str
    severity: Optional[str]
    diagnosis_date: Optional[date]
    is_resolved: bool
    supplement_name: Optional[str]
    supplement_dosage: Optional[str]
    current_level: Optional[float]
    target_level: Optional[float]
    unit: Optional[str]
    created_at: datetime

    class Config:
        from_attributes = True


class TherapeuticDietCreate(BaseModel):
    diet_name: str
    diet_type: Optional[str] = None
    prescribed_for: Optional[str] = None
    prescribed_by: Optional[str] = None
    prescription_date: Optional[date] = None
    calorie_target: Optional[int] = None
    protein_target: Optional[float] = None
    sodium_limit: Optional[float] = None
    potassium_limit: Optional[float] = None
    phosphorus_limit: Optional[float] = None
    fluid_limit: Optional[float] = None
    food_restrictions: List[str] = []
    food_allowances: List[str] = []
    clinical_goals: List[str] = []


class TherapeuticDietResponse(BaseModel):
    id: int
    diet_name: str
    diet_type: Optional[str]
    prescribed_for: Optional[str]
    is_active: bool
    calorie_target: Optional[int]
    protein_target: Optional[float]
    sodium_limit: Optional[float]
    food_restrictions: List[str]
    food_allowances: List[str]
    compliance_score: Optional[float]
    created_at: datetime

    class Config:
        from_attributes = True


class ClinicalAssessmentCreate(BaseModel):
    assessment_date: date
    assessed_by: Optional[str] = None
    assessment_type: Optional[str] = None
    weight: Optional[float] = None
    height: Optional[float] = None
    bmi: Optional[float] = None
    waist_circumference: Optional[float] = None
    body_fat_percentage: Optional[float] = None
    malnutrition_risk: Optional[str] = None
    nutritional_status: Optional[str] = None
    calorie_intake: Optional[int] = None
    protein_intake: Optional[float] = None
    findings: dict = {}
    diagnosis: Optional[str] = None
    short_term_goals: List[str] = []
    long_term_goals: List[str] = []
    notes: Optional[str] = None


class ClinicalAssessmentResponse(BaseModel):
    id: int
    assessment_date: date
    assessed_by: Optional[str]
    assessment_type: Optional[str]
    weight: Optional[float]
    bmi: Optional[float]
    malnutrition_risk: Optional[str]
    nutritional_status: Optional[str]
    findings: dict
    short_term_goals: List[str]
    long_term_goals: List[str]
    created_at: datetime

    class Config:
        from_attributes = True


# ============================================================================
# Medical Conditions Endpoints
# ============================================================================

@router.post("/conditions", response_model=MedicalConditionResponse, status_code=status.HTTP_201_CREATED)
async def create_medical_condition(
    condition_data: MedicalConditionCreate,
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
    """
    Add medical condition

    Track chronic conditions affecting nutritional needs:
    - Diabetes (Type 1, Type 2, Gestational)
    - Cardiovascular disease
    - Chronic kidney disease
    - Celiac disease
    - Food allergies/intolerances

    Includes medication tracking and dietary restrictions.
    """
    user = await auth_service.get_current_user(db=db, token=token)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")

    condition = MedicalCondition(
        user_id=user.id,
        **condition_data.dict()
    )

    db.add(condition)
    await db.commit()
    await db.refresh(condition)

    return condition


@router.get("/conditions", response_model=List[MedicalConditionResponse])
async def get_medical_conditions(
    active_only: bool = True,
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
    """Get all medical conditions"""
    user = await auth_service.get_current_user(db=db, token=token)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")

    stmt = select(MedicalCondition).where(MedicalCondition.user_id == user.id)

    if active_only:
        stmt = stmt.where(MedicalCondition.is_active == True)

    stmt = stmt.order_by(MedicalCondition.diagnosis_date.desc())

    result = await db.execute(stmt)
    conditions = result.scalars().all()

    return conditions


# ============================================================================
# Lab Results Endpoints
# ============================================================================

@router.post("/lab-results", response_model=LabResultResponse, status_code=status.HTTP_201_CREATED)
async def create_lab_result(
    lab_data: LabResultCreate,
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
    """
    Record laboratory test result

    Common tests for nutritional monitoring:
    - HbA1c (diabetes control)
    - Lipid panel (cholesterol, triglycerides)
    - Vitamin D, B12, Folate
    - Iron, Ferritin
    - Kidney function (creatinine, eGFR)
    - Liver function
    - Thyroid panel

    Results are automatically flagged if outside reference range.
    """
    user = await auth_service.get_current_user(db=db, token=token)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")

    # Determine status based on reference ranges
    status_value = "normal"
    flagged = False

    if lab_data.reference_range_low and lab_data.result_value < lab_data.reference_range_low:
        status_value = "low"
        flagged = True
    elif lab_data.reference_range_high and lab_data.result_value > lab_data.reference_range_high:
        status_value = "high"
        flagged = True

    lab_result = LabResult(
        user_id=user.id,
        status=status_value,
        flagged=flagged,
        **lab_data.dict()
    )

    db.add(lab_result)
    await db.commit()
    await db.refresh(lab_result)

    return lab_result


@router.get("/lab-results", response_model=List[LabResultResponse])
async def get_lab_results(
    test_name: Optional[str] = None,
    flagged_only: bool = False,
    limit: int = Query(50, le=200),
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
    """Get laboratory test results"""
    user = await auth_service.get_current_user(db=db, token=token)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")

    stmt = select(LabResult).where(LabResult.user_id == user.id)

    if test_name:
        stmt = stmt.where(LabResult.test_name == test_name)

    if flagged_only:
        stmt = stmt.where(LabResult.flagged == True)

    stmt = stmt.order_by(LabResult.test_date.desc()).limit(limit)

    result = await db.execute(stmt)
    lab_results = result.scalars().all()

    return lab_results


# ============================================================================
# Nutrient Deficiency Endpoints
# ============================================================================

@router.post("/deficiencies", response_model=NutrientDeficiencyResponse, status_code=status.HTTP_201_CREATED)
async def create_nutrient_deficiency(
    deficiency_data: NutrientDeficiencyCreate,
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
    """
    Track nutrient deficiency

    Common deficiencies:
    - Vitamin D
    - Vitamin B12
    - Iron (anemia)
    - Folate
    - Calcium
    - Magnesium

    Includes supplement tracking and dietary recommendations.
    """
    user = await auth_service.get_current_user(db=db, token=token)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")

    deficiency = NutrientDeficiency(
        user_id=user.id,
        **deficiency_data.dict()
    )

    db.add(deficiency)
    await db.commit()
    await db.refresh(deficiency)

    return deficiency


@router.get("/deficiencies", response_model=List[NutrientDeficiencyResponse])
async def get_nutrient_deficiencies(
    active_only: bool = True,
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
    """Get nutrient deficiencies"""
    user = await auth_service.get_current_user(db=db, token=token)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")

    stmt = select(NutrientDeficiency).where(NutrientDeficiency.user_id == user.id)

    if active_only:
        stmt = stmt.where(NutrientDeficiency.is_resolved == False)

    stmt = stmt.order_by(NutrientDeficiency.diagnosis_date.desc())

    result = await db.execute(stmt)
    deficiencies = result.scalars().all()

    return deficiencies


@router.patch("/deficiencies/{deficiency_id}/resolve")
async def resolve_deficiency(
    deficiency_id: int,
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
    """Mark nutrient deficiency as resolved"""
    user = await auth_service.get_current_user(db=db, token=token)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")

    result = await db.execute(
        select(NutrientDeficiency).where(
            NutrientDeficiency.id == deficiency_id,
            NutrientDeficiency.user_id == user.id
        )
    )
    deficiency = result.scalar_one_or_none()

    if not deficiency:
        raise HTTPException(status_code=404, detail="Deficiency not found")

    deficiency.is_resolved = True
    deficiency.resolution_date = date.today()

    await db.commit()

    return {"message": "Deficiency marked as resolved"}


# ============================================================================
# Therapeutic Diet Endpoints
# ============================================================================

@router.post("/therapeutic-diets", response_model=TherapeuticDietResponse, status_code=status.HTTP_201_CREATED)
async def create_therapeutic_diet(
    diet_data: TherapeuticDietCreate,
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
    """
    Create therapeutic diet plan

    Medical nutrition therapy for:
    - Renal diet (CKD stages)
    - Diabetic diet (carb counting, glycemic control)
    - Cardiac diet (low sodium, heart healthy)
    - DASH diet (hypertension)
    - Low FODMAP (IBS)
    - Gluten-free (Celiac)
    - Ketogenic (epilepsy, weight loss)

    Prescribed by healthcare providers with clinical targets.
    """
    user = await auth_service.get_current_user(db=db, token=token)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")

    therapeutic_diet = TherapeuticDiet(
        user_id=user.id,
        **diet_data.dict()
    )

    db.add(therapeutic_diet)
    await db.commit()
    await db.refresh(therapeutic_diet)

    return therapeutic_diet


@router.get("/therapeutic-diets", response_model=List[TherapeuticDietResponse])
async def get_therapeutic_diets(
    active_only: bool = True,
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
    """Get therapeutic diet plans"""
    user = await auth_service.get_current_user(db=db, token=token)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")

    stmt = select(TherapeuticDiet).where(TherapeuticDiet.user_id == user.id)

    if active_only:
        stmt = stmt.where(TherapeuticDiet.is_active == True)

    stmt = stmt.order_by(TherapeuticDiet.prescription_date.desc())

    result = await db.execute(stmt)
    diets = result.scalars().all()

    return diets


# ============================================================================
# Clinical Assessment Endpoints
# ============================================================================

@router.post("/assessments", response_model=ClinicalAssessmentResponse, status_code=status.HTTP_201_CREATED)
async def create_clinical_assessment(
    assessment_data: ClinicalAssessmentCreate,
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
    """
    Create clinical nutritional assessment

    Comprehensive medical nutrition assessment including:
    - Anthropometric measurements (BMI, body composition)
    - Biochemical data (albumin, prealbumin, hemoglobin)
    - Clinical findings
    - Dietary intake analysis
    - Nutrition diagnosis
    - Care plan and interventions

    Conducted by registered dietitians/nutritionists.
    """
    user = await auth_service.get_current_user(db=db, token=token)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")

    assessment = ClinicalAssessment(
        user_id=user.id,
        **assessment_data.dict()
    )

    db.add(assessment)
    await db.commit()
    await db.refresh(assessment)

    return assessment


@router.get("/assessments", response_model=List[ClinicalAssessmentResponse])
async def get_clinical_assessments(
    limit: int = Query(20, le=100),
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
    """Get clinical nutritional assessments"""
    user = await auth_service.get_current_user(db=db, token=token)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")

    stmt = select(ClinicalAssessment).where(
        ClinicalAssessment.user_id == user.id
    ).order_by(ClinicalAssessment.assessment_date.desc()).limit(limit)

    result = await db.execute(stmt)
    assessments = result.scalars().all()

    return assessments


@router.get("/assessments/latest", response_model=ClinicalAssessmentResponse)
async def get_latest_assessment(
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
    """Get most recent clinical assessment"""
    user = await auth_service.get_current_user(db=db, token=token)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")

    result = await db.execute(
        select(ClinicalAssessment)
        .where(ClinicalAssessment.user_id == user.id)
        .order_by(ClinicalAssessment.assessment_date.desc())
        .limit(1)
    )
    assessment = result.scalar_one_or_none()

    if not assessment:
        raise HTTPException(status_code=404, detail="No assessments found")

    return assessment


# ============================================================================
# Medication Interactions
# ============================================================================

@router.get("/medication-interactions")
async def get_medication_interactions(
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
    """
    Get medication-nutrient interactions

    Identifies interactions between medications and nutrients:
    - Warfarin + Vitamin K (avoid green leafy vegetables)
    - Statins + Grapefruit (avoid)
    - Thyroid meds + Calcium/Iron (timing)
    - Antibiotics + Dairy (timing)
    - MAOIs + Tyramine (dietary restrictions)

    Helps prevent adverse reactions and optimize medication efficacy.
    """
    user = await auth_service.get_current_user(db=db, token=token)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")

    result = await db.execute(
        select(MedicationNutrientInteraction)
        .where(
            MedicationNutrientInteraction.user_id == user.id,
            MedicationNutrientInteraction.is_active == True
        )
        .order_by(MedicationNutrientInteraction.severity.desc())
    )
    interactions = result.scalars().all()

    return interactions


# ============================================================================
# Reports and Analytics
# ============================================================================

@router.get("/reports/compliance")
async def get_compliance_report(
    start_date: Optional[date] = None,
    end_date: Optional[date] = None,
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
    """
    Generate dietary compliance report

    Analyzes adherence to therapeutic diet plans:
    - Sodium intake vs. limit
    - Protein intake vs. target
    - Fluid intake vs. restriction
    - Forbidden food consumption
    - Overall compliance score

    Used for clinical monitoring and patient counseling.
    """
    user = await auth_service.get_current_user(db=db, token=token)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")

    # TODO: Implement compliance calculation based on meal logs
    # This would compare actual intake vs. therapeutic diet targets

    return {
        "message": "Compliance report generation - to be implemented",
        "user_id": user.id,
        "start_date": start_date,
        "end_date": end_date
    }


@router.get("/reports/nutrition-status")
async def get_nutrition_status_report(
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db)
):
    """
    Comprehensive nutrition status report

    Medical-grade report including:
    - Current conditions and comorbidities
    - Latest lab results with trends
    - Active nutrient deficiencies
    - Therapeutic diet adherence
    - Anthropometric trends
    - Clinical recommendations

    Suitable for healthcare provider review.
    """
    user = await auth_service.get_current_user(db=db, token=token)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")

    # Get latest data from each category
    conditions = await db.execute(
        select(MedicalCondition).where(
            MedicalCondition.user_id == user.id,
            MedicalCondition.is_active == True
        )
    )

    lab_results = await db.execute(
        select(LabResult).where(LabResult.user_id == user.id).order_by(LabResult.test_date.desc()).limit(10)
    )

    deficiencies = await db.execute(
        select(NutrientDeficiency).where(
            NutrientDeficiency.user_id == user.id,
            NutrientDeficiency.is_resolved == False
        )
    )

    therapeutic_diets = await db.execute(
        select(TherapeuticDiet).where(
            TherapeuticDiet.user_id == user.id,
            TherapeuticDiet.is_active == True
        )
    )

    latest_assessment = await db.execute(
        select(ClinicalAssessment).where(
            ClinicalAssessment.user_id == user.id
        ).order_by(ClinicalAssessment.assessment_date.desc()).limit(1)
    )

    return {
        "user_id": user.id,
        "report_date": datetime.utcnow(),
        "active_conditions": [c.condition_name for c in conditions.scalars().all()],
        "recent_labs": len(lab_results.scalars().all()),
        "active_deficiencies": [d.nutrient_name for d in deficiencies.scalars().all()],
        "therapeutic_diets": [d.diet_name for d in therapeutic_diets.scalars().all()],
        "latest_assessment": latest_assessment.scalar_one_or_none(),
        "summary": "Comprehensive clinical nutrition status report"
    }
