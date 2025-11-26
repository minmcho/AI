"""
Micronutrient tracking models

Comprehensive tracking of vitamins, minerals, and micronutrients for:
- Detailed nutritional analysis
- Deficiency detection
- Treatment-specific dietary recommendations
- Research and health insights
"""

from sqlalchemy import Column, Integer, String, Float, Boolean, DateTime, JSON, Text, ForeignKey, Enum as SQLEnum
from sqlalchemy.orm import relationship
from datetime import datetime
from enum import Enum
from app.db.database import Base


class MicronutrientType(str, Enum):
    """Types of micronutrients"""
    VITAMIN = "vitamin"
    MINERAL = "mineral"
    TRACE_ELEMENT = "trace_element"
    PHYTONUTRIENT = "phytonutrient"
    OMEGA_FATTY_ACID = "omega_fatty_acid"
    AMINO_ACID = "amino_acid"


class MicronutrientUnit(str, Enum):
    """Units for micronutrient measurements"""
    MG = "mg"  # milligrams
    MCG = "mcg"  # micrograms
    IU = "iu"  # international units
    G = "g"  # grams
    PERCENT_DV = "percent_dv"  # percentage of daily value


class Micronutrient(Base):
    """
    Master table of micronutrients

    Defines all tracked vitamins, minerals, and micronutrients
    with their recommended daily values and health benefits.
    """
    __tablename__ = "micronutrients"

    id = Column(Integer, primary_key=True, index=True)
    code = Column(String, unique=True, nullable=False, index=True)  # e.g., VIT_D, CA, FE
    name = Column(String, nullable=False)  # e.g., Vitamin D, Calcium, Iron
    common_name = Column(String)  # Alternative names

    # Classification
    type = Column(SQLEnum(MicronutrientType), nullable=False, index=True)
    category = Column(String)  # Fat-soluble, Water-soluble, Major mineral, etc.

    # Measurement
    default_unit = Column(SQLEnum(MicronutrientUnit), nullable=False)

    # Recommended Daily Values (adult average)
    rda_male = Column(Float)  # Recommended Dietary Allowance for adult males
    rda_female = Column(Float)  # RDA for adult females
    rda_pregnant = Column(Float)  # RDA for pregnant women
    rda_lactating = Column(Float)  # RDA for lactating women
    rda_children = Column(Float)  # RDA for children (averaged)

    # Safety limits
    upper_limit = Column(Float)  # Tolerable Upper Intake Level (UL)
    toxicity_threshold = Column(Float)  # Level at which toxicity begins

    # Health information
    description = Column(Text)  # What it does
    health_benefits = Column(JSON)  # List of health benefits
    deficiency_symptoms = Column(JSON)  # Symptoms of deficiency
    food_sources = Column(JSON)  # Top food sources
    interactions = Column(JSON)  # Interactions with medications/nutrients

    # Medical relevance
    critical_for_conditions = Column(JSON)  # Medical conditions where this is critical
    contraindications = Column(JSON)  # When supplementation should be avoided

    # Metadata
    is_essential = Column(Boolean, default=True)  # Essential vs non-essential
    bioavailability_info = Column(Text)  # How well it's absorbed
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


class UserMicronutrientTarget(Base):
    """
    Personalized micronutrient targets for users

    Customized RDAs based on:
    - Age, sex, pregnancy/lactation status
    - Medical conditions
    - Treatment requirements
    - Activity level
    - Genetic factors
    """
    __tablename__ = "user_micronutrient_targets"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    micronutrient_id = Column(Integer, ForeignKey("micronutrients.id"), nullable=False)

    # Personalized target
    daily_target = Column(Float, nullable=False)  # Personalized daily target
    unit = Column(SQLEnum(MicronutrientUnit), nullable=False)

    # Why this target was set
    basis = Column(String)  # rda, medical_condition, deficiency, treatment, athlete
    condition_specific = Column(String)  # If for medical condition, which one
    notes = Column(Text)  # Additional context

    # Tracking
    priority = Column(String, default="medium")  # low, medium, high, critical
    monitor_closely = Column(Boolean, default=False)  # Flag for extra attention

    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    micronutrient = relationship("Micronutrient")


