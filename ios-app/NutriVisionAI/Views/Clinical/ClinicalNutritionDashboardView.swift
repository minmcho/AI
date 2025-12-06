//
//  ClinicalNutritionDashboardView.swift
//  NutriVision AI
//
//  Clinical nutrition dashboard
//

import SwiftUI

struct ClinicalNutritionDashboardView: View {
    @StateObject private var viewModel = ClinicalNutritionViewModel()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "heart.text.square.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.red)
                            VStack(alignment: .leading) {
                                Text("Clinical Nutrition")
                                    .font(.title)
                                    .fontWeight(.bold)
                                Text("Medical-grade nutrition management")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Medical Conditions
                    if !viewModel.medicalConditions.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "stethoscope")
                                    .foregroundColor(.blue)
                                Text("Medical Conditions")
                                    .font(.headline)
                                Spacer()
                                Text("\(viewModel.medicalConditions.count)")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.2))
                                    .cornerRadius(8)
                            }
                            .padding(.horizontal)

                            ForEach(viewModel.medicalConditions.prefix(3)) { condition in
                                ConditionCard(condition: condition)
                                    .padding(.horizontal)
                            }
                        }
                    }

                    // Lab Results - Flagged
                    if !viewModel.flaggedLabResults.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text("Attention Needed")
                                    .font(.headline)
                                Spacer()
                                Text("\(viewModel.flaggedLabResults.count)")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.orange.opacity(0.2))
                                    .cornerRadius(8)
                            }
                            .padding(.horizontal)

                            ForEach(viewModel.flaggedLabResults.prefix(2)) { lab in
                                LabResultCard(labResult: lab)
                                    .padding(.horizontal)
                            }
                        }
                    }

                    // Nutrient Deficiencies
                    if !viewModel.nutrientDeficiencies.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "pills.fill")
                                    .foregroundColor(.purple)
                                Text("Active Deficiencies")
                                    .font(.headline)
                                Spacer()
                                Text("\(viewModel.nutrientDeficiencies.count)")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.purple.opacity(0.2))
                                    .cornerRadius(8)
                            }
                            .padding(.horizontal)

                            ForEach(viewModel.nutrientDeficiencies) { deficiency in
                                DeficiencyCard(deficiency: deficiency) {
                                    await viewModel.resolveDeficiency(deficiency.id)
                                }
                                .padding(.horizontal)
                            }
                        }
                    }

                    // Therapeutic Diets
                    if !viewModel.therapeuticDiets.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "list.clipboard.fill")
                                    .foregroundColor(.green)
                                Text("Therapeutic Diets")
                                    .font(.headline)
                            }
                            .padding(.horizontal)

                            ForEach(viewModel.therapeuticDiets) { diet in
                                TherapeuticDietCard(diet: diet)
                                    .padding(.horizontal)
                            }
                        }
                    }

                    // Medication Interactions
                    if !viewModel.medicationInteractions.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "exclamationmark.shield.fill")
                                    .foregroundColor(.red)
                                Text("Medication Interactions")
                                    .font(.headline)
                            }
                            .padding(.horizontal)

                            ForEach(viewModel.medicationInteractions.prefix(3)) { interaction in
                                InteractionCard(interaction: interaction)
                                    .padding(.horizontal)
                            }
                        }
                    }

                    Spacer()
                }
                .padding(.vertical)
            }
            .navigationTitle("Clinical Nutrition")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                await viewModel.loadDashboard()
            }
            .task {
                await viewModel.loadDashboard()
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView("Loading...")
                }
            }
        }
    }
}

// MARK: - Condition Card

struct ConditionCard: View {
    let condition: MedicalCondition

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(condition.conditionName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                if let severity = condition.severity {
                    Text(severity.capitalized)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(severityColor(severity).opacity(0.2))
                        .foregroundColor(severityColor(severity))
                        .cornerRadius(8)
                }
            }

            if !condition.medications.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Medications:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    ForEach(condition.medications, id: \.self) { medication in
                        HStack(spacing: 4) {
                            Image(systemName: "pill.fill")
                                .font(.caption2)
                                .foregroundColor(.blue)
                            Text(medication)
                                .font(.caption)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }

    private func severityColor(_ severity: String) -> Color {
        switch severity.lowercased() {
        case "severe": return .red
        case "moderate": return .orange
        default: return .yellow
        }
    }
}

// MARK: - Lab Result Card

struct LabResultCard: View {
    let labResult: LabResult

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(labResult.testName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(getStatusColor())
            }

