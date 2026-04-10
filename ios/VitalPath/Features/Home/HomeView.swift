// HomeView.swift — VitalPath AI
// Dashboard with Apple Glass UI, animated greeting, streak, wellness score,
// and quick-action grid.

import SwiftUI

struct HomeView: View {
    @State private var viewModel = HomeViewModel()
    @EnvironmentObject private var appState: AppState
    @State private var showAchievement = false
    @State private var headerAppear = false
    @State private var cardsAppear = false
    @Namespace private var namespace

    var body: some View {
        NavigationStack {
            ZStack {
                // ── Animated background
                AnimatedMeshBackground()
                    .ignoresSafeArea()

                // Particle ambiance
                ParticleSystem(count: 12)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)

                // ── Content
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: AppSpacing.lg, pinnedViews: []) {
                        // Top spacer for status bar
                        Color.clear.frame(height: 60)

                        // ── Header greeting
                        headerSection
                            .opacity(headerAppear ? 1 : 0)
                            .offset(y: headerAppear ? 0 : -20)

                        // ── Streak card
                        streakCard
                            .transition(.asymmetric(
                                insertion: .move(edge: .leading).combined(with: .opacity),
                                removal: .opacity
                            ))

                        // ── Wellness score
                        wellnessScoreCard

                        // ── Quick actions
                        quickActionsSection

                        // ── Today's tip
                        dailyTipCard

                        // ── Wearable snapshot
                        wearableCard

                        Color.clear.frame(height: AppSpacing.xxl)
                    }
                    .padding(.horizontal, AppSpacing.md)
                }
                .refreshable { await viewModel.loadDashboard() }

