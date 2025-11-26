"""
Treatment-specific diet models

Medical nutrition therapy (MNT) for various health conditions.
Supports condition-specific dietary recommendations with clinical evidence.

PHI WARNING: Contains protected health information
All medical condition data must be encrypted at rest.
"""

from sqlalchemy import Column, Integer, String, Float, Boolean, DateTime, JSON, Text, ForeignKey, Enum as SQLEnum
from sqlalchemy.orm import relationship
from datetime import datetime
from enum import Enum
from app.db.database import Base


class MedicalConditionCategory(str, Enum):
    """Categories of medical conditions"""
    METABOLIC = "metabolic"  # Diabetes, metabolic syndrome
    CARDIOVASCULAR = "cardiovascular"  # Heart disease, hypertension
    GASTROINTESTINAL = "gastrointestinal"  # IBD, IBS, celiac
    RENAL = "renal"  # Kidney disease, CKD
    AUTOIMMUNE = "autoimmune"  # Rheumatoid arthritis, lupus
    NEUROLOGICAL = "neurological"  # Parkinson's, Alzheimer's
    ONCOLOGICAL = "oncological"  # Cancer, during treatment
    ENDOCRINE = "endocrine"  # Thyroid, PCOS
    RESPIRATORY = "respiratory"  # COPD, asthma
    MENTAL_HEALTH = "mental_health"  # Depression, anxiety
    BONE_JOINT = "bone_joint"  # Osteoporosis, gout
    LIVER = "liver"  # Fatty liver, hepatitis
    OTHER = "other"


class TreatmentDietType(str, Enum):
    """Types of therapeutic diets"""
    # Metabolic
    DIABETIC = "diabetic"  # Low glycemic index, carb controlled
    LOW_GLYCEMIC = "low_glycemic"
    KETOGENIC = "ketogenic"  # Very low carb, high fat

    # Cardiovascular
    DASH = "dash"  # Dietary Approaches to Stop Hypertension
    MEDITERRANEAN = "mediterranean"
    LOW_SODIUM = "low_sodium"
    HEART_HEALTHY = "heart_healthy"
    LOW_CHOLESTEROL = "low_cholesterol"

    # Renal
    RENAL = "renal"  # Low protein, potassium, phosphorus
    LOW_PHOSPHORUS = "low_phosphorus"
    LOW_POTASSIUM = "low_potassium"
    DIALYSIS = "dialysis"

    # Gastrointestinal
    LOW_FODMAP = "low_fodmap"  # For IBS
    IBD_FRIENDLY = "ibd_friendly"
    ANTI_INFLAMMATORY = "anti_inflammatory"
    BLAND = "bland"  # Low fiber, easily digestible

    # Cancer/Oncology
    NEUTROPENIC = "neutropenic"  # Low bacteria during chemotherapy
    HIGH_PROTEIN = "high_protein"  # For muscle preservation
    ANTI_CANCER = "anti_cancer"  # Antioxidant rich

    # Other
    GOUT_FRIENDLY = "gout_friendly"  # Low purine
    THYROID_SUPPORT = "thyroid_support"
    PCOS_FRIENDLY = "pcos_friendly"
    FERTILITY_SUPPORT = "fertility_support"
    ANTI_INFLAMMATORY_AUTOIMMUNE = "anti_inflammatory_autoimmune"


class EvidenceLevel(str, Enum):
    """Clinical evidence strength"""
    HIGH = "high"  # Multiple RCTs, meta-analyses
    MODERATE = "moderate"  # Some RCTs, observational studies
    LOW = "low"  # Expert opinion, case studies
    EMERGING = "emerging"  # New research, not yet conclusive


class MedicalCondition(Base):
    """
    Medical conditions requiring dietary management

    Defines conditions and their nutritional therapy protocols.
    """
    __tablename__ = "medical_conditions"

    id = Column(Integer, primary_key=True, index=True)
    code = Column(String, unique=True, nullable=False, index=True)  # ICD-10 code preferred
    name = Column(String, nullable=False, index=True)
    common_name = Column(String)

    # Classification
    category = Column(SQLEnum(MedicalConditionCategory), nullable=False, index=True)
    severity_levels = Column(JSON)  # mild, moderate, severe definitions

    # Description
    description = Column(Text)
    medical_overview = Column(Text)  # Clinical information

    # Dietary impact
    nutritional_considerations = Column(JSON)  # List of key nutritional factors
    nutrients_to_increase = Column(JSON)  # Beneficial nutrients
    nutrients_to_decrease = Column(JSON)  # Nutrients to limit
    nutrients_to_avoid = Column(JSON)  # Nutrients to eliminate

    # Recommended diet types
    recommended_diets = Column(JSON)  # List of TreatmentDietType codes
    evidence_level = Column(SQLEnum(EvidenceLevel))

    # Clinical guidelines
    clinical_guidelines = Column(Text)  # Summary of evidence-based recommendations
    references = Column(JSON)  # Scientific references

    # Interactions
    medication_interactions = Column(JSON)  # Food-drug interactions to watch
    comorbidity_considerations = Column(JSON)  # Considerations with other conditions

    # Monitoring
    monitoring_requirements = Column(JSON)  # What to track (blood sugar, BP, etc.)

    # Metadata
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


