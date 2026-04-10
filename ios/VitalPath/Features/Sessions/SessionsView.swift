// SessionsView.swift — VitalPath AI
// Progress dashboard: habit logging, goal tracking, session history,
// wearable data, and AI-suggested next goals.

import SwiftUI

// MARK: - ViewModel

@MainActor
@Observable
final class SessionsViewModel {
    var goals: [WellnessGoal] = []
    var suggestedGoals: [AIGoalSuggestion] = []
    var isLoading = false
    var showHabitSheet = false
    var showGoalSheet = false
    var habitCategory: GoalCategory = .exercise
    var habitValue: String = ""
    var habitUnit: String = ""
    var habitNotes: String = ""

    private let client = GraphQLClient.shared

    func loadGoals() async {
        isLoading = true
        defer { isLoading = false }
        do {
            struct GoalsData: Decodable { let myGoals: [WellnessGoal] }
            let data = try await client.execute(query: GQL.myGoals, variables: ["activeOnly": true], type: GoalsData.self)
            withAnimation(AppAnimation.spring) { goals = data.myGoals }
        } catch {}
    }

    func loadSuggestions() async {
        do {
            struct SuggestData: Decodable { let suggestedGoals: [AIGoalSuggestion] }
            let data = try await client.execute(query: GQL.suggestedGoals, type: SuggestData.self)
            withAnimation(AppAnimation.spring) { suggestedGoals = data.suggestedGoals }
        } catch {}
    }

    func logHabit() async {
        guard let value = Double(habitValue), !habitUnit.isEmpty else { return }
        do {
            let variables: [String: Any] = [
                "input": [
                    "category": habitCategory.rawValue.uppercased(),
                    "value": value,
                    "unit": habitUnit,
                    "notes": habitNotes,
                ]
            ]
            struct LogData: Decodable { let logHabit: WellnessSession }
            _ = try await client.execute(query: GQL.logHabit, variables: variables, type: LogData.self)
            showHabitSheet = false
            habitValue = ""
            habitNotes = ""
            await loadGoals()
        } catch {}
    }
}

// MARK: - View

struct SessionsView: View {
    @State private var viewModel = SessionsViewModel()
    @State private var selectedSegment = 0
    @State private var appear = false
    private let segments = ["Goals", "Suggested", "History"]

    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedMeshBackground().ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    sessionsHeader

                    // Segment control
                    segmentControl
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.top, 8)

                    // Content
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: AppSpacing.md) {
                            Color.clear.frame(height: 8)

                            switch selectedSegment {
                            case 0: goalsSection
                            case 1: suggestionsSection
                            default: historySection
                            }

                            Color.clear.frame(height: AppSpacing.xxl)
                        }
                        .padding(.horizontal, AppSpacing.md)
                    }
                    .refreshable {
                        await viewModel.loadGoals()
                        await viewModel.loadSuggestions()
                    }
                }
            }
            .navigationBarHidden(true)
            .task {
                await viewModel.loadGoals()
                await viewModel.loadSuggestions()
            }
            .sheet(isPresented: $viewModel.showHabitSheet) { habitLogSheet }
        }
    }

    // MARK: - Header

    private var sessionsHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Progress")
                    .font(AppFont.display(28))
                    .foregroundStyle(.white)
                Text("Track your wellness journey")
                    .font(AppFont.body())
                    .foregroundStyle(.vitaTeal)
            }
            Spacer()
            PrimaryGlassButton(title: "Log Habit", icon: "plus") {
                viewModel.showHabitSheet = true
            }
            .frame(width: 130, height: 40)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.top, 60)
        .padding(.bottom, 8)
    }

    // MARK: - Segment

    private var segmentControl: some View {
        HStack(spacing: 0) {
            ForEach(Array(segments.enumerated()), id: \.offset) { idx, title in
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(AppAnimation.spring) { selectedSegment = idx }
                }) {
                    Text(title)
                        .font(AppFont.body(14))
                        .fontWeight(selectedSegment == idx ? .semibold : .regular)
                        .foregroundStyle(selectedSegment == idx ? .black : .white.opacity(0.6))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background {
                            if selectedSegment == idx {
                                RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                                    .fill(Color.vitaTeal)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background {
            RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                }
        }
    }

    // MARK: - Goals

    private var goalsSection: some View {
        Group {
            if viewModel.isLoading {
                ProgressView().tint(.vitaTeal).padding()
            } else if viewModel.goals.isEmpty {
                emptyState(
                    icon: "target",
                    title: "No active goals",
                    subtitle: "Check the Suggested tab for AI-powered goal ideas"
                )
            } else {
                ForEach(viewModel.goals) { goal in
                    GoalCard(goal: goal)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
    }

    // MARK: - Suggestions

    private var suggestionsSection: some View {
        Group {
            GlassCard(cornerRadius: AppRadius.md) {
                HStack(spacing: 12) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 24))
                        .foregroundStyle(.vitaIndigo)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("AI-Suggested Goals")
                            .font(AppFont.title(15)).foregroundStyle(.white)
                        Text("Based on your progress and profile")
                            .font(AppFont.caption(12)).foregroundStyle(.white.opacity(0.55))
                    }
                }
            }

            if viewModel.suggestedGoals.isEmpty {
                emptyState(icon: "sparkles", title: "Loading suggestions…", subtitle: "")
            } else {
                ForEach(viewModel.suggestedGoals) { suggestion in
                    SuggestionCard(suggestion: suggestion) {
                        // Accept suggestion → open create goal sheet
                    }
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
        }
    }

    // MARK: - History (placeholder)

    private var historySection: some View {
        emptyState(icon: "clock.arrow.circlepath", title: "Session history", subtitle: "Your past coaching sessions will appear here")
    }

    // MARK: - Empty state

    private func emptyState(icon: String, title: String, subtitle: String) -> some View {
        GlassCard {
            VStack(spacing: AppSpacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundStyle(.vitaTeal.opacity(0.7))
                Text(title)
                    .font(AppFont.title(16))
                    .foregroundStyle(.white)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(AppFont.body(14))
                        .foregroundStyle(.white.opacity(0.55))
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.xl)
        }
    }

    // MARK: - Habit log sheet

    private var habitLogSheet: some View {
        NavigationStack {
            ZStack {
                AppGradient.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: AppSpacing.lg) {
                        Text("Log a Habit")
                            .font(AppFont.display(24))
                            .foregroundStyle(.white)

                        // Category picker
                        GlassCard(cornerRadius: AppRadius.md) {
                            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                Text("Category")
                                    .font(AppFont.caption()).foregroundStyle(.white.opacity(0.55))
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: AppSpacing.sm) {
                                        ForEach(GoalCategory.allCases, id: \.rawValue) { cat in
                                            Button(action: {
                                                viewModel.habitCategory = cat
                                            }) {
                                                Label(cat.displayName, systemImage: cat.icon)
                                                    .font(AppFont.body(13))
                                                    .foregroundStyle(viewModel.habitCategory == cat ? .black : .white)
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 8)
                                                    .background(
                                                        Capsule().fill(viewModel.habitCategory == cat ? Color.vitaTeal : Color.white.opacity(0.1))
                                                    )
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                            }
                        }

                        // Value & unit
                        GlassCard(cornerRadius: AppRadius.md) {
                            HStack(spacing: AppSpacing.md) {
                                TextField("Value", text: $viewModel.habitValue)
                                    .font(AppFont.mono(32))
                                    .keyboardType(.decimalPad)
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                Divider().frame(height: 44).background(.white.opacity(0.15))
                                TextField("Unit", text: $viewModel.habitUnit)
                                    .font(AppFont.body())
                                    .foregroundStyle(.white)
                                    .frame(width: 80)
                            }
                        }

                        // Notes
                        GlassCard(cornerRadius: AppRadius.md) {
                            TextField("Notes (optional)", text: $viewModel.habitNotes, axis: .vertical)
                                .font(AppFont.body())
                                .foregroundStyle(.white)
                                .lineLimit(3...6)
                        }

                        PrimaryGlassButton(title: "Save Habit", icon: "checkmark.circle.fill") {
                            Task { await viewModel.logHabit() }
                        }
                    }
                    .padding(AppSpacing.lg)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { viewModel.showHabitSheet = false }
                        .foregroundStyle(.vitaTeal)
                }
            }
        }
        .presentationDetents([.large])
        .preferredColorScheme(.dark)
    }
}

