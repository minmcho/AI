import SwiftUI
import AVFoundation

struct CameraView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var voiceRecorder = VoiceRecorder()
    @State private var capturedImage: UIImage?
    @State private var navigateToAnalysis = false
    @State private var recordedQuestion: String = ""

    var body: some View {
        ZStack {
            if let image = capturedImage {
                // Preview with voice input
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Text("✓ Photo Captured")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Color(red: 0.09, green: 0.64, blue: 0.29))

                        Text("Now, ask your question about the rash")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)

                    // Image preview
                    VStack {
                        Text("🖼️")
                            .font(.system(size: 64))

                        Text("Image saved")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(40)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                    )
                    .padding(.horizontal)

                    // Voice Input
                    VoiceInputView(
                        recorder: voiceRecorder,
                        language: appState.selectedLanguage
                    ) { transcript in
                        recordedQuestion = transcript
                        navigateToAnalysis = true
                    }
                    .padding(.horizontal)

                    // Retake button
                    Button(action: {
                        capturedImage = nil
                    }) {
                        Text("↻ Retake Photo")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)

                    Spacer()
                }
                .background(Color(UIColor.systemGroupedBackground))
            } else {
                // Camera preview
                CameraPreviewView(cameraManager: cameraManager)
                    .ignoresSafeArea()

                VStack {
                    // Guidance
                    VStack(spacing: 8) {
                        Text("📸 Position the rash clearly within the frame")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)

                        Text("Ensure good lighting and focus")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(12)
                    .padding()

                    Spacer()

                    // Capture button
                    Button(action: {
                        cameraManager.capturePhoto { image in
                            capturedImage = image
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 80, height: 80)

                            Circle()
                                .fill(Color.blue)
                                .frame(width: 64, height: 64)
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle("Capture Rash Photo")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToAnalysis) {
            if let image = capturedImage {
                AnalysisView(
                    image: image,
                    question: recordedQuestion,
                    language: appState.selectedLanguage
                )
            }
        }
        .onAppear {
            cameraManager.checkPermissions()
        }
    }
}

// MARK: - Camera Preview
struct CameraPreviewView: UIViewRepresentable {
    @ObservedObject var cameraManager: CameraManager

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)

        DispatchQueue.main.async {
            cameraManager.setupCamera()
            if let previewLayer = cameraManager.previewLayer {
                previewLayer.frame = view.bounds
                view.layer.addSublayer(previewLayer)
            }
        }

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = cameraManager.previewLayer {
            DispatchQueue.main.async {
                previewLayer.frame = uiView.bounds
            }
        }
    }
}

struct CameraView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            CameraView()
                .environmentObject(AppState())
        }
    }
}
