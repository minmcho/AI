import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var navigateToCamera = false
    @State private var showLanguageSheet = false
    @State private var isAnimating = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                Color.theme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Hero Section
                        heroSection
                            .padding(.top, 20)

                        // Language Selector
                        languageSection

                        // Quick Stats
                        statsSection

                        // How It Works
                        howItWorksSection

                        // Start Button
                        startButton

                        // Privacy Notice
                        privacyNotice

                        // Features Grid
                        featuresGrid
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Image(systemName: "cross.case.fill")
                            .foregroundColor(.white)
                        Text("Health Rash AI")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }
            }
            .navigationDestination(isPresented: $navigateToCamera) {
                CameraView()
            }
            .sheet(isPresented: $showLanguageSheet) {
                LanguageSelectionSheet(selectedLanguage: $appState.selectedLanguage)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isAnimating = true
            }
        }
    }

    // MARK: - Hero Section
    private var heroSection: some View {
        VStack(spacing: 16) {
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
                    .scaleEffect(isAnimating ? 1.0 : 0.8)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)

                Image(systemName: "cross.case.fill")
                    .font(.system(size: 50, weight: .light))
                    .foregroundStyle(Color.theme.primaryGradient)
                    .scaleEffect(isAnimating ? 1.0 : 0.9)
            }

            Text("Health Rash AI")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundColor(Color.theme.textPrimary)

            Text("AI-Powered Skin Analysis for Healthcare Workers")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color.theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.vertical, 20)
    }

    // MARK: - Language Section
    private var languageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "globe")
                    .foregroundColor(Color.theme.primary)
                Text("Selected Language")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color.theme.textPrimary)
                Spacer()
                Button(action: { showLanguageSheet = true }) {
                    Text("Change")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.theme.primary)
                }
            }

            // Current language card
            HStack(spacing: 16) {
                Text(appState.selectedLanguage.flag)
                    .font(.system(size: 40))

                VStack(alignment: .leading, spacing: 4) {
                    Text(appState.selectedLanguage.displayName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color.theme.textPrimary)

                    Text(appState.selectedLanguage.englishName)
                        .font(.system(size: 14))
                        .foregroundColor(Color.theme.textSecondary)
                }

                Spacer()

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Color.theme.success)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.theme.cardBackground)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.theme.primary.opacity(0.2), lineWidth: 2)
            )
        }
    }

    // MARK: - Stats Section
    private var statsSection: some View {
        HStack(spacing: 12) {
            StatCard(
                icon: "brain.head.profile",
                title: "AI Powered",
                subtitle: "On-Device",
                color: Color.theme.primary
            )

            StatCard(
                icon: "lock.shield.fill",
                title: "100% Private",
                subtitle: "Local Only",
                color: Color.theme.success
            )

            StatCard(
                icon: "bolt.fill",
                title: "Fast Results",
                subtitle: "< 10 sec",
                color: Color.theme.accent
            )
        }
    }

    // MARK: - How It Works
    private var howItWorksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "list.number")
                    .foregroundColor(Color.theme.primary)
                Text("How It Works")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color.theme.textPrimary)
            }

            VStack(spacing: 12) {
                StepCard(
                    number: 1,
                    icon: "camera.fill",
                    title: "Capture Photo",
                    description: "Take a clear photo of the skin rash",
                    color: Color.theme.primary
                )

                StepCard(
                    number: 2,
                    icon: "mic.fill",
                    title: "Ask Question",
                    description: "Speak your question in your language",
                    color: Color.theme.info
                )

                StepCard(
                    number: 3,
                    icon: "sparkles",
                    title: "Get Analysis",
                    description: "Receive AI-powered care instructions",
                    color: Color.theme.success
                )
            }
        }
    }

    // MARK: - Start Button
    private var startButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                navigateToCamera = true
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 20, weight: .semibold))

                Text("Start New Analysis")
                    .font(.system(size: 18, weight: .bold))

                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.theme.primaryGradient)
                    .shadow(color: Color.theme.primary.opacity(0.4), radius: 12, x: 0, y: 6)
            )
        }
        .scaleEffect(isAnimating ? 1.0 : 0.95)
        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)
    }

    // MARK: - Privacy Notice
    private var privacyNotice: some View {
        HStack(spacing: 12) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 24))
                .foregroundColor(Color.theme.success)

            VStack(alignment: .leading, spacing: 4) {
                Text("Complete Privacy")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.theme.success)

                Text("All processing happens on your device. Photos and voice recordings are never uploaded to external servers.")
                    .font(.system(size: 12))
                    .foregroundColor(Color.theme.textSecondary)
                    .lineLimit(3)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.theme.success.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.theme.success.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Features Grid
    private var featuresGrid: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(Color.theme.accent)
                Text("Key Features")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color.theme.textPrimary)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                FeatureCard(icon: "waveform", title: "Voice Input", color: Color.theme.primary)
                FeatureCard(icon: "doc.text.fill", title: "Care Instructions", color: Color.theme.success)
                FeatureCard(icon: "speaker.wave.3.fill", title: "Audio Playback", color: Color.theme.info)
                FeatureCard(icon: "chart.bar.fill", title: "Severity Analysis", color: Color.theme.accent)
            }
        }
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)

            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color.theme.textPrimary)
                .multilineTextAlignment(.center)

            Text(subtitle)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color.theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.theme.cardBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

struct StepCard: View {
    let number: Int
    let icon: String
    let title: String
    let description: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 50, height: 50)

                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.theme.textPrimary)

                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(Color.theme.textSecondary)
            }

            Spacer()

            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 28, height: 28)

                Text("\(number)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.theme.cardBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

struct FeatureCard: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(color)

            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color.theme.textPrimary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
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

// MARK: - Language Selection Sheet
struct LanguageSelectionSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedLanguage: AppState.Language

    var body: some View {
        NavigationStack {
            List {
                ForEach(AppState.Language.allCases) { language in
                    Button(action: {
                        withAnimation {
                            selectedLanguage = language
                        }
                        dismiss()
                    }) {
                        HStack(spacing: 16) {
                            Text(language.flag)
                                .font(.system(size: 40))

                            VStack(alignment: .leading, spacing: 4) {
                                Text(language.displayName)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(Color.theme.textPrimary)

                                Text(language.englishName)
                                    .font(.system(size: 14))
                                    .foregroundColor(Color.theme.textSecondary)
                            }

                            Spacer()

                            if selectedLanguage == language {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(Color.theme.primary)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("Select Language")
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
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(AppState())
            .environmentObject(ThemeManager())
    }
}