class TreatmentDiet(Base):
    """
    Therapeutic diet protocols

    Evidence-based dietary patterns for medical conditions.
    """
    __tablename__ = "treatment_diets"

    id = Column(Integer, primary_key=True, index=True)
    code = Column(String, unique=True, nullable=False, index=True)
    name = Column(String, nullable=False)
    diet_type = Column(SQLEnum(TreatmentDietType), nullable=False, index=True)

    # Description
    description = Column(Text)
    clinical_purpose = Column(Text)  # Why this diet is prescribed

    # Diet parameters
    macronutrient_targets = Column(JSON)  # Protein, carbs, fat percentages/amounts
    micronutrient_targets = Column(JSON)  # Specific vitamin/mineral requirements
    calorie_adjustment = Column(String)  # standard, reduced, increased

    # Rules and restrictions
    foods_to_emphasize = Column(JSON)  # Encouraged foods
    foods_to_limit = Column(JSON)  # Foods to reduce
    foods_to_avoid = Column(JSON)  # Foods to eliminate
    meal_timing_guidelines = Column(JSON)  # When to eat, frequency

    # Specific nutrients
    sodium_limit_mg = Column(Integer)  # Daily sodium limit
    sugar_limit_g = Column(Integer)  # Daily added sugar limit
    fiber_target_g = Column(Integer)  # Daily fiber target
    fluid_restriction_ml = Column(Integer)  # Fluid restriction if applicable

    # Evidence
    evidence_level = Column(SQLEnum(EvidenceLevel))
    clinical_outcomes = Column(JSON)  # Expected health outcomes
    scientific_references = Column(JSON)  # Research supporting this diet

    # Implementation
    difficulty_level = Column(String)  # easy, moderate, challenging
    typical_duration = Column(String)  # short-term, long-term, lifelong
    requires_supervision = Column(Boolean, default=False)  # Needs dietitian oversight

    # Metadata
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


class UserMedicalProfile(Base):
    """
    User's medical profile for dietary management

    PHI: Contains protected health information
    Encryption required: diagnosis, medications, provider_name, medical_notes
    """
    __tablename__ = "user_medical_profiles"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, unique=True, index=True)

    # Medical conditions (PHI - ENCRYPTED)
    conditions = Column(JSON)  # List of {condition_id, diagnosis_date, severity, encrypted_notes}

    # Current medications (PHI - ENCRYPTED)
    medications = Column(JSON)  # List of {name, dosage, frequency, reason, interactions}

    # Healthcare providers (PHI - ENCRYPTED)
    primary_care_provider = Column(Text)  # ENCRYPTED: Provider information
    registered_dietitian = Column(Text)  # ENCRYPTED: RD information

    # Treatment diets assigned
    assigned_diets = Column(JSON)  # List of {diet_id, assigned_date, assigned_by, priority}

    # Lab values (PHI - ENCRYPTED)
    recent_lab_values = Column(JSON)  # {test_name: {value, date, unit, reference_range}}

    # Risk factors
    family_history = Column(JSON)  # Relevant family medical history
    risk_factors = Column(JSON)  # Smoking, alcohol, lifestyle factors

    # Dietary restrictions (medical, not preference)
    texture_modifications = Column(JSON)  # Pureed, soft, etc. (for swallowing issues)
    tube_feeding = Column(Boolean, default=False)
    oral_supplements = Column(JSON)  # Nutritional supplements prescribed

    # HIPAA compliance
    consent_to_store_phi = Column(Boolean, nullable=False)  # Explicit consent required
    consent_date = Column(DateTime)
    phi_last_reviewed = Column(DateTime)  # Last time patient reviewed their info

    # Access control
    shared_with_providers = Column(JSON)  # List of provider IDs with access
    access_log_count = Column(Integer, default=0)

    # Metadata
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    last_accessed = Column(DateTime)


class DietPrescription(Base):
    """
    Formal dietary prescription for medical treatment

    PHI: Contains protected health information
    Represents a healthcare provider's dietary recommendation.
    """
    __tablename__ = "diet_prescriptions"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    medical_condition_id = Column(Integer, ForeignKey("medical_conditions.id"), nullable=True)
    treatment_diet_id = Column(Integer, ForeignKey("treatment_diets.id"), nullable=False)

    # Prescription details
    prescribed_date = Column(DateTime, nullable=False, default=datetime.utcnow)
    prescribed_by = Column(Text)  # ENCRYPTED: Healthcare provider information
    provider_credentials = Column(String)  # MD, RD, NP, etc.
    prescription_number = Column(String, unique=True)  # For tracking

    # Duration
    start_date = Column(DateTime, nullable=False)
    end_date = Column(DateTime)  # NULL = indefinite
    review_date = Column(DateTime)  # When to reassess

    # Customizations
    custom_macros = Column(JSON)  # Patient-specific macro adjustments
    custom_micronutrients = Column(JSON)  # Patient-specific micronutrient targets
    custom_restrictions = Column(JSON)  # Additional restrictions beyond standard diet
    special_instructions = Column(Text)  # ENCRYPTED: Provider notes

    # Goals
    treatment_goals = Column(JSON)  # Target outcomes (lower A1C, reduce inflammation, etc.)
    target_metrics = Column(JSON)  # Specific measurable goals

    # Status
    status = Column(String, default="active")  # active, completed, discontinued, modified
    adherence_level = Column(String)  # excellent, good, fair, poor
    effectiveness = Column(String)  # very_effective, effective, minimal, ineffective

    # Monitoring
    requires_monitoring = Column(Boolean, default=True)
    monitoring_frequency = Column(String)  # weekly, monthly, quarterly
    next_followup = Column(DateTime)

    # Clinical notes (PHI - ENCRYPTED)
    progress_notes = Column(JSON)  # [{date, note, provider}]
    adjustments_made = Column(JSON)  # History of modifications

    # HIPAA tracking
    access_count = Column(Integer, default=0)
    last_accessed = Column(DateTime)

    # Metadata
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    medical_condition = relationship("MedicalCondition")
    treatment_diet = relationship("TreatmentDiet")


