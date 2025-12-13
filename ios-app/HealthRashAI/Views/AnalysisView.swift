import SwiftUI
import AVFoundation

struct AnalysisView: View {
    let image: UIImage
    let question: String
    let language: AppState.Language

    @Environment(\.dismiss) var dismiss
    @StateObject private var analyzer = AIAnalyzer()
    @State private var isSpeaking = false
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            Color.theme.background
                .ignoresSafeArea()

            if analyzer.isAnalyzing {
                loadingView
            } else if let result = analyzer.result {
                ScrollView {
                    VStack(spacing: 20) {
                        // Severity Badge
                        severityBadge(result.severity)
                            .padding(.top, 20)

                        // Image Preview
                        imagePreviewCard

                        // Question Card
                        questionCard

                        // Medical Analysis
                        medicalAnalysisCard(result)

                        // Care Instructions
                        careInstructionsCard(result)

                        // Medical Attention Warning
                        if result.seekMedicalAttention {
                            medicalAttentionWarning
                        }

                        // Audio Playback Button
                        audioPlaybackButton(result)

                        // Privacy Notice
                        privacyNotice

                        // Action Buttons
                        actionButtons

                        // Disclaimer
                        disclaimer
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
        }
        .navigationTitle("AI Analysis")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            analyzer.analyzeRash(image: image, question: question, language: language)
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }

    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 30) {
            // Animated Analysis Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.theme.primary.opacity(0.2), Color.theme.primaryLight.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)
                    .scaleEffect(isAnimating ? 1.1 : 0.9)

                Image(systemName: "brain.head.profile")
                    .font(.system(size: 60, weight: .light))
                    .foregroundStyle(Color.theme.primaryGradient)
                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
                    .animation(.linear(duration: 3).repeatForever(autoreverses: false), value: isAnimating)
            }

            // Loading Title
            Text("Analyzing...")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(Color.theme.textPrimary)

            // Loading Steps
            VStack(alignment: .leading, spacing: 16) {
                LoadingStep(icon: "magnifyingglass", text: "Analyzing rash image", isActive: true)
                LoadingStep(icon: "cpu", text: "Processing with AI", isActive: true)
                LoadingStep(icon: "doc.text", text: "Generating care instructions", isActive: true)
            }
            .padding(.horizontal, 40)

            // Privacy Note
            HStack(spacing: 8) {
                Image(systemName: "checkmark.shield.fill")
                    .foregroundColor(Color.theme.success)
                Text("All processing is done locally on your device")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.theme.success)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.theme.success.opacity(0.1))
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Severity Badge
    private func severityBadge(_ severity: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: severityIcon(severity))
                .font(.system(size: 16, weight: .semibold))

            Text(severity.uppercased() + " SEVERITY")
                .font(.system(size: 14, weight: .bold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(severityColor(severity))
                .shadow(color: severityColor(severity).opacity(0.4), radius: 8, x: 0, y: 4)
        )
    }

    // MARK: - Image Preview Card
    private var imagePreviewCard: some View {
        VStack(spacing: 12) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 200)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)

            HStack(spacing: 8) {
                Image(systemName: "photo.fill")
                    .foregroundColor(Color.theme.primary)
                Text("Captured Image")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.theme.textSecondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.theme.cardBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }

    // MARK: - Question Card
    private var questionCard: some View {
        ResultCard(
            icon: "❓",
            title: "Your Question",
            content: question,
            accentColor: Color.theme.primary
        )
    }

    // MARK: - Medical Analysis Card
    private func medicalAnalysisCard(_ result: AnalysisResult) -> some View {
        ResultCard(
            icon: "🩺",
            title: "Medical Analysis",
            content: result.response,
            accentColor: Color.theme.info
        )
    }

    // MARK: - Care Instructions Card
    private func careInstructionsCard(_ result: AnalysisResult) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Text("📋")
                    .font(.system(size: 24))
                Text("Care Instructions")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color.theme.textPrimary)
            }

            VStack(spacing: 12) {
                ForEach(Array(result.careInstructions.enumerated()), id: \.offset) { index, instruction in
                    HStack(alignment: .top, spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.theme.primary)
                                .frame(width: 32, height: 32)

                            Text("\(index + 1)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        }

                        Text(instruction)
                            .font(.system(size: 15))
                            .foregroundColor(Color.theme.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer()
                    }
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

    // MARK: - Medical Attention Warning
    private var medicalAttentionWarning: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 28))
                .foregroundColor(Color.theme.danger)

            VStack(alignment: .leading, spacing: 4) {
                Text("Seek Medical Attention")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color.theme.danger)

                Text("This appears to require professional evaluation. Please consult a healthcare provider.")
                    .font(.system(size: 14))
                    .foregroundColor(Color.theme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.theme.danger.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.theme.danger.opacity(0.3), lineWidth: 2)
        )
    }

    // MARK: - Audio Playback Button
    private func audioPlaybackButton(_ result: AnalysisResult) -> some View {
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
            HStack(spacing: 12) {
                Image(systemName: isSpeaking ? "stop.circle.fill" : "speaker.wave.3.fill")
                    .font(.system(size: 24))

                Text(isSpeaking ? "Stop Audio" : "Listen to Response")
                    .font(.system(size: 16, weight: .semibold))

                if isSpeaking {
                    Spacer()

                    HStack(spacing: 4) {
                        ForEach(0..<3) { index in
                            Circle()
                                .fill(Color.white)
                                .frame(width: 6, height: 6)
                                .scaleEffect(isAnimating ? 1.2 : 0.8)
                                .animation(
                                    .easeInOut(duration: 0.6)
                                    .repeatForever()
                                    .delay(Double(index) * 0.2),
                                    value: isAnimating
                                )
                        }
                    }
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        isSpeaking ?
                        LinearGradient(colors: [Color.theme.danger, Color.theme.danger.opacity(0.8)], startPoint: .leading, endPoint: .trailing) :
                        Color.theme.primaryGradient
                    )
                    .shadow(color: (isSpeaking ? Color.theme.danger : Color.theme.primary).opacity(0.3), radius: 8, x: 0, y: 4)
            )
        }
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

                Text("This analysis was processed entirely on your device. No data was sent to external servers.")
                    .font(.system(size: 12))
                    .foregroundColor(Color.theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
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

    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Save Analysis
            Button(action: {
                // Save functionality
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "square.and.arrow.down.fill")
                    Text("Save Analysis")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.theme.successGradient)
                )
            }

            // New Analysis
            Button(action: {
                dismiss()
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.counterclockwise")
                    Text("New Analysis")
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color.theme.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.theme.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.theme.primary, lineWidth: 2)
                        )
                )
            }
        }
    }

    // MARK: - Disclaimer
    private var disclaimer: some View {
        HStack(spacing: 12) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(Color.theme.warning)

            Text("This AI analysis is for informational purposes only and does not replace professional medical advice. Always consult with qualified healthcare providers for proper diagnosis and treatment.")
                .font(.system(size: 12))
                .foregroundColor(Color.theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
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

    // MARK: - Helper Functions
    private func severityColor(_ severity: String) -> Color {
        switch severity {
        case "low": return Color.theme.success
        case "medium": return Color.theme.warning
        case "high": return Color.theme.danger
        default: return Color.gray
        }
    }

    private func severityIcon(_ severity: String) -> String {
        switch severity {
        case "low": return "checkmark.circle.fill"
        case "medium": return "exclamationmark.circle.fill"
        case "high": return "exclamationmark.triangle.fill"
        default: return "circle.fill"
        }
    }
}

// MARK: - Loading Step
struct LoadingStep: View {
    let icon: String
    let text: String
    let isActive: Bool

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.theme.primary.opacity(0.1))
                    .frame(width: 32, height: 32)

                if isActive {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color.theme.primary))
                        .scaleEffect(0.7)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(Color.theme.primary)
                }
            }

            Text(text)
                .font(.system(size: 16))
                .foregroundColor(Color.theme.textPrimary)

            Spacer()
        }
    }
}

