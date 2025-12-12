import SwiftUI
import AVFoundation

struct AnalysisView: View {
    let image: UIImage
    let question: String
    let language: AppState.Language

    @Environment(\.dismiss) var dismiss
    @StateObject private var analyzer = AIAnalyzer()
    @State private var isSpeaking = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if analyzer.isAnalyzing {
                    // Loading state
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)

                        Text("Analyzing...")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)

                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("🔍")
                                Text("Analyzing rash image")
                                    .foregroundColor(.secondary)
                            }
                            HStack {
                                Text("🤖")
                                Text("Processing with AI")
                                    .foregroundColor(.secondary)
                            }
                            HStack {
                                Text("📋")
                                Text("Generating care instructions")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .font(.system(size: 16))

                        Text("All processing is done locally on your device")
                            .font(.system(size: 14))
                            .foregroundColor(Color(red: 0.09, green: 0.64, blue: 0.29))
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else if let result = analyzer.result {
                    // Results
                    VStack(spacing: 16) {
                        // Severity badge
                        Text(result.severity.uppercased() + " SEVERITY")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(result.severityColor)
                            .cornerRadius(8)

                        // Question
                        SectionCard(
                            icon: "❓",
                            title: "Your Question",
                            content: question
                        )

                        // Medical Response
                        SectionCard(
                            icon: "🩺",
                            title: "Medical Analysis",
                            content: result.response
                        )

                        // Care Instructions
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("📋")
                                    .font(.system(size: 24))
                                Text("Care Instructions")
                                    .font(.system(size: 18, weight: .semibold))
                            }

                            ForEach(Array(result.careInstructions.enumerated()), id: \.offset) { index, instruction in
                                HStack(alignment: .top, spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.blue)
                                            .frame(width: 28, height: 28)

                                        Text("\(index + 1)")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.white)
                                    }

                                    Text(instruction)
                                        .font(.system(size: 15))
                                        .foregroundColor(.primary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)

                        // Medical attention warning
                        if result.seekMedicalAttention {
                            HStack(spacing: 12) {
                                Text("⚠️")
                                    .font(.system(size: 24))

                                Text("Seek immediate medical attention. This appears to require professional evaluation.")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Color(red: 0.60, green: 0.11, blue: 0.11))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding()
                            .background(Color(red: 1.0, green: 0.95, blue: 0.95))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(red: 1.0, green: 0.79, blue: 0.79), lineWidth: 2)
                            )
                        }

                        // Audio playback
                        Button(action: {
                            if isSpeaking {
                                SpeechSynthesizer.shared.stop()
                                isSpeaking = false
                            } else {
                                let fullText = "\(result.response)\n\n\(result.careInstructions.joined(separator: ". "))"
                                SpeechSynthesizer.shared.speak(text: fullText, language: language) {
                                    isSpeaking = false
                                }
                                isSpeaking = true
                            }
                        }) {
                            HStack {
                                Text(isSpeaking ? "⏸️" : "🔊")
                                    .font(.system(size: 24))

                                Text(isSpeaking ? "Stop Audio" : "Listen to Response")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isSpeaking ? Color.red : Color.blue)
                            .cornerRadius(12)
                        }

                        // Privacy notice
                        HStack(spacing: 12) {
                            Text("🔒")
                                .font(.system(size: 20))

                            Text("This analysis was processed entirely on your device. No data was sent to external servers.")
                                .font(.system(size: 12))
                                .foregroundColor(Color(red: 0.09, green: 0.39, blue: 0.20))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding()
                        .background(Color(red: 0.94, green: 0.99, blue: 0.96))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(red: 0.53, green: 0.94, blue: 0.67), lineWidth: 1)
                        )

                        // New analysis button
                        Button(action: {
                            dismiss()
                        }) {
                            Text("New Analysis")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(red: 0.09, green: 0.64, blue: 0.29))
                                .cornerRadius(12)
                        }

                        // Disclaimer
                        VStack(spacing: 8) {
                            Text("⚕️ This AI analysis is for informational purposes only and does not replace professional medical advice. Always consult with qualified healthcare providers for proper diagnosis and treatment.")
                                .font(.system(size: 12))
                                .foregroundColor(Color(red: 0.47, green: 0.21, blue: 0.06))
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .background(Color(red: 1.0, green: 0.95, blue: 0.78))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(red: 0.99, green: 0.91, blue: 0.54), lineWidth: 1)
                        )
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("AI Analysis")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(UIColor.systemGroupedBackground))
        .onAppear {
            analyzer.analyzeRash(image: image, question: question, language: language)
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
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct AnalysisView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            AnalysisView(
                image: UIImage(systemName: "photo")!,
                question: "¿Es esto peligroso?",
                language: .spanish
            )
        }
    }
}
