import SwiftUI
import AVFoundation

struct CameraView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    @StateObject private var cameraManager = CameraManager()
    @State private var capturedImage: UIImage?
    @State private var navigateToAnalysis = false
    @State private var recordedQuestion: String = ""
    @State private var showFlash = false

    var body: some View {
        ZStack {
            if let image = capturedImage {
                // Preview with voice input
                previewView
            } else {
                // Camera view
                cameraInterfaceView
            }

            // Flash effect
            if showFlash {
                Color.white
                    .ignoresSafeArea()
                    .transition(.opacity)
            }
        }
        .navigationTitle("Capture Photo")
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

    // MARK: - Camera Interface
    private var cameraInterfaceView: some View {
        ZStack {
            // Camera preview
            CameraPreviewView(cameraManager: cameraManager)
                .ignoresSafeArea()

            // Overlay gradient
            LinearGradient(
                colors: [Color.black.opacity(0.4), Color.clear, Color.black.opacity(0.6)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack {
                // Top guidance
                guidanceBox
                    .padding(.top, 20)

                Spacer()

                // Camera controls
                cameraControls
                    .padding(.bottom, 40)
            }
        }
    }

    private var guidanceBox: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "viewfinder")
                    .font(.system(size: 20))
                Text("Position the rash clearly")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)

            Text("Ensure good lighting and focus")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.9))
        }
        .padding()
        .background(
            ZStack {
                BlurView(style: .systemMaterialDark)
                Color.black.opacity(0.6)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
        )
        .padding(.horizontal)
    }

    private var cameraControls: some View {
        HStack(spacing: 40) {
            // Cancel button
            Button(action: { dismiss() }) {
                VStack(spacing: 4) {
                    Image(systemName: "xmark")
                        .font(.system(size: 20, weight: .medium))
                    Text("Cancel")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(.white)
            }

            // Capture button
            Button(action: {
                capturePhoto()
            }) {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 80, height: 80)
                        .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)

                    Circle()
                        .strokeBorder(Color.white, lineWidth: 4)
                        .frame(width: 90, height: 90)

                    Circle()
                        .fill(Color.theme.primary)
                        .frame(width: 70, height: 70)
                }
            }

            // Flash toggle
            Button(action: {
                cameraManager.toggleFlash()
            }) {
                VStack(spacing: 4) {
                    Image(systemName: cameraManager.isFlashOn ? "bolt.fill" : "bolt.slash.fill")
                        .font(.system(size: 20, weight: .medium))
                    Text("Flash")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(.white)
            }
        }
    }

    // MARK: - Preview View
    private var previewView: some View {
        ZStack {
            Color.theme.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Success header
                    successHeader
                        .padding(.top, 20)

                    // Image preview
                    imagePreviewCard

                    // Voice input
                    VoiceInputCard(
                        language: appState.selectedLanguage
                    ) { transcript in
                        recordedQuestion = transcript
                        navigateToAnalysis = true
                    }

                    // Retake button
                    retakeButton
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
    }

    private var successHeader: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.theme.success.opacity(0.2))
                    .frame(width: 80, height: 80)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(Color.theme.success)
            }

            Text("Photo Captured")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(Color.theme.success)

            Text("Now, ask your question about the rash")
                .font(.system(size: 16))
                .foregroundColor(Color.theme.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    private var imagePreviewCard: some View {
        VStack(spacing: 16) {
            if let image = capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
            }

            HStack(spacing: 8) {
                Image(systemName: "photo.fill")
                    .foregroundColor(Color.theme.primary)
                Text("Image saved and ready")
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

    private var retakeButton: some View {
        Button(action: {
            withAnimation {
                capturedImage = nil
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 16, weight: .semibold))
                Text("Retake Photo")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(Color.theme.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.theme.surface)
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
    }

    // MARK: - Helper Methods
    private func capturePhoto() {
        // Flash animation
        withAnimation(.easeInOut(duration: 0.1)) {
            showFlash = true
        }

        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        cameraManager.capturePhoto { image in
            capturedImage = image

            // Hide flash
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    showFlash = false
                }
            }
        }
    }
}

// MARK: - Camera Preview
struct CameraPreviewView: UIViewRepresentable {
    @ObservedObject var cameraManager: CameraManager

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black

        DispatchQueue.main.async {
            cameraManager.setupCamera()
            if let previewLayer = cameraManager.previewLayer {
                previewLayer.frame = UIScreen.main.bounds
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

// MARK: - Blur View
struct BlurView: UIViewRepresentable {
    let style: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

struct CameraView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            CameraView()
                .environmentObject(AppState())
        }
    }
}