// MARK: - Goal Card

struct GoalCard: View {
    let goal: WellnessGoal
    @State private var animatedProgress: Double = 0

    var body: some View {
        GlassCard(cornerRadius: AppRadius.md) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack {
                    Image(systemName: goal.category.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color(goal.category.color))
                    Text(goal.title)
                        .font(AppFont.title(15))
                        .foregroundStyle(.white)
                    Spacer()
                    if goal.aiSuggested {
                        Label("AI", systemImage: "sparkles")
                            .font(AppFont.caption(10))
                            .foregroundStyle(.vitaIndigo)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.vitaIndigo.opacity(0.15)))
                    }
                }

                if let description = goal.description {
                    Text(description)
                        .font(AppFont.body(13))
                        .foregroundStyle(.white.opacity(0.6))
                }

                // Progress bar
                if let target = goal.targetValue {
                    HStack(spacing: 8) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.08)).frame(height: 8)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(goal.category.color).opacity(0.85))
                                    .frame(width: geo.size.width * animatedProgress, height: 8)
                                    .animation(AppAnimation.spring, value: animatedProgress)
                            }
                        }
                        .frame(height: 8)

                        Text("\(Int(goal.currentValue)) / \(Int(target)) \(goal.unit ?? "")")
                            .font(AppFont.caption(11))
                            .foregroundStyle(.white.opacity(0.5))
                            .fixedSize()
                    }
                }
            }
        }
        .onAppear { animatedProgress = goal.progress }
    }
}

// MARK: - Suggestion Card

struct SuggestionCard: View {
    let suggestion: AIGoalSuggestion
    let onAccept: () -> Void

    var body: some View {
        GlassCard(cornerRadius: AppRadius.md) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack {
                    Image(systemName: suggestion.category.icon)
                        .font(.system(size: 18))
                        .foregroundStyle(Color(suggestion.category.color))
                    Text(suggestion.title)
                        .font(AppFont.title(15))
                        .foregroundStyle(.white)
                    Spacer()
                    Image(systemName: "sparkles")
                        .foregroundStyle(.vitaIndigo)
                }
                Text(suggestion.rationale)
                    .font(AppFont.body(13))
                    .foregroundStyle(.white.opacity(0.65))
                    .lineSpacing(3)

                if let target = suggestion.targetValue {
                    Text("Target: \(Int(target)) \(suggestion.unit ?? "")")
                        .font(AppFont.caption(12))
                        .foregroundStyle(.vitaTeal)
                }

                PrimaryGlassButton(title: "Add This Goal", icon: "plus.circle.fill",
                                   gradient: AppGradient.wellnessScore, action: onAccept)
                    .frame(height: 42)
            }
        }
    }
}

#Preview {
    SessionsView()
}