            HStack {
                Text("\(labResult.resultValue, specifier: "%.2f") \(labResult.resultUnit)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(getStatusColor())

                if let low = labResult.referenceRangeLow, let high = labResult.referenceRangeHigh {
                    Text("(\(low, specifier: "%.1f")-\(high, specifier: "%.1f"))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Text("Test Date: \(DateUtils.formatShort(labResult.testDate))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(getStatusColor().opacity(0.1))
        .cornerRadius(12)
    }

    private func getStatusColor() -> Color {
        switch labResult.status?.lowercased() {
        case "low": return .blue
        case "high": return .orange
        case "critical": return .red
        default: return .green
        }
    }
}

// MARK: - Deficiency Card

struct DeficiencyCard: View {
    let deficiency: NutrientDeficiency
    let onResolve: () async -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text(deficiency.nutrientName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    if let supplement = deficiency.supplementName {
                        Text("Taking: \(supplement)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Button {
                    Task {
                        await onResolve()
                    }
                } label: {
                    Text("Resolved")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }

            if let current = deficiency.currentLevel, let target = deficiency.targetLevel, let unit = deficiency.unit {
                HStack {
                    Text("Current: \(current, specifier: "%.1f") \(unit)")
                        .font(.caption)
                    Spacer()
                    Text("Target: \(target, specifier: "%.1f") \(unit)")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.purple.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Therapeutic Diet Card

struct TherapeuticDietCard: View {
    let diet: TherapeuticDiet

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(diet.dietName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                if let compliance = diet.complianceScore {
                    Text("\(Int(compliance))% compliance")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(complianceColor(compliance).opacity(0.2))
                        .foregroundColor(complianceColor(compliance))
                        .cornerRadius(8)
                }
            }

            if let prescribedFor = diet.prescribedFor {
                Text("For: \(prescribedFor)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let calories = diet.calorieTarget {
                Text("Calorie target: \(calories) kcal/day")
                    .font(.caption)
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
    }

    private func complianceColor(_ score: Double) -> Color {
        if score >= 80 { return .green }
        if score >= 60 { return .yellow }
        return .orange
    }
}

// MARK: - Interaction Card

struct InteractionCard: View {
    let interaction: MedicationNutrientInteraction

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(getSeverityColor())
                VStack(alignment: .leading) {
                    Text(interaction.medicationName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text("Interacts with: \(interaction.interactingNutrient)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }

            if let description = interaction.description {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(getSeverityColor().opacity(0.1))
        .cornerRadius(12)
    }

    private func getSeverityColor() -> Color {
        switch interaction.severity.lowercased() {
        case "severe": return .red
        case "moderate": return .orange
        default: return .yellow
        }
    }
}

// MARK: - ViewModel

@MainActor
class ClinicalNutritionViewModel: ObservableObject {
    @Published var medicalConditions: [MedicalCondition] = []
    @Published var labResults: [LabResult] = []
    @Published var nutrientDeficiencies: [NutrientDeficiency] = []
    @Published var therapeuticDiets: [TherapeuticDiet] = []
    @Published var medicationInteractions: [MedicationNutrientInteraction] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let clinicalService = ClinicalNutritionService()

    var flaggedLabResults: [LabResult] {
        labResults.filter { $0.flagged }
    }

    func loadDashboard() async {
        isLoading = true
        errorMessage = nil

        async let conditions = try? clinicalService.getMedicalConditions(activeOnly: true)
        async let labs = try? clinicalService.getLabResults(limit: 10)
        async let deficiencies = try? clinicalService.getNutrientDeficiencies(activeOnly: true)
        async let diets = try? clinicalService.getTherapeuticDiets(activeOnly: true)
        async let interactions = try? clinicalService.getMedicationInteractions()

        let results = await (conditions, labs, deficiencies, diets, interactions)

        medicalConditions = results.0 ?? []
        labResults = results.1 ?? []
        nutrientDeficiencies = results.2 ?? []
        therapeuticDiets = results.3 ?? []
        medicationInteractions = results.4 ?? []

        isLoading = false
    }

    func resolveDeficiency(_ id: Int) async {
        do {
            try await clinicalService.resolveDeficiency(id: id)
            await loadDashboard()
        } catch {
            errorMessage = "Failed to resolve deficiency"
        }
    }
}

// MARK: - Preview

struct ClinicalNutritionDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        ClinicalNutritionDashboardView()
    }
}