                // Achievement burst overlay
                if showAchievement {
                    AchievementBurst(color: .vitaGold) { showAchievement = false }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .allowsHitTesting(false)
                }
            }
            .navigationBarHidden(true)
            .task { await viewModel.loadDashboard() }
            .onAppear {
                withAnimation(AppAnimation.entrance) { headerAppear = true }
                withAnimation(AppAnimation.entrance.delay(0.15)) { cardsAppear = true }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.greeting + ",")
                    .font(AppFont.body(17))
                    .foregroundStyle(.white.opacity(0.70))
                Text(viewModel.firstName)
                    .font(AppFont.display(34))
                    .foregroundStyle(.white)
            }
            Spacer()
            HStack(spacing: 12) {
                GlassIconButton(icon: "bell.fill", badgeCount: 0) {
                    // notifications
                }
                GlassIconButton(icon: "person.crop.circle") {
                    appState.selectedTab = .profile
                }
            }
        }
    }

    // MARK: - Streak Card

    private var streakCard: some View {
        GlowingGlassCard(glowColor: viewModel.streakInfo.currentStreak > 0 ? .vitaGold : .vitaTeal) {
            HStack(spacing: AppSpacing.md) {
                // Streak ring
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 4)
                        .frame(width: 72, height: 72)

                    Circle()
                        .trim(from: 0, to: min(CGFloat(viewModel.streakInfo.currentStreak) / 30.0, 1.0))
                        .stroke(AppGradient.streak, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 72, height: 72)
                        .rotationEffect(.degrees(-90))
                        .animation(AppAnimation.spring, value: viewModel.streakInfo.currentStreak)

                    VStack(spacing: 0) {
                        Text(viewModel.streakEmoji)
                            .font(.system(size: 22))
                        Text("\(viewModel.streakInfo.currentStreak)")
                            .font(AppFont.mono(18))
                            .foregroundStyle(.white)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("\(viewModel.streakInfo.currentStreak)-day streak")
                        .font(AppFont.title(18))
                        .foregroundStyle(.white)
                    Text("Best: \(viewModel.streakInfo.longestStreak) days")
                        .font(AppFont.caption())
                        .foregroundStyle(.white.opacity(0.6))

                    if viewModel.streakInfo.freezeAvailable {
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            Task { await viewModel.freezeStreak() }
                        }) {
                            Label("Freeze streak", systemImage: "snowflake")
                                .font(AppFont.caption(12))
                                .foregroundStyle(.vitaTeal)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Capsule().fill(Color.vitaTeal.opacity(0.15)))
                                .overlay(Capsule().stroke(Color.vitaTeal.opacity(0.3), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }

                Spacer()

                Image(systemName: "flame.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(AppGradient.streak)
                    .opacity(viewModel.streakInfo.currentStreak > 0 ? 1 : 0.25)
            }
        }
    }

    // MARK: - Wellness Score Card

    private var wellnessScoreCard: some View {
        GlassCard {
            VStack(spacing: AppSpacing.md) {
                HStack {
                    Text("Wellness Score")
                        .font(AppFont.title(17))
                        .foregroundStyle(.white)
                    Spacer()
                    Text("\(Int(viewModel.wellnessScore.overall))")
                        .font(AppFont.mono(28))
                        .foregroundStyle(.vitaTeal)
                    Text("/ 100")
                        .font(AppFont.caption())
                        .foregroundStyle(.white.opacity(0.4))
                        .offset(y: 4)
                }

                // Score breakdown bars
                VStack(spacing: 10) {
                    ForEach([
                        ("Nutrition", viewModel.wellnessScore.breakdown.nutrition, Color.vitaTeal),
                        ("Exercise", viewModel.wellnessScore.breakdown.exercise, Color.vitaCoral),
                        ("Sleep", viewModel.wellnessScore.breakdown.sleep, Color.vitaIndigo),
                        ("Mindfulness", viewModel.wellnessScore.breakdown.mindfulness, Color.vitaMint),
                        ("Consistency", viewModel.wellnessScore.breakdown.consistency, Color.vitaGold),
                    ], id: \.0) { label, value, color in
                        ScoreBar(label: label, value: value, color: color)
                    }
                }
            }
        }
    }

    // MARK: - Quick Actions

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Quick Actions")
                .font(AppFont.caption(13))
                .foregroundStyle(.white.opacity(0.55))
                .padding(.leading, 4)

            HStack(spacing: AppSpacing.md) {
                QuickActionPill(title: "Chat Coach", icon: "bubble.left.fill",
                                gradient: AppGradient.primaryButton) {
                    appState.selectedTab = .chat
                }
                QuickActionPill(title: "Analyze Meal", icon: "camera.fill",
                                gradient: AppGradient.wellnessScore) {
                    appState.selectedTab = .video
                }
                QuickActionPill(title: "Log Habit", icon: "checkmark.circle.fill",
                                gradient: AppGradient.streak) {
                    appState.selectedTab = .sessions
                }
                QuickActionPill(title: "Meditate", icon: "leaf.fill",
                                gradient: LinearGradient(
                                    colors: [.vitaMint, .vitaTeal],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                )) {
                    // open mindfulness
                }
            }
        }
    }

    // MARK: - Daily Tip

    private var dailyTipCard: some View {
        GlassCard(cornerRadius: AppRadius.md) {
            HStack(spacing: AppSpacing.md) {
                ZStack {
                    Circle().fill(AppGradient.wellnessScore)
                        .frame(width: 44, height: 44)
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Wellness Tip")
                        .font(AppFont.caption(12))
                        .foregroundStyle(.white.opacity(0.55))
                    Text("Start with 5 minutes of deep breathing to set a calm tone for the day.")
                        .font(AppFont.body(14))
                        .foregroundStyle(.white)
                        .lineLimit(3)
                }
            }
        }
    }

    // MARK: - Wearable Snapshot

    private var wearableCard: some View {
        GlassCard(cornerRadius: AppRadius.md) {
            VStack(spacing: AppSpacing.sm) {
                HStack {
                    Label("Health Metrics", systemImage: "heart.fill")
                        .font(AppFont.title(15))
                        .foregroundStyle(.white)
                    Spacer()
                    Text("From Apple Health")
                        .font(AppFont.caption(11))
                        .foregroundStyle(.white.opacity(0.4))
                }
                Divider().background(.white.opacity(0.1))
                HStack {
                    MetricPill(icon: "figure.walk", value: "8,234", unit: "steps", color: .vitaTeal)
                    Spacer()
                    MetricPill(icon: "heart.fill", value: "68", unit: "BPM", color: .vitaCoral)
                    Spacer()
                    MetricPill(icon: "moon.fill", value: "7.2", unit: "hrs", color: .vitaIndigo)
                }
            }
        }
    }
}

// MARK: - Sub-components

struct ScoreBar: View {
    let label: String
    let value: Double
    let color: Color
    @State private var animatedValue: Double = 0

    var body: some View {
        HStack(spacing: 10) {
            Text(label)
                .font(AppFont.caption(12))
                .foregroundStyle(.white.opacity(0.65))
                .frame(width: 90, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(color.opacity(0.85))
                        .frame(width: geo.size.width * (animatedValue / 100), height: 8)
                        .animation(AppAnimation.spring, value: animatedValue)
                }
            }
            .frame(height: 8)

            Text("\(Int(value))")
                .font(AppFont.mono(12))
                .foregroundStyle(color)
                .frame(width: 28, alignment: .trailing)
        }
        .onAppear { animatedValue = value }
    }
}

struct MetricPill: View {
    let icon: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(color)
            Text(value)
                .font(AppFont.mono(18))
                .foregroundStyle(.white)
            Text(unit)
                .font(AppFont.caption(11))
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ZStack {
        AppGradient.background.ignoresSafeArea()
        HomeView()
            .environmentObject(AppState())
    }
}
