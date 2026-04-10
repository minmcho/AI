// ProfileView.swift — VitalPath AI
// User wellness profile, preferences, language, wearable connection,
// privacy controls, and app settings.

import SwiftUI

// MARK: - ViewModel

@MainActor
@Observable
final class ProfileViewModel {
    var profile: WellnessProfile = .empty
    var isLoading = false
    var showEditSheet = false
    var selectedLanguage: AppLanguage = .en
    var dietaryPrefs: [String] = []
    var wellnessGoals: [String] = []
    var isWearableConnected = false
    var error: String?

    private let client = GraphQLClient.shared

    func loadProfile() async {
        isLoading = true
        defer { isLoading = false }
        do {
            struct ProfileData: Decodable { let myProfile: WellnessProfile }
            let data = try await client.execute(query: GQL.myProfile, type: ProfileData.self)
            profile = data.myProfile
            selectedLanguage = AppLanguage(rawValue: profile.preferredLanguage) ?? .en
            dietaryPrefs = profile.dietaryPreferences
            wellnessGoals = profile.wellnessGoals
        } catch {
            self.error = error.localizedDescription
        }
    }

    func saveProfile() async {
        do {
            struct UpdateData: Decodable { let updateProfile: WellnessProfile }
            let variables: [String: Any] = [
                "input": [
                    "preferredLanguage": selectedLanguage.rawValue,
                    "dietaryPreferences": dietaryPrefs,
                    "wellnessGoals": wellnessGoals,
                ]
            ]
            let data = try await client.execute(
                query: GQL.updateProfile,
                variables: variables,
                type: UpdateData.self
            )
            profile = data.updateProfile
            showEditSheet = false
        } catch {
            self.error = error.localizedDescription
        }
    }

    func connectWearable() {
        // In production: HKHealthStore authorization
        withAnimation(AppAnimation.spring) { isWearableConnected.toggle() }
    }
}

// MARK: - View

