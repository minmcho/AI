from sqlalchemy import Column, Integer, String, Float, DateTime, JSON, ForeignKey, Date, Boolean, Text
from sqlalchemy.orm import relationship
from datetime import datetime
from app.db.database import Base


class MedicalCondition(Base):
    """Medical conditions affecting nutritional needs"""
    __tablename__ = "medical_conditions"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)

    # Condition details
    condition_name = Column(String, nullable=False)  # diabetes, hypertension, CKD, etc.
    condition_type = Column(String)  # chronic, acute, genetic
    severity = Column(String)  # mild, moderate, severe
    diagnosis_date = Column(Date)

    # Treatment
    is_active = Column(Boolean, default=True)
    medications = Column(JSON)  # List of current medications
    dietary_restrictions = Column(JSON)  # Required dietary modifications

    # Monitoring
    target_nutrients = Column(JSON)  # Special nutrient targets for this condition
    notes = Column(Text)

    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    user = relationship("User", back_populates="medical_conditions")


class LabResult(Base):
    """Laboratory test results for nutritional assessment"""
    __tablename__ = "lab_results"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)

    # Test information
    test_name = Column(String, nullable=False)  # HbA1c, cholesterol, vitamin D, etc.
    test_type = Column(String)  # blood, urine, other
    test_date = Column(Date, nullable=False)

    # Results
    result_value = Column(Float, nullable=False)
    result_unit = Column(String, nullable=False)  # mg/dL, mmol/L, %, etc.
    reference_range_low = Column(Float)
    reference_range_high = Column(Float)

    # Status
    status = Column(String)  # normal, low, high, critical
    flagged = Column(Boolean, default=False)  # Requires attention

    # Clinical notes
    ordered_by = Column(String)  # Healthcare provider
    notes = Column(Text)
    recommendations = Column(JSON)  # Dietary recommendations based on results

    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow)

    # Relationships
    user = relationship("User", back_populates="lab_results")


class NutrientDeficiency(Base):
    """Tracked nutrient deficiencies and supplementation"""
    __tablename__ = "nutrient_deficiencies"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)

    # Nutrient information
    nutrient_name = Column(String, nullable=False)  # Vitamin D, Iron, B12, etc.
    severity = Column(String)  # mild, moderate, severe
    diagnosis_date = Column(Date)

    # Current status
    is_resolved = Column(Boolean, default=False)
    resolution_date = Column(Date)

    # Treatment
    supplement_name = Column(String)
    supplement_dosage = Column(String)  # e.g., "1000 IU daily"
    supplement_frequency = Column(String)

    # Monitoring
    target_level = Column(Float)
    current_level = Column(Float)
    unit = Column(String)

    # Clinical guidance
    symptoms = Column(JSON)  # List of symptoms
    dietary_sources = Column(JSON)  # Recommended food sources
    notes = Column(Text)

    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    user = relationship("User", back_populates="nutrient_deficiencies")


class TherapeuticDiet(Base):
    """Medical therapeutic diet plans"""
    __tablename__ = "therapeutic_diets"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)

    # Diet information
    diet_name = Column(String, nullable=False)  # Renal, Diabetic, Cardiac, etc.
    diet_type = Column(String)  # therapeutic, preventive, management

    # Medical context
    prescribed_for = Column(String)  # Condition name
    prescribed_by = Column(String)  # Healthcare provider
    prescription_date = Column(Date)

    # Diet parameters
    is_active = Column(Boolean, default=True)
    calorie_target = Column(Integer)
    protein_target = Column(Float)  # grams per day
    sodium_limit = Column(Float)  # mg per day
    potassium_limit = Column(Float)  # mg per day
    phosphorus_limit = Column(Float)  # mg per day
    fluid_limit = Column(Float)  # mL per day

    # Restrictions and allowances
    food_restrictions = Column(JSON)  # Foods to avoid
    food_allowances = Column(JSON)  # Recommended foods
    portion_guidelines = Column(JSON)

    # Monitoring
    compliance_score = Column(Float)  # 0-100%
    last_review_date = Column(Date)
    next_review_date = Column(Date)

    # Notes and goals
    clinical_goals = Column(JSON)
    notes = Column(Text)

    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    user = relationship("User", back_populates="therapeutic_diets")


class MedicationNutrientInteraction(Base):
    """Track medication-nutrient interactions"""
    __tablename__ = "medication_interactions"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)

    # Medication information
    medication_name = Column(String, nullable=False)
    medication_class = Column(String)
    dosage = Column(String)

    # Interaction details
    interacting_nutrient = Column(String)  # Vitamin K, Calcium, Grapefruit, etc.
    interaction_type = Column(String)  # avoid, limit, increase, timing
    severity = Column(String)  # mild, moderate, severe

    # Guidance
    description = Column(Text)
    recommendations = Column(JSON)
    timing_instructions = Column(String)  # e.g., "Take 2 hours before food"

    # Status
    is_active = Column(Boolean, default=True)
    acknowledged = Column(Boolean, default=False)
    acknowledged_date = Column(DateTime)

    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow)

    # Relationships
    user = relationship("User", back_populates="medication_interactions")


class ClinicalAssessment(Base):
    """Clinical nutritional assessments"""
    __tablename__ = "clinical_assessments"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)

    # Assessment information
    assessment_date = Column(Date, nullable=False)
    assessed_by = Column(String)  # Healthcare provider name
    assessment_type = Column(String)  # initial, follow-up, discharge

    # Anthropometric measurements
    weight = Column(Float)  # kg
    height = Column(Float)  # cm
    bmi = Column(Float)
    waist_circumference = Column(Float)  # cm
    body_fat_percentage = Column(Float)

    # Clinical indicators
    malnutrition_risk = Column(String)  # none, low, moderate, high
    nutritional_status = Column(String)  # well-nourished, at-risk, malnourished

    # Biochemical data
    albumin = Column(Float)  # g/dL
    prealbumin = Column(Float)  # mg/dL
    hemoglobin = Column(Float)  # g/dL
    hematocrit = Column(Float)  # %

    # Dietary assessment
    calorie_intake = Column(Integer)  # kcal/day
    protein_intake = Column(Float)  # g/day
    dietary_adequacy = Column(Float)  # % of requirements met

    # Clinical findings
    findings = Column(JSON)
    diagnosis = Column(Text)
    care_plan = Column(JSON)

    # Goals and recommendations
    short_term_goals = Column(JSON)
    long_term_goals = Column(JSON)
    interventions = Column(JSON)

    # Follow-up
    next_assessment_date = Column(Date)
    notes = Column(Text)

    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow)

    # Relationships
    user = relationship("User", back_populates="clinical_assessments")
