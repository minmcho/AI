//
//  ClinicalNutritionService.swift
//  NutriVision AI
//
//  Service for clinical nutrition features
//

import Foundation

class ClinicalNutritionService {
    private let apiClient = APIClient.shared

    // MARK: - Medical Conditions

    func getMedicalConditions(activeOnly: Bool = true) async throws -> [MedicalCondition] {
        return try await apiClient.request(
            endpoint: "/clinical/conditions?active_only=\(activeOnly)",
            method: "GET"
        )
    }

    func createMedicalCondition(_ request: CreateMedicalConditionRequest) async throws -> MedicalCondition {
        return try await apiClient.request(
            endpoint: "/clinical/conditions",
            method: "POST",
            body: request
        )
    }

    // MARK: - Lab Results

    func getLabResults(testName: String? = nil, flaggedOnly: Bool = false, limit: Int = 50) async throws -> [LabResult] {
        var endpoint = "/clinical/lab-results?limit=\(limit)"
        if let testName = testName {
            endpoint += "&test_name=\(testName)"
        }
        if flaggedOnly {
            endpoint += "&flagged_only=true"
        }

        return try await apiClient.request(
            endpoint: endpoint,
            method: "GET"
        )
    }

    func createLabResult(_ request: CreateLabResultRequest) async throws -> LabResult {
        return try await apiClient.request(
            endpoint: "/clinical/lab-results",
            method: "POST",
            body: request
        )
    }

    // MARK: - Nutrient Deficiencies

    func getNutrientDeficiencies(activeOnly: Bool = true) async throws -> [NutrientDeficiency] {
        return try await apiClient.request(
            endpoint: "/clinical/deficiencies?active_only=\(activeOnly)",
            method: "GET"
        )
    }

    func createNutrientDeficiency(_ request: CreateNutrientDeficiencyRequest) async throws -> NutrientDeficiency {
        return try await apiClient.request(
            endpoint: "/clinical/deficiencies",
            method: "POST",
            body: request
        )
    }

    func resolveDeficiency(id: Int) async throws {
        let _: EmptyResponse = try await apiClient.request(
            endpoint: "/clinical/deficiencies/\(id)/resolve",
            method: "PATCH"
        )
    }

    // MARK: - Therapeutic Diets

    func getTherapeuticDiets(activeOnly: Bool = true) async throws -> [TherapeuticDiet] {
        return try await apiClient.request(
            endpoint: "/clinical/therapeutic-diets?active_only=\(activeOnly)",
            method: "GET"
        )
    }

    // MARK: - Clinical Assessments

    func getClinicalAssessments(limit: Int = 20) async throws -> [ClinicalAssessment] {
        return try await apiClient.request(
            endpoint: "/clinical/assessments?limit=\(limit)",
            method: "GET"
        )
    }

    func getLatestAssessment() async throws -> ClinicalAssessment {
        return try await apiClient.request(
            endpoint: "/clinical/assessments/latest",
            method: "GET"
        )
    }

    // MARK: - Medication Interactions

    func getMedicationInteractions() async throws -> [MedicationNutrientInteraction] {
        return try await apiClient.request(
            endpoint: "/clinical/medication-interactions",
            method: "GET"
        )
    }

    // MARK: - Reports

    struct ComplianceReport: Codable {
        let message: String
        let userId: Int
        let startDate: Date?
        let endDate: Date?

        enum CodingKeys: String, CodingKey {
            case message
            case userId = "user_id"
            case startDate = "start_date"
            case endDate = "end_date"
        }
    }

    struct NutritionStatusReport: Codable {
        let userId: Int
        let reportDate: Date
        let activeConditions: [String]
        let recentLabs: Int
        let activeDeficiencies: [String]
        let therapeuticDiets: [String]
        let summary: String

        enum CodingKeys: String, CodingKey {
            case userId = "user_id"
            case reportDate = "report_date"
            case activeConditions = "active_conditions"
            case recentLabs = "recent_labs"
            case activeDeficiencies = "active_deficiencies"
            case therapeuticDiets = "therapeutic_diets"
            case summary
        }
    }

    func getComplianceReport(startDate: Date? = nil, endDate: Date? = nil) async throws -> ComplianceReport {
        var endpoint = "/clinical/reports/compliance"
        var params: [String] = []

        if let startDate = startDate {
            params.append("start_date=\(DateUtils.dateToString(startDate, format: "yyyy-MM-dd"))")
        }
        if let endDate = endDate {
            params.append("end_date=\(DateUtils.dateToString(endDate, format: "yyyy-MM-dd"))")
        }

        if !params.isEmpty {
            endpoint += "?" + params.joined(separator: "&")
        }

        return try await apiClient.request(
            endpoint: endpoint,
            method: "GET"
        )
    }

    func getNutritionStatusReport() async throws -> NutritionStatusReport {
        return try await apiClient.request(
            endpoint: "/clinical/reports/nutrition-status",
            method: "GET"
        )
    }
}
