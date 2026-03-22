import SwiftUI
import AVKit

/// AI Voice Dubbing panel — Gemini transcription → translation → OpenClaw TTS → playback.
struct DubPanelView: View {
    let video: Video
    @Binding var settings: DubSettings
    @Binding var dubPlayer: AVPlayer?
    var originalPlayer: AVPlayer?

    @State private var phase: DubPhase = .idle
    @State private var transcript: String = ""
    @State private var translatedText: String = ""
    @State private var currentJob: AgentJob?
    @State private var errorMessage: String?

    private let apiClient = APIClient.shared

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Status Header
                        DubStatusHeader(phase: phase)

                        // Language Picker
                        SectionCard(title: "Target Language", icon: "globe", accent: .purple) {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(Language.allCases) { lang in
                                        LanguageChip(
                                            language: lang,
                                            isSelected: settings.targetLanguage == lang
                                        ) { settings.targetLanguage = lang }
                                    }
                                }
                            }
                        }

                        // Voice Persona Picker
                        SectionCard(title: "Voice Persona", icon: "person.wave.2.fill", accent: .indigo) {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                ForEach(VoicePersona.allCases) { persona in
                                    PersonaCard(
                                        persona: persona,
                                        isSelected: settings.voicePersona == persona
                                    ) { settings.voicePersona = persona }
                                }
                            }
                        }

                        // Transcript Preview
                        if !transcript.isEmpty {
                            SectionCard(title: "Transcript", icon: "text.bubble.fill", accent: .gray) {
                                Text(transcript)
                                    .font(.system(size: 14))
                                    .foregroundStyle(.white.opacity(0.85))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }

                        if !translatedText.isEmpty {
                            SectionCard(title: "Translation", icon: "character.bubble.fill", accent: .green) {
                                Text(translatedText)
                                    .font(.system(size: 14))
                                    .foregroundStyle(.white.opacity(0.85))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }

                        // Error
                        if let error = errorMessage {
                            Label(error, systemImage: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                                .font(.footnote)
                                .padding()
                                .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                        }

                        // Action Button
                        actionButton
                    }
                    .padding()
                }
            }
            .navigationTitle("AI Voice Dub")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if settings.isActive {
                        Button("Disable") {
                            settings.isActive = false
                            dubPlayer?.pause()
                            originalPlayer?.volume = 1.0
                        }
                        .foregroundStyle(.red)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Action Button

    @ViewBuilder
    var actionButton: some View {
        switch phase {
        case .idle:
            PrimaryButton(label: "Start Dubbing", icon: "wand.and.stars", color: .purple) {
                Task { await startDubbing() }
            }
        case .transcribing, .translating, .generating:
            HStack(spacing: 12) {
                ProgressView().tint(.white)
                Text(phase.label)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 14))
        case .ready:
            PrimaryButton(
                label: settings.isActive ? "Playing Dub" : "Play Dub",
                icon: settings.isActive ? "pause.fill" : "play.fill",
                color: .green
            ) { toggleDub() }
        case .failed:
            PrimaryButton(label: "Retry", icon: "arrow.clockwise", color: .orange) {
                phase = .idle
                errorMessage = nil
                Task { await startDubbing() }
            }
        }
    }

    // MARK: - Dubbing Pipeline

    private func startDubbing() async {
        errorMessage = nil

        // 1. Transcribe via Gemini (through Python FastAPI)
        phase = .transcribing
        do {
            let transcribeJob = try await apiClient.transcribeVideo(videoID: video.id)
            let done = try await pollJob(transcribeJob.id)
            transcript = done.result ?? ""
        } catch {
            handleError(error); return
        }

        // 2. Translate via OpenClaw agent
        phase = .translating
        do {
            let dubJob = try await apiClient.dubVideo(
                videoID: video.id,
                language: settings.targetLanguage.rawValue,
                persona: settings.voicePersona.rawValue
            )
            let done = try await pollJob(dubJob.id)
            translatedText = done.result ?? ""
        } catch {
            handleError(error); return
        }

        // 3. Generate TTS audio via OpenClaw ace-music / TTS skill
        phase = .generating
        do {
            let ttsJob = try await apiClient.dubVideo(
                videoID: video.id,
                language: settings.targetLanguage.rawValue,
                persona: settings.voicePersona.rawValue
            )
            let done = try await pollJob(ttsJob.id)
            if let urlString = done.result, let url = URL(string: urlString) {
                settings.dubAudioURL = url
                dubPlayer = AVPlayer(url: url)
            }
        } catch {
            handleError(error); return
        }

        phase = .ready
    }

    private func pollJob(_ jobID: String) async throws -> AgentJob {
        var job = try await apiClient.pollJob(jobID: jobID)
        while job.status == .pending || job.status == .running {
            try await Task.sleep(for: .seconds(2))
            job = try await apiClient.pollJob(jobID: jobID)
        }
        if job.status == .failed { throw APIError.serverError(job.error ?? "Job failed") }
        return job
    }

    private func toggleDub() {
        guard let dubPlayer else { return }
        settings.isActive.toggle()
        if settings.isActive {
            originalPlayer?.volume = 0.1
            dubPlayer.seek(to: originalPlayer?.currentTime() ?? .zero)
            dubPlayer.play()
        } else {
            originalPlayer?.volume = 1.0
            dubPlayer.pause()
        }
    }

    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        phase = .failed
    }
}

// MARK: - Supporting Types

enum DubPhase {
    case idle, transcribing, translating, generating, ready, failed
    var label: String {
        switch self {
        case .idle: return "Ready"
        case .transcribing: return "Transcribing with Gemini..."
        case .translating: return "Translating..."
        case .generating: return "Generating voice with OpenClaw..."
        case .ready: return "Ready"
        case .failed: return "Failed"
        }
    }
}

// MARK: - Sub-components

struct DubStatusHeader: View {
    let phase: DubPhase

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(phaseColor.opacity(0.2))
                    .frame(width: 52, height: 52)
                Image(systemName: phaseIcon)
                    .font(.title2)
                    .foregroundStyle(phaseColor)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("AI Voice Dubbing")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                Text(phase.label)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private var phaseColor: Color {
        switch phase {
        case .idle: return .purple
        case .transcribing, .translating, .generating: return .orange
        case .ready: return .green
        case .failed: return .red
        }
    }

    private var phaseIcon: String {
        switch phase {
        case .idle: return "person.wave.2.fill"
        case .transcribing: return "waveform"
        case .translating: return "globe"
        case .generating: return "waveform.path.ecg"
        case .ready: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        }
    }
}

struct LanguageChip: View {
    let language: Language
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(language.flag)
                    .font(.title2)
                Text(language.label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(isSelected ? .black : .white)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isSelected ? Color.purple : Color.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.purple : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

struct PersonaCard: View {
    let persona: VoicePersona
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: persona.icon)
                    .font(.system(size: 20))
                    .foregroundStyle(isSelected ? .white : .purple)
                Text(persona.label)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(isSelected ? Color.purple.opacity(0.4) : Color.white.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? .purple : .clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

struct PrimaryButton: View {
    let label: String
    let icon: String
    var color: Color = .purple
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(label, systemImage: icon)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(color.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: color.opacity(0.4), radius: 10, y: 4)
        }
        .buttonStyle(.plain)
    }
}
