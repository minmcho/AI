import SwiftUI

struct SettingsView: View {
    @AppStorage("defaultLanguage") private var defaultLanguage = "es"
    @AppStorage("autoSaveAnalyses") private var autoSaveAnalyses = true
    @AppStorage("autoDeleteDays") private var autoDeleteDays = 30
    @AppStorage("enableAudioPlayback") private var enableAudioPlayback = true
    @AppStorage("privacyMode") private var privacyMode = true
    @AppStorage("hapticFeedback") private var hapticFeedback = true

    @State private var showingClearDataAlert = false
    @State private var storageUsed = "0 KB"
    @State private var analysesCount = 0

    var body: some View {
        NavigationStack {
            ZStack {
                Color.theme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // App Info Header
                        appInfoHeader

                        // Language Section
                        languageSection

                        // Privacy Section
                        privacySection

                        // Audio Section
                        audioSection

                        // Storage Section
                        storageSection

                        // About Section
                        aboutSection

                        // Disclaimer
                        disclaimer
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .alert("Clear All Data", isPresented: $showingClearDataAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Clear All", role: .destructive) {
                    clearAllData()
                }
            } message: {
                Text("This will permanently delete all saved analyses and reset the app. This action cannot be undone.")
            }
            .onAppear {
                loadStorageStats()
            }
        }
    }

    // MARK: - App Info Header
    private var appInfoHeader: some View {
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
                    .frame(width: 100, height: 100)

                Image(systemName: "cross.case.fill")
                    .font(.system(size: 45, weight: .light))
                    .foregroundStyle(Color.theme.primaryGradient)
            }

            VStack(spacing: 4) {
                Text("Health Rash AI")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color.theme.textPrimary)