class MealMicronutrients(Base):
    """
    Micronutrient content of meals

    Links meals to their micronutrient breakdown for detailed analysis.
    """
    __tablename__ = "meal_micronutrients"

    id = Column(Integer, primary_key=True, index=True)
    meal_plan_id = Column(Integer, ForeignKey("meal_plans.id", ondelete="CASCADE"), index=True)
    micronutrient_id = Column(Integer, ForeignKey("micronutrients.id"), nullable=False)

    # Amount
    amount = Column(Float, nullable=False)
    unit = Column(SQLEnum(MicronutrientUnit), nullable=False)

    # Percentage of daily value
    percent_dv = Column(Float)  # Percentage of recommended daily value

    # Source tracking
    primary_sources = Column(JSON)  # Which ingredients contributed most

    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow)

    # Relationships
    micronutrient = relationship("Micronutrient")


class MicronutrientDeficiency(Base):
    """
    Detected micronutrient deficiencies

    PHI: Contains protected health information
    Encryption: medical_notes, symptoms, lab_results
    """
    __tablename__ = "micronutrient_deficiencies"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    micronutrient_id = Column(Integer, ForeignKey("micronutrients.id"), nullable=False)

    # Deficiency details
    severity = Column(String)  # mild, moderate, severe, critical
    detected_date = Column(DateTime, default=datetime.utcnow, index=True)
    resolved_date = Column(DateTime, nullable=True)
    is_active = Column(Boolean, default=True, index=True)

    # Clinical information (PHI - should be encrypted)
    symptoms = Column(Text)  # ENCRYPTED: Reported symptoms
    lab_results = Column(Text)  # ENCRYPTED: Lab test results
    diagnosis_code = Column(String)  # ICD-10 code if applicable
    diagnosed_by = Column(String)  # Healthcare provider (encrypted)

    # Treatment
    treatment_plan = Column(JSON)  # Recommended interventions
    supplementation_required = Column(Boolean, default=False)
    dietary_changes = Column(JSON)  # Recommended food sources

    # Monitoring
    retest_date = Column(DateTime)  # When to recheck levels
    medical_notes = Column(Text)  # ENCRYPTED: Additional notes

    # HIPAA tracking
    last_accessed = Column(DateTime)  # Track PHI access
    access_count = Column(Integer, default=0)

    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    micronutrient = relationship("Micronutrient")


class DailyMicronutrientIntake(Base):
    """
    Daily tracking of micronutrient intake

    Aggregates micronutrient intake from all meals for daily analysis.
    """
    __tablename__ = "daily_micronutrient_intake"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    date = Column(DateTime, nullable=False, index=True)
    micronutrient_id = Column(Integer, ForeignKey("micronutrients.id"), nullable=False)

    # Intake
    total_amount = Column(Float, nullable=False)
    unit = Column(SQLEnum(MicronutrientUnit), nullable=False)

    # Analysis
    percent_of_target = Column(Float)  # Percentage of user's personalized target
    status = Column(String)  # deficient, low, adequate, high, excessive

    # Sources
    from_food = Column(Float)  # Amount from food
    from_supplements = Column(Float, default=0)  # Amount from supplements

    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow)

    # Relationships
    micronutrient = relationship("Micronutrient")


