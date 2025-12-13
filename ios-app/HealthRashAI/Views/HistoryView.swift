import SwiftUI

struct HistoryView: View {
    @State private var analyses: [AnalysisRecord] = []
    @State private var selectedAnalysis: AnalysisRecord?
    @State private var showingDeleteAlert = false
    @State private var analysisToDelete: AnalysisRecord?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.theme.background
                    .ignoresSafeArea()

                if analyses.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            // Stats header
                            statsHeader

                            // Analysis list
                            LazyVStack(spacing: 12) {
                                ForEach(analyses) { analysis in
                                    AnalysisHistoryCard(
                                        analysis: analysis,
                                        onTap: {
                                            selectedAnalysis = analysis
                                        },
                                        onDelete: {
                                            analysisToDelete = analysis
                                            showingDeleteAlert = true
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 30)
                        }
                        .padding(.top, 20)
                    }
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if !analyses.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            // Clear all
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(Color.theme.danger)
                        }
                    }
                }
            }
            .sheet(item: $selectedAnalysis) { analysis in
                AnalysisDetailSheet(analysis: analysis)
            }
            .alert("Delete Analysis", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let analysis = analysisToDelete {
                        deleteAnalysis(analysis)
                    }
                }
            } message: {
                Text("Are you sure you want to delete this analysis? This action cannot be undone.")
            }
            .onAppear {
                loadAnalyses()
            }
        }
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.theme.primary.opacity(0.2), Color.theme.primaryLight.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)

                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 50, weight: .light))
                    .foregroundColor(Color.theme.primary)
            }

            VStack(spacing: 12) {
                Text("No Analyses Yet")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color.theme.textPrimary)

                Text("Your analysis history will appear here. Start by taking a photo of a skin rash.")
                    .font(.system(size: 16))
                    .foregroundColor(Color.theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            // Quick start button
            NavigationLink(destination: CameraView()) {
                HStack(spacing: 12) {
                    Image(systemName: "camera.fill")
                    Text("Start First Analysis")
                    Image(systemName: "arrow.right")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .padding(.vertical, 16)
                .padding(.horizontal, 32)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.theme.primaryGradient)
                        .shadow(color: Color.theme.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                )
            }
        }
    }

    // MARK: - Stats Header
    private var statsHeader: some View {
        HStack(spacing: 12) {
            StatBadge(
                icon: "doc.text.fill",
                value: "\(analyses.count)",
                label: "Total",
                color: Color.theme.primary
            )

            StatBadge(
                icon: "checkmark.circle.fill",
                value: "\(analyses.filter { $0.severity == "low" }.count)",
                label: "Low",
                color: Color.theme.success
            )

            StatBadge(
                icon: "exclamationmark.triangle.fill",
                value: "\(analyses.filter { $0.severity == "high" }.count)",
                label: "High",
                color: Color.theme.danger
            )
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Helper Methods
    private func loadAnalyses() {
        // Mock data for demonstration
        analyses = [
            AnalysisRecord(
                id: "1",
                timestamp: Date().addingTimeInterval(-86400),
                question: "¿Es esto peligroso?",
                language: "es",
                severity: "low",
                response: "Basado en la imagen, esto parece ser una irritación leve...",
                careInstructions: ["Limpie suavemente el área", "Aplique crema hidratante"],
                seekMedicalAttention: false
            ),
            AnalysisRecord(
                id: "2",
                timestamp: Date().addingTimeInterval(-172800),
                question: "ဒါက အန္တရာယ်ရှိပါသလား။",
                language: "my",
                severity: "medium",
                response: "အဖုအပိမ့်များသည် အလယ်အလတ် ရောင်ရမ်းမှု...",
                careInstructions: ["ဆားရည်ဖြင့် သန့်ရှင်းပါ", "အအေးဓာတ်ကပ်ပါ"],
                seekMedicalAttention: false
            )
        ]
    }

    private func deleteAnalysis(_ analysis: AnalysisRecord) {
        withAnimation {
            analyses.removeAll { $0.id == analysis.id }
        }
    }
}

// MARK: - Analysis History Card
struct AnalysisHistoryCard: View {
    let analysis: AnalysisRecord
    let onTap: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Severity indicator
                VStack {
                    Circle()
                        .fill(severityColor)
                        .frame(width: 12, height: 12)

                    Rectangle()
                        .fill(severityColor.opacity(0.3))
                        .frame(width: 2)
                }

                VStack(alignment: .leading, spacing: 8) {
                    // Question
                    Text(analysis.question)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color.theme.textPrimary)
                        .lineLimit(2)

                    // Metadata
                    HStack(spacing: 12) {
                        Label(analysis.severity.capitalized, systemImage: "chart.bar.fill")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(severityColor)

                        Label(formattedDate, systemImage: "clock")
                            .font(.system(size: 12))
                            .foregroundColor(Color.theme.textSecondary)
                    }

                    // Preview
                    Text(analysis.response)
                        .font(.system(size: 13))
                        .foregroundColor(Color.theme.textSecondary)
                        .lineLimit(2)
                }

                Spacer()

                // Actions
                VStack(spacing: 12) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color.theme.textTertiary)

                    Spacer()

                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                            .foregroundColor(Color.theme.danger)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.theme.cardBackground)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var severityColor: Color {
        switch analysis.severity {
        case "low": return Color.theme.success
        case "medium": return Color.theme.warning
        case "high": return Color.theme.danger
        default: return Color.theme.textSecondary
        }
    }

    private var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: analysis.timestamp, relativeTo: Date())
    }
}

// MARK: - Stat Badge
struct StatBadge: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(Color.theme.textPrimary)

            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color.theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Analysis Detail Sheet
struct AnalysisDetailSheet: View {
    @Environment(\.dismiss) var dismiss
    let analysis: AnalysisRecord

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Severity badge
                    HStack {
                        Spacer()
                        Text(analysis.severity.uppercased())
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(severityColor)
                            )
                        Spacer()
                    }

                    // Question
                    SectionCard(
                        icon: "❓",
                        title: "Question",
                        content: analysis.question
                    )

                    // Response
                    SectionCard(
                        icon: "🩺",
                        title: "Medical Analysis",
                        content: analysis.response
                    )

                    // Care Instructions
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("📋")
                                .font(.system(size: 24))
                            Text("Care Instructions")
                                .font(.system(size: 18, weight: .semibold))
                        }

                        ForEach(Array(analysis.careInstructions.enumerated()), id: \.offset) { index, instruction in
                            HStack(alignment: .top, spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color.theme.primary)
                                        .frame(width: 28, height: 28)

                                    Text("\(index + 1)")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                }

                                Text(instruction)
                                    .font(.system(size: 15))
                                    .foregroundColor(Color.theme.textPrimary)
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.theme.cardBackground)
                    )
                }
                .padding()
            }
            .navigationTitle("Analysis Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var severityColor: Color {
        switch analysis.severity {
        case "low": return Color.theme.success
        case "medium": return Color.theme.warning
        case "high": return Color.theme.danger
        default: return Color.gray
        }
    }
}

// MARK: - Section Card
struct SectionCard: View {
    let icon: String
    let title: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(icon)
                    .font(.system(size: 24))
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
            }

            Text(content)
                .font(.system(size: 16))
                .foregroundColor(Color.theme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.theme.cardBackground)
        )
    }
}

// MARK: - Analysis Record Model
struct AnalysisRecord: Identifiable, Codable {
    let id: String
    let timestamp: Date
    let question: String
    let language: String
    let severity: String
    let response: String
    let careInstructions: [String]
    let seekMedicalAttention: Bool
}

struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryView()
    }
}
