//
//  Clinical.swift
//  NutriVision AI
//
//  Clinical nutrition models
//

import Foundation

// MARK: - Medical Condition

struct MedicalCondition: Codable, Identifiable {
    let id: Int
    let conditionName: String
    let conditionType: String?
    let severity: String?
    let diagnosisDate: Date?
    let isActive: Bool
    let medications: [String]
    let dietaryRestrictions: [String]
    let targetNutrients: [String: Double]
    let notes: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case conditionName = "condition_name"
        case conditionType = "condition_type"
        case severity
        case diagnosisDate = "diagnosis_date"
        case isActive = "is_active"
        case medications
        case dietaryRestrictions = "dietary_restrictions"
        case targetNutrients = "target_nutrients"
        case notes
        case createdAt = "created_at"
    }
}

// MARK: - Lab Result

struct LabResult: Codable, Identifiable {
    let id: Int
    let testName: String
    let testType: String?
    let testDate: Date
    let resultValue: Double
    let resultUnit: String
    let referenceRangeLow: Double?
    let referenceRangeHigh: Double?
    let status: String?
    let flagged: Bool
    let orderedBy: String?
    let notes: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case testName = "test_name"
        case testType = "test_type"
        case testDate = "test_date"
        case resultValue = "result_value"
        case resultUnit = "result_unit"
        case referenceRangeLow = "reference_range_low"
        case referenceRangeHigh = "reference_range_high"
        case status, flagged
        case orderedBy = "ordered_by"
        case notes
        case createdAt = "created_at"
    }

    var isAbnormal: Bool {
        flagged
    }

    var statusColor: String {
        switch status {
        case "low": return "blue"
        case "high": return "orange"
        case "critical": return "red"
        default: return "green"
        }
    }
}

// MARK: - Nutrient Deficiency

struct NutrientDeficiency: Codable, Identifiable {
    let id: Int
    let nutrientName: String
    let severity: String?
    let diagnosisDate: Date?
    let isResolved: Bool
    let resolutionDate: Date?
    let supplementName: String?
    let supplementDosage: String?
    let targetLevel: Double?
    let currentLevel: Double?
    let unit: String?
    let symptoms: [String]
    let dietarySources: [String]
    let notes: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case nutrientName = "nutrient_name"
        case severity
        case diagnosisDate = "diagnosis_date"
        case isResolved = "is_resolved"
        case resolutionDate = "resolution_date"
        case supplementName = "supplement_name"
        case supplementDosage = "supplement_dosage"
        case targetLevel = "target_level"
        case currentLevel = "current_level"
        case unit, symptoms
        case dietarySources = "dietary_sources"
        case notes
        case createdAt = "created_at"
    }
}

// MARK: - Therapeutic Diet

struct TherapeuticDiet: Codable, Identifiable {
    let id: Int
    let dietName: String
    let dietType: String?
    let prescribedFor: String?
    let prescribedBy: String?
    let prescriptionDate: Date?
    let isActive: Bool
    let calorieTarget: Int?
    let proteinTarget: Double?
    let sodiumLimit: Double?
    let potassiumLimit: Double?
    let phosphorusLimit: Double?
    let fluidLimit: Double?
    let foodRestrictions: [String]
    let foodAllowances: [String]
    let portionGuidelines: [String: String]
    let complianceScore: Double?
    let clinicalGoals: [String]
    let notes: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case dietName = "diet_name"
        case dietType = "diet_type"
        case prescribedFor = "prescribed_for"
        case prescribedBy = "prescribed_by"
        case prescriptionDate = "prescription_date"
        case isActive = "is_active"
        case calorieTarget = "calorie_target"
        case proteinTarget = "protein_target"
        case sodiumLimit = "sodium_limit"
        case potassiumLimit = "potassium_limit"
        case phosphorusLimit = "phosphorus_limit"
        case fluidLimit = "fluid_limit"
        case foodRestrictions = "food_restrictions"
        case foodAllowances = "food_allowances"
        case portionGuidelines = "portion_guidelines"
        case complianceScore = "compliance_score"
        case clinicalGoals = "clinical_goals"
        case notes
        case createdAt = "created_at"
    }
}

// MARK: - Clinical Assessment