struct ProfileView: View {
    @State private var viewModel = ProfileViewModel()
    @EnvironmentObject private var appState: AppState
    @State private var appear = false

    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedMeshBackground().ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppSpacing.lg) {
                        Color.clear.frame(height: 60)

                        // ── Profile header
                        profileHeader
                            .opacity(appear ? 1 : 0)
                            .offset(y: appear ? 0 : -20)

                        // ── Stats row
                        statsRow

                        // ── Language
                        languageSection

                        // ── Preferences
                        preferencesSection

                        // ── Wearable
                        wearableSection

                        // ── Privacy & Safety
                        privacySection

                        // ── Sign out
                        PrimaryGlassButton(
                            title: "Sign Out",
                            icon: "rectangle.portrait.and.arrow.right",
                            gradient: LinearGradient(
                                colors: [Color.white.opacity(0.08), Color.white.opacity(0.04)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        ) {
                            appState.signOut()
                        }

                        Text("VitalPath AI v1.0.0\nWellness, Not Medicine.")
                            .font(AppFont.caption(11))
                            .foregroundStyle(.white.opacity(0.25))
                            .multilineTextAlignment(.center)

                        Color.clear.frame(height: AppSpacing.xxl)
                    }
                    .padding(.horizontal, AppSpacing.md)
                }
            }
            .navigationBarHidden(true)
            .task { await viewModel.loadProfile() }
            .onAppear { withAnimation(AppAnimation.entrance) { appear = true } }
            .sheet(isPresented: $viewModel.showEditSheet) { editProfileSheet }
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        GlassCard(cornerRadius: AppRadius.lg) {
            VStack(spacing: AppSpacing.md) {
                HStack {
                    Spacer()
                    Button("Edit") { viewModel.showEditSheet = true }
                        .font(AppFont.body(14))
                        .foregroundStyle(.vitaTeal)
                }

                // Avatar
                ZStack {
                    Circle()
                        .fill(AppGradient.primaryButton)
                        .frame(width: 90, height: 90)
                        .shadow(color: .vitaPurple.opacity(0.4), radius: 20, x: 0, y: 8)
                    Text(String(viewModel.profile.displayName?.prefix(1) ?? "V"))
                        .font(AppFont.display(38))
                        .foregroundStyle(.white)
                }

                VStack(spacing: 4) {
                    Text(viewModel.profile.displayName ?? "Wellness Seeker")
                        .font(AppFont.title(20))
                        .foregroundStyle(.white)
                    Text("Member since \(viewModel.profile.createdAt.formatted(.dateTime.month().year()))")
                        .font(AppFont.caption(12))
                        .foregroundStyle(.white.opacity(0.5))
                }

                // Wellness score badge
                HStack(spacing: 6) {
                    Image(systemName: "leaf.fill").foregroundStyle(.vitaTeal)
                    Text("Wellness Score: \(Int(viewModel.profile.wellnessScore))")
                        .font(AppFont.body(14)).fontWeight(.semibold)
                        .foregroundStyle(.vitaTeal)
                }
                .padding(.horizontal, 16).padding(.vertical, 8)
                .background(Capsule().fill(Color.vitaTeal.opacity(0.12)))
                .overlay(Capsule().stroke(Color.vitaTeal.opacity(0.25), lineWidth: 1))
            }
        }
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: AppSpacing.sm) {
            StatCard(icon: "flame.fill", value: "\(viewModel.profile.currentStreak)", label: "Day Streak", color: .vitaGold)
            StatCard(icon: "chart.bar.fill", value: "\(viewModel.profile.totalSessions)", label: "Sessions", color: .vitaIndigo)
            StatCard(icon: "trophy.fill", value: "\(viewModel.profile.longestStreak)", label: "Best Streak", color: .vitaCoral)
        }
    }

    // MARK: - Language

    private var languageSection: some View {
        GlassCard(cornerRadius: AppRadius.md) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Label("Language", systemImage: "globe")
                    .font(AppFont.title(15))
                    .foregroundStyle(.white)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(AppLanguage.allCases, id: \.rawValue) { lang in
                            Button(action: {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                viewModel.selectedLanguage = lang
                            }) {
                                VStack(spacing: 4) {
                                    Text(lang.flag).font(.system(size: 28))
                                    Text(lang.displayName)
                                        .font(AppFont.caption(11))
                                        .foregroundStyle(viewModel.selectedLanguage == lang ? .vitaTeal : .white.opacity(0.6))
                                }
                                .padding(.horizontal, 14).padding(.vertical, 10)
                                .background {
                                    RoundedRectangle(cornerRadius: AppRadius.sm)
                                        .fill(viewModel.selectedLanguage == lang ? Color.vitaTeal.opacity(0.15) : Color.white.opacity(0.05))
                                        .overlay {
                                            RoundedRectangle(cornerRadius: AppRadius.sm)
                                                .stroke(viewModel.selectedLanguage == lang ? Color.vitaTeal.opacity(0.4) : .clear, lineWidth: 1.5)
                                        }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Preferences

    private var preferencesSection: some View {
        GlassCard(cornerRadius: AppRadius.md) {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Label("Wellness Preferences", systemImage: "slider.horizontal.3")
                    .font(AppFont.title(15)).foregroundStyle(.white)

                // Dietary preferences
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Dietary").font(AppFont.caption()).foregroundStyle(.white.opacity(0.5))
                    FlexWrap(items: ["Vegetarian", "Vegan", "Gluten-Free", "Dairy-Free", "Halal", "Kosher"]) { item in
                        let isSelected = viewModel.dietaryPrefs.contains(item)
                        Button(action: {
                            if isSelected { viewModel.dietaryPrefs.removeAll { $0 == item } }
                            else { viewModel.dietaryPrefs.append(item) }
                        }) {
                            Text(item)
                                .font(AppFont.caption(12))
                                .foregroundStyle(isSelected ? .black : .white.opacity(0.7))
                                .padding(.horizontal, 12).padding(.vertical, 6)
                                .background(Capsule().fill(isSelected ? Color.vitaTeal : Color.white.opacity(0.08)))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Wearable

    private var wearableSection: some View {
        GlassCard(cornerRadius: AppRadius.md) {
            HStack(spacing: AppSpacing.md) {
                ZStack {
                    Circle().fill(viewModel.isWearableConnected ? Color.vitaTeal.opacity(0.2) : Color.white.opacity(0.08))
                        .frame(width: 52, height: 52)
                    Image(systemName: "applewatch")
                        .font(.system(size: 24))
                        .foregroundStyle(viewModel.isWearableConnected ? .vitaTeal : .white.opacity(0.4))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Apple Health")
                        .font(AppFont.title(15)).foregroundStyle(.white)
                    Text(viewModel.isWearableConnected ? "Connected — steps, HR, sleep syncing" : "Connect to sync your health metrics")
                        .font(AppFont.caption(12))
                        .foregroundStyle(viewModel.isWearableConnected ? .vitaTeal : .white.opacity(0.5))
                }
                Spacer()
                Toggle("", isOn: Binding(get: { viewModel.isWearableConnected }, set: { _ in viewModel.connectWearable() }))
                    .tint(.vitaTeal)
            }
        }
    }

    // MARK: - Privacy

    private var privacySection: some View {
        GlassCard(cornerRadius: AppRadius.md) {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Label("Privacy & Safety", systemImage: "lock.shield.fill")
                    .font(AppFont.title(15)).foregroundStyle(.white)

                Divider().background(.white.opacity(0.08))

                VStack(spacing: AppSpacing.sm) {
                    PrivacyRow(icon: "eye.slash.fill", color: .vitaIndigo,
                               title: "AI Data Privacy",
                               subtitle: "Your messages are anonymized before processing. Crisis inputs are never stored as plain text.")

                    PrivacyRow(icon: "cross.circle.fill", color: .wellnessCrisis,
                               title: "Not Medical Advice",
                               subtitle: "VitalPath provides wellness guidance only. Always consult a qualified healthcare professional for medical concerns.")

                    PrivacyRow(icon: "trash.fill", color: .vitaCoral,
                               title: "Delete My Data",
                               subtitle: "Request full data deletion from our privacy portal.")
                }
            }
        }
    }

    // MARK: - Edit profile sheet

    private var editProfileSheet: some View {
        NavigationStack {
            ZStack {
                AppGradient.background.ignoresSafeArea()
                VStack(spacing: AppSpacing.lg) {
                    Text("Edit Profile").font(AppFont.title(22)).foregroundStyle(.white)
                    PrimaryGlassButton(title: "Save Changes", icon: "checkmark") {
                        Task { await viewModel.saveProfile() }
                    }
                }
                .padding(AppSpacing.lg)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { viewModel.showEditSheet = false }.foregroundStyle(.vitaTeal)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .preferredColorScheme(.dark)
    }
}

// MARK: - Sub-components

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        GlassCard(cornerRadius: AppRadius.md, padding: EdgeInsets(top: 16, leading: 12, bottom: 16, trailing: 12)) {
            VStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 22)).foregroundStyle(color)
                Text(value).font(AppFont.mono(22)).foregroundStyle(.white)
                Text(label).font(AppFont.caption(11)).foregroundStyle(.white.opacity(0.5)).lineLimit(1)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

struct PrivacyRow: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon).font(.system(size: 18)).foregroundStyle(color)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(AppFont.body(14)).fontWeight(.semibold).foregroundStyle(.white)
                Text(subtitle).font(AppFont.caption(12)).foregroundStyle(.white.opacity(0.55)).lineSpacing(2)
            }
        }
    }
}

// MARK: - Flex Wrap (simple)

struct FlexWrap<Item: Hashable, Content: View>: View {
    let items: [Item]
    let content: (Item) -> Content

    var body: some View {
        // Simple horizontal scroll for now — replace with LazyVGrid for true wrap
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(items, id: \.self) { item in content(item) }
            }
        }
    }
}

// MARK: - Color helper for GoalCategory

extension Color {
    init(_ named: String) {
        switch named {
        case "vitaTeal":      self = .vitaTeal
        case "vitaCoral":     self = .vitaCoral
        case "vitaIndigo":    self = .vitaIndigo
        case "vitaMint":      self = .vitaMint
        case "vitaLavender":  self = .vitaLavender
        case "vitaGold":      self = .vitaGold
        default:              self = .white
        }
    }
}

#Preview {
    ProfileView().environmentObject(AppState())
}
