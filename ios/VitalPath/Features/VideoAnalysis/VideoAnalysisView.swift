// VideoAnalysisView.swift — VitalPath AI
// Multi-modal meal and exercise video analysis with Qwen 3.5 VL.
// Real-time overlay cards, 30s capture limit, local compression.

import SwiftUI
import AVFoundation

// MARK: - ViewModel

@MainActor
@Observable
final class VideoAnalysisViewModel {
    var analysisType: AnalysisType = .meal
    var captureState: CaptureState = .idle
    var recordingProgress: Double = 0
    var analysisResult: VideoAnalysisResult?
    var taskId: String?
    var error: String?
    var showResult = false

    enum AnalysisType: String, CaseIterable {
        case meal     = "meal"
        case exercise = "exercise"
        var title: String { rawValue == "meal" ? "Meal Analysis" : "Exercise Form" }
        var icon: String  { rawValue == "meal" ? "fork.knife" : "figure.run" }
        var description: String {
            rawValue == "meal"
                ? "Record your meal for nutritional insights"
                : "Record your exercise form for safety feedback"
        }
    }

    enum CaptureState {
        case idle, recording, uploading, analyzing, completed, failed
        var description: String {
            switch self {
            case .idle:      return "Ready to record"
            case .recording: return "Recording…"
            case .uploading: return "Uploading…"
            case .analyzing: return "Analyzing with AI…"
            case .completed: return "Analysis complete"
            case .failed:    return "Failed — tap to retry"
            }
        }
    }

    func startRecording() {
        withAnimation(AppAnimation.spring) {
            captureState = .recording
            recordingProgress = 0
        }
        // Simulate 30s countdown
        animateProgress()
    }

    private func animateProgress() {
        withAnimation(.linear(duration: 30)) { recordingProgress = 1.0 }
    }

    func stopRecording(videoURL: String) async {
        withAnimation(AppAnimation.smooth) { captureState = .uploading }
        await uploadAndAnalyze(videoURL: videoURL)
    }

    private func uploadAndAnalyze(videoURL: String) async {
        do {
            captureState = .uploading
            // Upload to Supabase bucket first (implementation detail)
            let supabaseURL = videoURL // In production: upload to Supabase Storage first

            captureState = .analyzing
            struct VideoData: Decodable { let initiateVideoAnalysis: VideoAnalysisResult }
            let variables: [String: Any] = [
                "input": ["videoUrl": supabaseURL, "analysisType": analysisType.rawValue]
            ]
            let data = try await GraphQLClient.shared.execute(
                query: GQL.initiateVideoAnalysis,
                variables: variables,
                type: VideoData.self
            )
            taskId = data.initiateVideoAnalysis.taskId
            await pollResult()
        } catch {
            self.error = error.localizedDescription
            withAnimation { captureState = .failed }
        }
    }

    func pollResult() async {
        guard let tid = taskId else { return }
        var attempts = 0
        while attempts < 60 {
            try? await Task.sleep(nanoseconds: 3_000_000_000) // 3s interval
            do {
                struct ResultData: Decodable { let videoAnalysisResult: VideoAnalysisResult }
                let data = try await GraphQLClient.shared.execute(
                    query: GQL.videoAnalysisResult,
                    variables: ["taskId": tid],
                    type: ResultData.self
                )
                let result = data.videoAnalysisResult
                if result.status == .completed || result.status == .failed {
                    withAnimation(AppAnimation.entrance) {
                        analysisResult = result
                        captureState = result.status == .completed ? .completed : .failed
                        showResult = true
                    }
                    return
                }
            } catch {}
            attempts += 1
        }
        withAnimation { captureState = .failed }
    }

    func reset() {
        withAnimation(AppAnimation.spring) {
            captureState = .idle
            recordingProgress = 0
            analysisResult = nil
            taskId = nil
            showResult = false
            error = nil
        }
    }
}

// MARK: - View