# Pre-populate essential micronutrients data
ESSENTIAL_MICRONUTRIENTS = [
    # Vitamins - Fat Soluble
    {
        "code": "VIT_A",
        "name": "Vitamin A (Retinol)",
        "type": MicronutrientType.VITAMIN,
        "category": "fat_soluble",
        "default_unit": MicronutrientUnit.MCG,
        "rda_male": 900,
        "rda_female": 700,
        "rda_pregnant": 770,
        "upper_limit": 3000,
        "health_benefits": ["vision", "immune_function", "skin_health", "reproduction"],
        "deficiency_symptoms": ["night_blindness", "dry_eyes", "weak_immunity"],
        "food_sources": ["sweet_potato", "carrots", "spinach", "liver", "eggs"],
    },
    {
        "code": "VIT_D",
        "name": "Vitamin D (Calciferol)",
        "type": MicronutrientType.VITAMIN,
        "category": "fat_soluble",
        "default_unit": MicronutrientUnit.IU,
        "rda_male": 600,
        "rda_female": 600,
        "rda_pregnant": 600,
        "upper_limit": 4000,
        "health_benefits": ["bone_health", "immune_support", "mood_regulation", "calcium_absorption"],
        "deficiency_symptoms": ["bone_pain", "muscle_weakness", "fatigue", "depression"],
        "food_sources": ["sunlight", "fatty_fish", "fortified_milk", "eggs", "mushrooms"],
        "critical_for_conditions": ["osteoporosis", "rickets", "multiple_sclerosis", "diabetes"],
    },
    {
        "code": "VIT_E",
        "name": "Vitamin E (Tocopherol)",
        "type": MicronutrientType.VITAMIN,
        "category": "fat_soluble",
        "default_unit": MicronutrientUnit.MG,
        "rda_male": 15,
        "rda_female": 15,
        "rda_pregnant": 15,
        "upper_limit": 1000,
        "health_benefits": ["antioxidant", "immune_function", "skin_health", "heart_health"],
        "food_sources": ["nuts", "seeds", "vegetable_oils", "spinach", "avocado"],
    },
    {
        "code": "VIT_K",
        "name": "Vitamin K",
        "type": MicronutrientType.VITAMIN,
        "category": "fat_soluble",
        "default_unit": MicronutrientUnit.MCG,
        "rda_male": 120,
        "rda_female": 90,
        "health_benefits": ["blood_clotting", "bone_health", "heart_health"],
        "food_sources": ["kale", "spinach", "broccoli", "brussels_sprouts"],
        "contraindications": ["blood_thinners_warfarin"],
    },

    # Vitamins - Water Soluble (B Complex)
    {
        "code": "VIT_B1",
        "name": "Vitamin B1 (Thiamine)",
        "type": MicronutrientType.VITAMIN,
        "category": "water_soluble",
        "default_unit": MicronutrientUnit.MG,
        "rda_male": 1.2,
        "rda_female": 1.1,
        "health_benefits": ["energy_metabolism", "nerve_function", "heart_health"],
        "food_sources": ["whole_grains", "pork", "legumes", "nuts"],
    },
    {
        "code": "VIT_B12",
        "name": "Vitamin B12 (Cobalamin)",
        "type": MicronutrientType.VITAMIN,
        "category": "water_soluble",
        "default_unit": MicronutrientUnit.MCG,
        "rda_male": 2.4,
        "rda_female": 2.4,
        "rda_pregnant": 2.6,
        "health_benefits": ["red_blood_cell_formation", "nerve_function", "DNA_synthesis"],
        "deficiency_symptoms": ["anemia", "fatigue", "nerve_damage", "cognitive_issues"],
        "food_sources": ["meat", "fish", "dairy", "eggs", "fortified_cereals"],
        "critical_for_conditions": ["pernicious_anemia", "vegan_diet", "elderly"],
    },
    {
        "code": "VIT_C",
        "name": "Vitamin C (Ascorbic Acid)",
        "type": MicronutrientType.VITAMIN,
        "category": "water_soluble",
        "default_unit": MicronutrientUnit.MG,
        "rda_male": 90,
        "rda_female": 75,
        "rda_pregnant": 85,
        "upper_limit": 2000,
        "health_benefits": ["immune_support", "antioxidant", "collagen_synthesis", "iron_absorption"],
        "deficiency_symptoms": ["scurvy", "bleeding_gums", "slow_wound_healing"],
        "food_sources": ["citrus_fruits", "strawberries", "bell_peppers", "broccoli"],
    },

    # Minerals - Major
    {
        "code": "CA",
        "name": "Calcium",
        "type": MicronutrientType.MINERAL,
        "category": "major_mineral",
        "default_unit": MicronutrientUnit.MG,
        "rda_male": 1000,
        "rda_female": 1000,
        "rda_pregnant": 1000,
        "upper_limit": 2500,
        "health_benefits": ["bone_health", "muscle_function", "nerve_transmission", "heart_rhythm"],
        "deficiency_symptoms": ["osteoporosis", "muscle_cramps", "numbness"],
        "food_sources": ["dairy", "leafy_greens", "fortified_foods", "sardines"],
        "critical_for_conditions": ["osteoporosis", "osteopenia", "rickets"],
    },
    {
        "code": "MG",
        "name": "Magnesium",
        "type": MicronutrientType.MINERAL,
        "category": "major_mineral",
        "default_unit": MicronutrientUnit.MG,
        "rda_male": 400,
        "rda_female": 310,
        "rda_pregnant": 350,
        "health_benefits": ["muscle_function", "nerve_function", "blood_pressure", "blood_sugar"],
        "deficiency_symptoms": ["muscle_cramps", "fatigue", "irregular_heartbeat"],
        "food_sources": ["nuts", "seeds", "whole_grains", "leafy_greens", "legumes"],
        "critical_for_conditions": ["diabetes", "hypertension", "migraines"],
    },
    {
        "code": "K",
        "name": "Potassium",
        "type": MicronutrientType.MINERAL,
        "category": "major_mineral",
        "default_unit": MicronutrientUnit.MG,
        "rda_male": 3400,
        "rda_female": 2600,
        "health_benefits": ["blood_pressure", "heart_health", "muscle_function", "nerve_transmission"],
        "food_sources": ["bananas", "potatoes", "beans", "spinach", "avocado"],
        "critical_for_conditions": ["hypertension", "heart_disease", "kidney_disease"],
    },

    # Minerals - Trace
    {
        "code": "FE",
        "name": "Iron",
        "type": MicronutrientType.MINERAL,
        "category": "trace_element",
        "default_unit": MicronutrientUnit.MG,
        "rda_male": 8,
        "rda_female": 18,
        "rda_pregnant": 27,
        "upper_limit": 45,
        "health_benefits": ["oxygen_transport", "energy_production", "immune_function"],
        "deficiency_symptoms": ["anemia", "fatigue", "weakness", "pale_skin"],
        "food_sources": ["red_meat", "poultry", "fish", "lentils", "spinach", "fortified_cereals"],
        "critical_for_conditions": ["anemia", "pregnancy", "heavy_menstruation"],
    },
    {
        "code": "ZN",
        "name": "Zinc",
        "type": MicronutrientType.MINERAL,
        "category": "trace_element",
        "default_unit": MicronutrientUnit.MG,
        "rda_male": 11,
        "rda_female": 8,
        "rda_pregnant": 11,
        "upper_limit": 40,
        "health_benefits": ["immune_function", "wound_healing", "protein_synthesis", "DNA_synthesis"],
        "deficiency_symptoms": ["weak_immunity", "hair_loss", "slow_wound_healing"],
        "food_sources": ["oysters", "beef", "pork", "chicken", "beans", "nuts"],
    },
    {
        "code": "SE",
        "name": "Selenium",
        "type": MicronutrientType.MINERAL,
        "category": "trace_element",
        "default_unit": MicronutrientUnit.MCG,
        "rda_male": 55,
        "rda_female": 55,
        "rda_pregnant": 60,
        "upper_limit": 400,
        "health_benefits": ["antioxidant", "thyroid_function", "immune_support", "reproduction"],
        "food_sources": ["brazil_nuts", "seafood", "meat", "eggs"],
    },

    # Omega Fatty Acids
    {
        "code": "OMEGA3",
        "name": "Omega-3 Fatty Acids",
        "type": MicronutrientType.OMEGA_FATTY_ACID,
        "default_unit": MicronutrientUnit.G,
        "rda_male": 1.6,
        "rda_female": 1.1,
        "health_benefits": ["heart_health", "brain_function", "inflammation_reduction", "mood"],
        "food_sources": ["fatty_fish", "flaxseeds", "chia_seeds", "walnuts", "algae_oil"],
        "critical_for_conditions": ["cardiovascular_disease", "depression", "arthritis"],
    },
]
