import SwiftUI

struct SettingsView: View {
    @AppStorage("defaultLanguage") private var defaultLanguage = "es"
    @AppStorage("autoSaveAnalyses") private var autoSaveAnalyses = true
    @AppStorage("autoDeleteDays") private var autoDeleteDays = 30
    @AppStorage("enableAudioPlayback") private var enableAudioPlayback = true
    @AppStorage("privacyMode") private var privacyMode = true

    @State private var showingClearDataAlert = false
    @State private var storageStats = StorageStats(analysesCount: 0, storageUsed: "0 KB")

    var body: some View {
        List {
            // Language Section
            Section {
                Text("🌍 Language Preferences")
                    .font(.system(size: 18, weight: .semibold))
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())

                VStack(alignment: .leading, spacing: 12) {
                    Text("Default Language")
                        .font(.system(size: 16, weight: .semibold))

                    HStack(spacing: 12) {
                        LanguageOptionButton(
                            language: .spanish,
                            isSelected: defaultLanguage == "es"
                        ) {
                            defaultLanguage = "es"
                        }

                        LanguageOptionButton(
                            language: .burmese,
                            isSelected: defaultLanguage == "my"
                        ) {
                            defaultLanguage = "my"
                        }
                    }
                }
            }

            // Privacy Section
            Section {
                Text("🔒 Privacy & Data")
                    .font(.system(size: 18, weight: .semibold))
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())

                Toggle(isOn: $privacyMode) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Privacy Mode")
                            .font(.system(size: 16, weight: .semibold))
                        Text("All data processed locally, never sent to servers")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }
                .tint(.green)

                Toggle(isOn: $autoSaveAnalyses) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Auto-Save Analyses")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Automatically save analysis results locally")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }
                .tint(.blue)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Auto-Delete After (Days)")
                        .font(.system(size: 16, weight: .semibold))

                    Text("Automatically delete analyses older than \(autoDeleteDays) days")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)

                    HStack(spacing: 8) {
                        ForEach([7, 14, 30, 60], id: \.self) { days in
                            Button(action: {
                                autoDeleteDays = days
                            }) {
                                Text("\(days)d")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(autoDeleteDays == days ? .blue : .secondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(autoDeleteDays == days ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(autoDeleteDays == days ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
                                    )
                            }
                        }
                    }
                }
            }

            // Audio Section
            Section {
                Text("🔊 Audio")
                    .font(.system(size: 18, weight: .semibold))
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())

                Toggle(isOn: $enableAudioPlayback) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Enable Audio Playback")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Read analysis results aloud")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }
                .tint(.blue)
            }

            // Storage Section
            Section {
                Text("💾 Storage")
                    .font(.system(size: 18, weight: .semibold))
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())

                HStack {
                    Text("Saved Analyses")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(storageStats.analysesCount)")
                        .fontWeight(.semibold)
                }

                HStack {
                    Text("Storage Used")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(storageStats.storageUsed)
                        .fontWeight(.semibold)
                }

                Button(role: .destructive, action: {
                    showingClearDataAlert = true
                }) {
                    HStack {
                        Text("🗑️")
                        Text("Clear All Data")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.red)
                }
            }

            // About Section
            Section {
                Text("ℹ️ About")
                    .font(.system(size: 18, weight: .semibold))
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())

                VStack(alignment: .leading, spacing: 12) {
                    Text("Health Rash AI v1.0.0")
                        .font(.system(size: 18, weight: .bold))

                    Text("Open-source AI-powered medical assistance for healthcare workers in underserved communities.")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(alignment: .leading, spacing: 6) {
                        FeatureRow(text: "100% Privacy-Preserving")
                        FeatureRow(text: "All Processing On-Device")
                        FeatureRow(text: "Open-Source AI Models")
                        FeatureRow(text: "Multilingual Support")
                    }
                }
            }

            // Disclaimer Section
            Section {
                Text("This application is intended as a support tool for healthcare workers and does not replace professional medical judgment. Always follow established medical protocols and guidelines.")
                    .font(.system(size: 12))
                    .foregroundColor(Color(red: 0.47, green: 0.21, blue: 0.06))
                    .padding()
                    .background(Color(red: 1.0, green: 0.95, blue: 0.78))
                    .cornerRadius(8)
            }
            .listRowBackground(Color.clear)
        }
        .navigationTitle("Settings")
        .alert("Clear All Data", isPresented: $showingClearDataAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear All", role: .destructive) {
                StorageService.shared.clearAllData()
                loadStorageStats()
            }
        } message: {
            Text("This will permanently delete all saved analyses and reset the app. This action cannot be undone.")
        }
        .onAppear {
            loadStorageStats()
        }
    }

    private func loadStorageStats() {
        storageStats = StorageService.shared.getStorageStats()
    }
}

// MARK: - Language Option Button
struct LanguageOptionButton: View {
    let language: AppState.Language
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack {
                Text(language.flag)
                    .font(.system(size: 32))

                Text(language.displayName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
            )
        }
    }
}

// MARK: - Feature Row
struct FeatureRow: View {
    let text: String

    var body: some View {
        HStack {
            Text("✓")
                .foregroundColor(.green)
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.green)
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SettingsView()
        }
    }
}
