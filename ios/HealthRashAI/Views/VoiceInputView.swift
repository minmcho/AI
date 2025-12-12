import SwiftUI
import AVFoundation

struct VoiceInputView: View {
    @ObservedObject var recorder: VoiceRecorder
    let language: AppState.Language
    let onTranscript: (String) -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Select Language & Speak")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)

            // Language selector
            HStack(spacing: 12) {
                ForEach(AppState.Language.allCases, id: \.self) { lang in
                    Button(action: {
                        // Language is set at app level
                    }) {
                        HStack(spacing: 8) {
                            Text(lang.flag)
                                .font(.system(size: 24))

                            Text(lang.displayName)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(language == lang ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(language == lang ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
                        )
                    }
                }
            }

            // Recording button
            if recorder.isProcessing {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)

                    Text("Processing audio...")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
                .frame(width: 160, height: 160)
            } else {
                Button(action: {
                    if recorder.isRecording {
                        recorder.stopRecording { transcript in
                            onTranscript(transcript)
                        }
                    } else {
                        recorder.startRecording(language: language)
                    }
                }) {
                    VStack(spacing: 12) {
                        Text(recorder.isRecording ? "⏹️" : "🎤")
                            .font(.system(size: 48))

                        Text(recorder.isRecording ? "Tap to Stop" : "Tap to Record")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)

                        if recorder.isRecording {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 12, height: 12)

                                Text("Recording...")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .frame(width: 160, height: 160)
                    .background(recorder.isRecording ? Color.red : Color.blue)
                    .clipShape(Circle())
                    .shadow(color: (recorder.isRecording ? Color.red : Color.blue).opacity(0.3), radius: 8, x: 0, y: 4)
                }
            }

            // Example questions
            VStack(alignment: .leading, spacing: 8) {
                Text("Example Questions:")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)

                if language == .spanish {
                    Text("• \"¿Es esto peligroso?\"")
                    Text("• \"¿Qué debo hacer?\"")
                    Text("• \"¿Necesita tratamiento inmediato?\"")
                } else {
                    Text("• \"ဒါက အန္တရာယ်ရှိပါသလား။\"")
                    Text("• \"ဘာလုပ်သင့်ပါသလဲ။\"")
                    Text("• \"ချက်ခြင်း ကုသမှု လိုအပ်ပါသလား။\"")
                }
            }
            .font(.system(size: 13))
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(UIColor.systemGroupedBackground))
            .cornerRadius(8)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.3), lineWidth: 2)
        )
    }
}
