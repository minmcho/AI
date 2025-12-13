import SwiftUI
import AVFoundation

struct VoiceInputCard: View {
    let language: AppState.Language
    let onTranscript: (String) -> Void

    @StateObject private var recorder = VoiceRecorder()
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Image(systemName: "waveform")
                    .foregroundColor(Color.theme.primary)
                Text("Voice Input")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color.theme.textPrimary)
                Spacer()
            }

            // Language indicator
            languageIndicator

            // Recording button
            recordingButton

            // Status indicator
            if recorder.isRecording {
                recordingIndicator
            } else if recorder.isProcessing {
                processingIndicator
            }

            // Example questions
            exampleQuestions
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.theme.cardBackground)
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [Color.theme.primary.opacity(0.3), Color.theme.primaryLight.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }

    private var languageIndicator: some View {
        HStack(spacing: 12) {
            Text(language.flag)
                .font(.system(size: 32))

            VStack(alignment: .leading, spacing: 4) {
                Text(language.displayName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.theme.textPrimary)

                Text("Ready to record")
                    .font(.system(size: 13))
                    .foregroundColor(Color.theme.textSecondary)
            }

            Spacer()

            Image(systemName: "mic.fill")
                .font(.system(size: 20))
                .foregroundColor(Color.theme.primary.opacity(0.6))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.theme.primary.opacity(0.05))
        )
    }

    private var recordingButton: some View {
        Button(action: {
            if recorder.isRecording {
                recorder.stopRecording { transcript in
                    onTranscript(transcript)
                }
            } else {
                recorder.startRecording(language: language)
            }
        }) {
            ZStack {
                // Outer circle with pulse
                Circle()
                    .fill(
                        recorder.isRecording ?
                        Color.red.opacity(0.2) :
                        Color.theme.primary.opacity(0.2)
                    )
                    .frame(width: 180, height: 180)
                    .scaleEffect(recorder.isRecording && isAnimating ? 1.1 : 1.0)

                // Main circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: recorder.isRecording ?
                            [Color.red, Color.red.opacity(0.8)] :
                            [Color.theme.primary, Color.theme.primaryLight],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)
                    .shadow(color: (recorder.isRecording ? Color.red : Color.theme.primary).opacity(0.4), radius: 12, x: 0, y: 6)

                VStack(spacing: 8) {
                    Image(systemName: recorder.isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 40, weight: .medium))
                        .foregroundColor(.white)

                    Text(recorder.isRecording ? "Stop" : "Record")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
        }
        .disabled(recorder.isProcessing)
    }

    private var recordingIndicator: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.red)
                .frame(width: 12, height: 12)
                .scaleEffect(isAnimating ? 1.2 : 0.8)

            Text("Recording...")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.red)
        }
    }

    private var processingIndicator: some View {
        HStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color.theme.primary))

            Text("Processing audio...")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.theme.primary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.theme.primary.opacity(0.1))
        )
    }

    private var exampleQuestions: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Color.theme.accent)
                Text("Example Questions")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.theme.textPrimary)
            }

            VStack(alignment: .leading, spacing: 8) {
                if language == .spanish {
                    ExampleQuestionRow(text: "¿Es esto peligroso?")
                    ExampleQuestionRow(text: "¿Qué debo hacer?")
                    ExampleQuestionRow(text: "¿Necesita tratamiento inmediato?")
                } else {
                    ExampleQuestionRow(text: "ဒါက အန္တရာယ်ရှိပါသလား။")
                    ExampleQuestionRow(text: "ဘာလုပ်သင့်ပါသလဲ။")
                    ExampleQuestionRow(text: "ချက်ခြင်း ကုသမှု လိုအပ်ပါသလား။")
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.theme.background)
        )
    }
}

struct ExampleQuestionRow: View {
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "quote.bubble.fill")
                .font(.system(size: 12))
                .foregroundColor(Color.theme.primary.opacity(0.6))

            Text(text)
                .font(.system(size: 13))
                .foregroundColor(Color.theme.textSecondary)
        }
    }
}