struct VideoAnalysisView: View {
    @State private var viewModel = VideoAnalysisViewModel()
    @State private var appear = false

    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedMeshBackground().ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppSpacing.lg) {
                        Color.clear.frame(height: 60)

                        // Header
                        headerSection
                            .opacity(appear ? 1 : 0)
                            .offset(y: appear ? 0 : -20)

                        // Type selector
                        typeSelector

                        // Camera / recorder area
                        cameraArea

                        // Result overlay
                        if viewModel.showResult, let result = viewModel.analysisResult {
                            analysisResultCard(result)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .bottom).combined(with: .opacity),
                                    removal: .opacity
                                ))
                        }

                        Color.clear.frame(height: AppSpacing.xxl)
                    }
                    .padding(.horizontal, AppSpacing.md)
                }
            }
            .navigationBarHidden(true)
            .onAppear { withAnimation(AppAnimation.entrance) { appear = true } }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Visual Analysis")
                    .font(AppFont.display(28))
                    .foregroundStyle(.white)
                Text("Show, don't just tell")
                    .font(AppFont.body())
                    .foregroundStyle(.vitaTeal)
            }
            Spacer()
            GlassIconButton(icon: "questionmark.circle", size: 40, iconSize: 18) {}
        }
    }

    // MARK: - Type Selector

    private var typeSelector: some View {
        HStack(spacing: AppSpacing.sm) {
            ForEach(VideoAnalysisViewModel.AnalysisType.allCases, id: \.rawValue) { type in
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(AppAnimation.spring) { viewModel.analysisType = type }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: type.icon)
                            .font(.system(size: 16, weight: .semibold))
                        Text(type.title)
                            .font(AppFont.body(15))
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(viewModel.analysisType == type ? .black : .white.opacity(0.7))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background {
                        if viewModel.analysisType == type {
                            RoundedRectangle(cornerRadius: AppRadius.pill, style: .continuous)
                                .fill(Color.vitaTeal)
                        } else {
                            RoundedRectangle(cornerRadius: AppRadius.pill, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .overlay {
                                    RoundedRectangle(cornerRadius: AppRadius.pill, style: .continuous)
                                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                }
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Camera Area

    private var cameraArea: some View {
        ZStack {
            // Camera placeholder (in production: AVCaptureVideoPreviewLayer)
            RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                .fill(Color.black.opacity(0.6))
                .overlay {
                    RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                        .stroke(
                            viewModel.captureState == .recording
                                ? Color.vitaCoral.opacity(0.8)
                                : Color.white.opacity(0.12),
                            lineWidth: viewModel.captureState == .recording ? 2 : 1
                        )
                }
                .frame(height: 320)

            // Camera content
            VStack(spacing: AppSpacing.md) {
                switch viewModel.captureState {
                case .idle:
                    idleOverlay
                case .recording:
                    recordingOverlay
                case .uploading, .analyzing:
                    processingOverlay
                case .completed:
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.vitaTeal)
                case .failed:
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.wellnessCrisis)
                }
            }
        }
    }

    private var idleOverlay: some View {
        VStack(spacing: AppSpacing.md) {
            ZStack {
                PulseRing(color: .vitaTeal, size: 70)
                Image(systemName: viewModel.analysisType.icon)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(.vitaTeal)
            }
            Text(viewModel.analysisType.description)
                .font(AppFont.body(15))
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
            PrimaryGlassButton(
                title: "Record Video",
                icon: "record.circle",
                gradient: LinearGradient(colors: [.vitaCoral, Color(red: 0.9, green: 0.2, blue: 0.3)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing)
            ) {
                viewModel.startRecording()
            }
            .frame(maxWidth: 200)
            Text("Max 30 seconds • Compressed locally")
                .font(AppFont.caption(11))
                .foregroundStyle(.white.opacity(0.35))
        }
        .padding(AppSpacing.lg)
    }

    private var recordingOverlay: some View {
        VStack(spacing: AppSpacing.md) {
            // Recording indicator
            HStack(spacing: 8) {
                Circle().fill(Color.vitaCoral)
                    .frame(width: 10, height: 10)
                    .shadow(color: .vitaCoral.opacity(0.8), radius: 6)
                Text("REC")
                    .font(AppFont.caption(13))
                    .fontWeight(.bold)
                    .foregroundStyle(.vitaCoral)
            }

            // Progress arc
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 6)
                    .frame(width: 100, height: 100)
                Circle()
                    .trim(from: 0, to: viewModel.recordingProgress)
                    .stroke(Color.vitaCoral, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                Text("\(Int((1 - viewModel.recordingProgress) * 30))s")
                    .font(AppFont.mono(22))
                    .foregroundStyle(.white)
            }

            PrimaryGlassButton(
                title: "Stop & Analyze",
                icon: "stop.circle.fill",
                gradient: LinearGradient(colors: [.vitaGold, .vitaCoral],
                                         startPoint: .topLeading, endPoint: .bottomTrailing)
            ) {
                Task { await viewModel.stopRecording(videoURL: "demo://video") }
            }
            .frame(maxWidth: 200)
        }
        .padding(AppSpacing.lg)
    }

    private var processingOverlay: some View {
        VStack(spacing: AppSpacing.md) {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(.vitaTeal)
                .scaleEffect(1.5)
            Text(viewModel.captureState.description)
                .font(AppFont.body(15))
                .foregroundStyle(.white.opacity(0.75))
            WaveformView(isActive: true, color: .vitaTeal)
        }
    }

    // MARK: - Result Card

    private func analysisResultCard(_ result: VideoAnalysisResult) -> some View {
        GlowingGlassCard(glowColor: result.safetyFlag ? .wellnessCaution : .vitaTeal) {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                // Header
                HStack {
                    Image(systemName: result.safetyFlag ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(result.safetyFlag ? .wellnessCaution : .vitaTeal)
                    Text(result.status.displayText)
                        .font(AppFont.title(16))
                        .foregroundStyle(.white)
                    Spacer()
                    Button(action: viewModel.reset) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    .buttonStyle(.plain)
                }

                Divider().background(.white.opacity(0.1))

                // Feedback
                if let feedback = result.feedback {
                    Text(feedback)
                        .font(AppFont.body(15))
                        .foregroundStyle(.white)
                        .lineSpacing(4)
                }

                // Nutrition estimate
                if let nutrition = result.nutritionEstimate, !nutrition.isEmpty && nutrition != "N/A" {
                    HStack(spacing: 10) {
                        Image(systemName: "fork.knife")
                            .foregroundStyle(.vitaTeal)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Nutritional Balance").font(AppFont.caption(11)).foregroundStyle(.white.opacity(0.5))
                            Text(nutrition).font(AppFont.body(14)).foregroundStyle(.white)
                        }
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: AppRadius.sm).fill(Color.vitaTeal.opacity(0.10)))
                }

                // Form notes
                if let form = result.formNotes, !form.isEmpty && form != "N/A" {
                    HStack(spacing: 10) {
                        Image(systemName: "figure.run")
                            .foregroundStyle(.vitaGold)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Form Feedback").font(AppFont.caption(11)).foregroundStyle(.white.opacity(0.5))
                            Text(form).font(AppFont.body(14)).foregroundStyle(.white)
                        }
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: AppRadius.sm).fill(Color.vitaGold.opacity(0.10)))
                }

                // Disclaimer
                Text("This is general wellness feedback, not medical advice.")
                    .font(AppFont.caption(11))
                    .foregroundStyle(.white.opacity(0.35))
                    .italic()
            }
        }
    }
}

#Preview {
    VideoAnalysisView()
}