class NutritionalIntervention(Base):
    """
    Specific nutritional interventions for conditions

    Tracks individual dietary changes and their outcomes.
    """
    __tablename__ = "nutritional_interventions"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    prescription_id = Column(Integer, ForeignKey("diet_prescriptions.id"), nullable=True)

    # Intervention details
    intervention_type = Column(String)  # increase_fiber, reduce_sodium, etc.
    target_nutrient = Column(String)  # Which nutrient is being modified
    baseline_value = Column(Float)  # Starting intake
    target_value = Column(Float)  # Goal intake
    current_value = Column(Float)  # Current intake

    # Timeline
    start_date = Column(DateTime, default=datetime.utcnow)
    target_date = Column(DateTime)  # When to reach goal
    achieved_date = Column(DateTime)  # When goal was reached

    # Outcome tracking
    health_markers = Column(JSON)  # {marker: {baseline, current, target}}
    clinical_outcomes = Column(JSON)  # Observed health improvements
    adherence_rate = Column(Float)  # Percentage of compliance

    # Notes
    barriers = Column(JSON)  # Challenges faced
    strategies = Column(JSON)  # Strategies that worked
    notes = Column(Text)

    # Metadata
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


# Pre-populated medical conditions and diets
MEDICAL_CONDITIONS_DATA = [
    {
        "code": "E11",  # ICD-10 for Type 2 Diabetes
        "name": "Type 2 Diabetes Mellitus",
        "common_name": "Type 2 Diabetes",
        "category": MedicalConditionCategory.METABOLIC,
        "nutritional_considerations": [
            "carbohydrate_management",
            "glycemic_control",
            "weight_management",
            "consistent_meal_timing"
        ],
        "nutrients_to_increase": ["fiber", "omega-3", "magnesium", "chromium"],
        "nutrients_to_decrease": ["simple_carbs", "saturated_fat", "sodium"],
        "nutrients_to_avoid": ["added_sugars", "refined_grains"],
        "recommended_diets": ["diabetic", "low_glycemic", "mediterranean"],
        "evidence_level": EvidenceLevel.HIGH,
    },
    {
        "code": "I10",  # Essential hypertension
        "name": "Hypertension",
        "common_name": "High Blood Pressure",
        "category": MedicalConditionCategory.CARDIOVASCULAR,
        "nutritional_considerations": [
            "sodium_restriction",
            "potassium_increase",
            "weight_management",
            "alcohol_moderation"
        ],
        "nutrients_to_increase": ["potassium", "calcium", "magnesium", "fiber"],
        "nutrients_to_decrease": ["sodium", "saturated_fat"],
        "nutrients_to_avoid": ["excess_sodium"],
        "recommended_diets": ["dash", "low_sodium", "mediterranean"],
        "evidence_level": EvidenceLevel.HIGH,
    },
    {
        "code": "K58",  # Irritable bowel syndrome
        "name": "Irritable Bowel Syndrome",
        "common_name": "IBS",
        "category": MedicalConditionCategory.GASTROINTESTINAL,
        "nutritional_considerations": [
            "trigger_food_identification",
            "fiber_management",
            "gut_health",
            "stress_management"
        ],
        "nutrients_to_increase": ["soluble_fiber", "probiotics", "omega-3"],
        "nutrients_to_decrease": ["fodmaps", "caffeine", "alcohol"],
        "recommended_diets": ["low_fodmap", "anti_inflammatory"],
        "evidence_level": EvidenceLevel.MODERATE,
    },
    {
        "code": "N18",  # Chronic kidney disease
        "name": "Chronic Kidney Disease",
        "common_name": "CKD",
        "category": MedicalConditionCategory.RENAL,
        "nutritional_considerations": [
            "protein_restriction",
            "phosphorus_control",
            "potassium_management",
            "fluid_balance"
        ],
        "nutrients_to_decrease": ["protein", "phosphorus", "potassium", "sodium"],
        "recommended_diets": ["renal", "low_phosphorus", "low_potassium"],
        "evidence_level": EvidenceLevel.HIGH,
    },
]