                Text("Version 1.0.0")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.theme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.theme.cardBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }

    // MARK: - Language Section
    private var languageSection: some View {
        SettingsSection(title: "🌍 Language", icon: "globe") {
            VStack(spacing: 12) {
                Text("Default Language")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.theme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 12) {
                    LanguageOptionButton(
                        flag: "🇪🇸",
                        name: "Español",
                        code: "es",
                        isSelected: defaultLanguage == "es"
                    ) {
                        defaultLanguage = "es"
                    }

                    LanguageOptionButton(
                        flag: "🇲🇲",
                        name: "မြန်မာ",
                        code: "my",
                        isSelected: defaultLanguage == "my"
                    ) {
                        defaultLanguage = "my"
                    }
                }
            }
        }
    }

    // MARK: - Privacy Section
    private var privacySection: some View {
        SettingsSection(title: "🔒 Privacy & Data", icon: "lock.shield") {
            VStack(spacing: 16) {
                ToggleRow(
                    title: "Privacy Mode",
                    description: "All data processed locally, never sent to servers",
                    isOn: $privacyMode,
                    color: Color.theme.success
                )

                ToggleRow(
                    title: "Auto-Save Analyses",
                    description: "Automatically save analysis results locally",
                    isOn: $autoSaveAnalyses,
                    color: Color.theme.primary
                )

                VStack(alignment: .leading, spacing: 12) {
                    Text("Auto-Delete After")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color.theme.textPrimary)

                    Text("Automatically delete analyses older than \(autoDeleteDays) days")
                        .font(.system(size: 13))
                        .foregroundColor(Color.theme.textSecondary)

                    HStack(spacing: 8) {
                        ForEach([7, 14, 30, 60], id: \.self) { days in
                            Button(action: {
                                withAnimation(.spring(response: 0.3)) {
                                    autoDeleteDays = days
                                }
                            }) {
                                Text("\(days)d")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(autoDeleteDays == days ? .white : Color.theme.textSecondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(autoDeleteDays == days ? Color.theme.primary : Color.theme.background)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(autoDeleteDays == days ? Color.theme.primary : Color.gray.opacity(0.3), lineWidth: 2)
                                    )
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Audio Section
    private var audioSection: some View {
        SettingsSection(title: "🔊 Audio", icon: "speaker.wave.3") {
            VStack(spacing: 16) {
                ToggleRow(
                    title: "Enable Audio Playback",
                    description: "Read analysis results aloud",
                    isOn: $enableAudioPlayback,
                    color: Color.theme.primary
                )

                ToggleRow(
                    title: "Haptic Feedback",
                    description: "Vibration feedback for interactions",
                    isOn: $hapticFeedback,
                    color: Color.theme.accent
                )
            }
        }
    }

    // MARK: - Storage Section
    private var storageSection: some View {
        SettingsSection(title: "💾 Storage", icon: "internaldrive") {
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Saved Analyses")
                            .font(.system(size: 14))
                            .foregroundColor(Color.theme.textSecondary)
                        Text("\(analysesCount)")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Color.theme.textPrimary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.theme.primary.opacity(0.1))
                    )

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Storage Used")
                            .font(.system(size: 14))
                            .foregroundColor(Color.theme.textSecondary)
                        Text(storageUsed)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Color.theme.textPrimary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.theme.success.opacity(0.1))
                    )
                }

                Button(action: {
                    showingClearDataAlert = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "trash.fill")
                        Text("Clear All Data")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.theme.danger)
                    )
                }
            }
        }
    }

    // MARK: - About Section
    private var aboutSection: some View {
        SettingsSection(title: "ℹ️ About", icon: "info.circle") {
            VStack(alignment: .leading, spacing: 16) {
                Text("Open-source AI-powered medical assistance for healthcare workers in underserved communities.")
                    .font(.system(size: 14))
                    .foregroundColor(Color.theme.textSecondary)
                    .lineLimit(nil)

                VStack(alignment: .leading, spacing: 8) {
                    FeatureRow(icon: "checkmark.circle.fill", text: "100% Privacy-Preserving", color: Color.theme.success)
                    FeatureRow(icon: "checkmark.circle.fill", text: "All Processing On-Device", color: Color.theme.success)
                    FeatureRow(icon: "checkmark.circle.fill", text: "Open-Source AI Models", color: Color.theme.primary)
                    FeatureRow(icon: "checkmark.circle.fill", text: "Multilingual Support", color: Color.theme.info)
                }

                Divider()

                VStack(spacing: 12) {
                    LinkRow(icon: "envelope.fill", title: "Contact Support", color: Color.theme.primary)
                    LinkRow(icon: "doc.text.fill", title: "Privacy Policy", color: Color.theme.info)
                    LinkRow(icon: "star.fill", title: "Rate This App", color: Color.theme.accent)
                }
            }
        }
    }

    // MARK: - Disclaimer
    private var disclaimer: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 24))
                .foregroundColor(Color.theme.warning)

            Text("Medical Disclaimer")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color.theme.textPrimary)

            Text("This application is intended as a support tool for healthcare workers and does not replace professional medical judgment. Always follow established medical protocols and guidelines.")
                .font(.system(size: 12))
                .foregroundColor(Color.theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.theme.warning.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.theme.warning.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Helper Methods
    private func loadStorageStats() {
        // Mock data
        storageUsed = "24.5 KB"
        analysesCount = 12
    }

    private func clearAllData() {
        withAnimation {
            analysesCount = 0
            storageUsed = "0 KB"
        }
    }
}

// MARK: - Settings Section
struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color.theme.textPrimary)
            }

            VStack(spacing: 0) {
                content
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.theme.cardBackground)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
            )
        }
    }
}

// MARK: - Language Option Button
struct LanguageOptionButton: View {
    let flag: String
    let name: String
    let code: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(flag)
                    .font(.system(size: 32))

                Text(name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isSelected ? Color.theme.primary : Color.theme.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.theme.primary.opacity(0.1) : Color.theme.background)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.theme.primary : Color.gray.opacity(0.3), lineWidth: 2)
            )
        }
    }
}

// MARK: - Toggle Row
struct ToggleRow: View {
    let title: String
    let description: String
    @Binding var isOn: Bool
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color.theme.textPrimary)

                    Text(description)
                        .font(.system(size: 13))
                        .foregroundColor(Color.theme.textSecondary)
                }

                Spacer()

                Toggle("", isOn: $isOn)
                    .labelsHidden()
                    .tint(color)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Feature Row
struct FeatureRow: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(Color.theme.textPrimary)
        }
    }
}

// MARK: - Link Row
struct LinkRow: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        Button(action: {}) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                    .frame(width: 24)

                Text(title)
                    .font(.system(size: 15))
                    .foregroundColor(Color.theme.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color.theme.textTertiary)
            }
            .padding(.vertical, 4)
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