struct ClinicalAssessment: Codable, Identifiable {
    let id: Int
    let assessmentDate: Date
    let assessedBy: String?
    let assessmentType: String?
    let weight: Double?
    let height: Double?
    let bmi: Double?
    let waistCircumference: Double?
    let bodyFatPercentage: Double?
    let malnutritionRisk: String?
    let nutritionalStatus: String?
    let calorieIntake: Int?
    let proteinIntake: Double?
    let findings: [String: String]
    let diagnosis: String?
    let shortTermGoals: [String]
    let longTermGoals: [String]
    let interventions: [String]
    let notes: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case assessmentDate = "assessment_date"
        case assessedBy = "assessed_by"
        case assessmentType = "assessment_type"
        case weight, height, bmi
        case waistCircumference = "waist_circumference"
        case bodyFatPercentage = "body_fat_percentage"
        case malnutritionRisk = "malnutrition_risk"
        case nutritionalStatus = "nutritional_status"
        case calorieIntake = "calorie_intake"
        case proteinIntake = "protein_intake"
        case findings, diagnosis
        case shortTermGoals = "short_term_goals"
        case longTermGoals = "long_term_goals"
        case interventions, notes
        case createdAt = "created_at"
    }

    var bmiCategory: String {
        guard let bmi = bmi else { return "Unknown" }
        switch bmi {
        case ..<18.5: return "Underweight"
        case 18.5..<25: return "Normal"
        case 25..<30: return "Overweight"
        default: return "Obese"
        }
    }
}

// MARK: - Medication Nutrient Interaction

struct MedicationNutrientInteraction: Codable, Identifiable {
    let id: Int
    let medicationName: String
    let medicationClass: String?
    let dosage: String?
    let interactingNutrient: String
    let interactionType: String
    let severity: String
    let description: String?
    let recommendations: [String]
    let timingInstructions: String?
    let isActive: Bool
    let acknowledged: Bool
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case medicationName = "medication_name"
        case medicationClass = "medication_class"
        case dosage
        case interactingNutrient = "interacting_nutrient"
        case interactionType = "interaction_type"
        case severity, description, recommendations
        case timingInstructions = "timing_instructions"
        case isActive = "is_active"
        case acknowledged
        case createdAt = "created_at"
    }

    var severityColor: String {
        switch severity.lowercased() {
        case "severe": return "red"
        case "moderate": return "orange"
        default: return "yellow"
        }
    }
}

// MARK: - Create Request Models

struct CreateMedicalConditionRequest: Codable {
    let conditionName: String
    let conditionType: String?
    let severity: String?
    let diagnosisDate: Date?
    let medications: [String]
    let dietaryRestrictions: [String]
    let targetNutrients: [String: Double]
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case conditionName = "condition_name"
        case conditionType = "condition_type"
        case severity
        case diagnosisDate = "diagnosis_date"
        case medications
        case dietaryRestrictions = "dietary_restrictions"
        case targetNutrients = "target_nutrients"
        case notes
    }
}

struct CreateLabResultRequest: Codable {
    let testName: String
    let testType: String?
    let testDate: Date
    let resultValue: Double
    let resultUnit: String
    let referenceRangeLow: Double?
    let referenceRangeHigh: Double?
    let orderedBy: String?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case testName = "test_name"
        case testType = "test_type"
        case testDate = "test_date"
        case resultValue = "result_value"
        case resultUnit = "result_unit"
        case referenceRangeLow = "reference_range_low"
        case referenceRangeHigh = "reference_range_high"
        case orderedBy = "ordered_by"
        case notes
    }
}

struct CreateNutrientDeficiencyRequest: Codable {
    let nutrientName: String
    let severity: String?
    let diagnosisDate: Date?
    let supplementName: String?
    let supplementDosage: String?
    let targetLevel: Double?
    let currentLevel: Double?
    let unit: String?
    let symptoms: [String]
    let dietarySources: [String]

    enum CodingKeys: String, CodingKey {
        case nutrientName = "nutrient_name"
        case severity
        case diagnosisDate = "diagnosis_date"
        case supplementName = "supplement_name"
        case supplementDosage = "supplement_dosage"
        case targetLevel = "target_level"
        case currentLevel = "current_level"
        case unit, symptoms
        case dietarySources = "dietary_sources"
    }
}