// MARK: - Result Card
struct ResultCard: View {
    let icon: String
    let title: String
    let content: String
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text(icon)
                    .font(.system(size: 24))
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color.theme.textPrimary)
            }

            Text(content)
                .font(.system(size: 16))
                .foregroundColor(Color.theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.theme.cardBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(accentColor.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - AI Analyzer
class AIAnalyzer: ObservableObject {
    @Published var isAnalyzing = false
    @Published var result: AnalysisResult?

    func analyzeRash(image: UIImage, question: String, language: AppState.Language) {
        isAnalyzing = true

        // Simulate AI processing
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            self?.result = self?.generateMockResult(language: language)
            self?.isAnalyzing = false
        }
    }

    private func generateMockResult(language: AppState.Language) -> AnalysisResult {
        if language == .spanish {
            return AnalysisResult(
                severity: "low",
                response: "Basado en la imagen, esto parece ser una irritación leve de la piel. No parece ser peligroso en este momento, pero es importante monitorearlo.",
                careInstructions: [
                    "Limpie suavemente el área con agua tibia y jabón neutro",
                    "Aplique una crema hidratante sin fragancia",
                    "Evite rascar o frotar el área afectada",
                    "Mantenga el área limpia y seca",
                    "Observe si hay cambios en las próximas 24-48 horas"
                ],
                seekMedicalAttention: false,
                confidence: 0.85
            )
        } else {
            return AnalysisResult(
                severity: "low",
                response: "ပုံအရ၊ ဒါက အရေပြားယားယံမှု အနည်းငယ်ဖြစ်ပုံရပါတယ်။ ယခုအချိန်မှာ အန္တရာယ်မရှိပုံရပေမယ့် စောင့်ကြည့်ဖို့ အရေးကြီးပါတယ်။",
                careInstructions: [
                    "နွေးသော ရေနှင့် နူးညံ့သော ဆပ်ပြာဖြင့် နူးညံ့စွာ သန့်ရှင်းပါ",
                    "ရနံ့မပါသော အစိုဓာတ်ထိန်းခရင်မ်ကို လိမ်းပါ",
                    "ထိခိုက်သောနေရာကို ကုတ်ခြင်း သို့မဟုတ် ပွတ်တိုက်ခြင်းမှ ရှောင်ကြဉ်ပါ",
                    "ထိုနေရာကို သန့်ရှင်းပြီး ခြောက်သွေ့အောင် ထားပါ",
                    "နောက် ၂၄-၄၈ နာရီအတွင်း ပြောင်းလဲမှုများကို စောင့်ကြည့်ပါ"
                ],
                seekMedicalAttention: false,
                confidence: 0.85
            )
        }
    }
}

// MARK: - Analysis Result Model
struct AnalysisResult {
    let severity: String
    let response: String
    let careInstructions: [String]
    let seekMedicalAttention: Bool
    let confidence: Double
}

// MARK: - Speech Synthesizer
class SpeechSynthesizer {
    static let shared = SpeechSynthesizer()
    private let synthesizer = AVSpeechSynthesizer()
    private var currentCompletion: (() -> Void)?

    private init() {
        synthesizer.delegate = self
    }

    func speak(text: String, language: AppState.Language, completion: @escaping () -> Void) {
        currentCompletion = completion

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language.locale)
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0

        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        currentCompletion?()
        currentCompletion = nil
    }
}

extension SpeechSynthesizer: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        currentCompletion?()
        currentCompletion = nil
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
