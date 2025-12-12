import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var navigateToCamera = false
    @State private var navigateToSettings = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Text("🏥")
                        .font(.system(size: 64))

                    Text("Health Rash AI")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.primary)

                    Text("AI-powered skin rash analysis for healthcare workers")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 20)

                // Language Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Select Language")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.primary)

                    HStack(spacing: 12) {
                        ForEach(AppState.Language.allCases, id: \.self) { language in
                            LanguageButton(
                                language: language,
                                isSelected: appState.selectedLanguage == language
                            ) {
                                appState.selectedLanguage = language
                            }
                        }
                    }
                }
                .padding(.horizontal)

                // How it works
                VStack(alignment: .leading, spacing: 12) {
                    Text("How It Works")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.primary)

                    VStack(spacing: 12) {
                        StepCard(
                            number: "1",
                            icon: "📸",
                            title: "Take Photo",
                            description: "Capture a clear photo of the skin rash"
                        )

                        StepCard(
                            number: "2",
                            icon: "🎤",
                            title: "Ask Question",
                            description: "Speak your question in your language"
                        )

                        StepCard(
                            number: "3",
                            icon: "🤖",
                            title: "AI Analysis",
                            description: "Get evidence-based analysis and care instructions"
                        )
                    }
                }
                .padding(.horizontal)

                // Start Button
                Button(action: {
                    navigateToCamera = true
                }) {
                    Text("Start New Analysis")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                        .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal)

                // Privacy Notice
                HStack(spacing: 12) {
                    Text("🔒")
                        .font(.system(size: 24))

                    Text("All data is processed locally on your device. Photos and voice recordings are never uploaded to external servers, ensuring complete privacy.")
                        .font(.system(size: 12))
                        .foregroundColor(Color(red: 0.09, green: 0.39, blue: 0.20))
                        .lineLimit(nil)
                }
                .padding()
                .background(Color(red: 0.94, green: 0.99, blue: 0.96))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(red: 0.53, green: 0.94, blue: 0.67), lineWidth: 1)
                )
                .padding(.horizontal)

                // Settings Link
                Button(action: {
                    navigateToSettings = true
                }) {
                    Text("⚙️ Settings")
                        .font(.system(size: 16))
                        .foregroundColor(.blue)
                }
                .padding(.bottom, 20)
            }
        }
        .navigationTitle("Health Rash AI")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToCamera) {
            CameraView()
        }
        .navigationDestination(isPresented: $navigateToSettings) {
            SettingsView()
        }
    }
}

// MARK: - Language Button
struct LanguageButton: View {
    let language: AppState.Language
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(language.flag)
                    .font(.system(size: 40))

                Text(language.displayName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)

                Text(language.rawValue == "es" ? "Spanish" : "Burmese")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
            )
        }
    }
}

// MARK: - Step Card
struct StepCard: View {
    let number: String
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 15) {
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 32, height: 32)

                Text(number)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }

            Text(icon)
                .font(.system(size: 32))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)

                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            HomeView()
                .environmentObject(AppState())
        }
    }
}
