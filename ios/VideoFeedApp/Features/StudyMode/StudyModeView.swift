import SwiftUI
import AVFoundation

/// Study Mode — Pomodoro timer + lofi video feed.
/// Designed specifically for college students during study sessions.
struct StudyModeView: View {
    @State private var viewModel = StudyModeViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {

                        // ── Pomodoro Timer ────────────────────────────────────
                        PomodoroTimerView(viewModel: viewModel)

                        // ── Session Stats ─────────────────────────────────────
                        SessionStatsRow(viewModel: viewModel)

                        // ── Subject Picker ────────────────────────────────────
                        SubjectPickerView(selected: $viewModel.subject)

                        // ── Lofi Feed ─────────────────────────────────────────
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "music.note.list")
                                    .foregroundStyle(.green)
                                Text("Lofi & Study Beats")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(.white)
                                Spacer()
                                Text("\(viewModel.lofiVideos.count) tracks")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            if viewModel.isLoadingLofi {
                                ProgressView()
                                    .frame(maxWidth: .infinity, minHeight: 80)
                            } else {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(viewModel.lofiVideos) { video in
                                            LofiTrackCard(video: video,
                                                          isPlaying: viewModel.activeTrackID == video.id) {
                                                viewModel.toggleTrack(video)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(16)
                        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 18))
                        .overlay(RoundedRectangle(cornerRadius: 18).stroke(.green.opacity(0.2), lineWidth: 1))

                        // ── All-time Study Stats ───────────────────────────────
                        if let stats = viewModel.allTimeStats {
                            AllTimeStatsView(stats: stats)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Study Mode")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(.cyan)
                }
            }
        }
        .preferredColorScheme(.dark)
        .task {
            await viewModel.loadLofi()
            await viewModel.loadStats()
        }
    }
}

// MARK: - Pomodoro Timer

struct PomodoroTimerView: View {
    @Bindable var viewModel: StudyModeViewModel
    private let totalSeconds: Int = 25 * 60

    var body: some View {
        VStack(spacing: 20) {
            // Ring
            ZStack {
                Circle()
                    .stroke(.white.opacity(0.1), lineWidth: 10)
                    .frame(width: 200, height: 200)

                Circle()
                    .trim(from: 0, to: viewModel.timerProgress)
                    .stroke(
                        LinearGradient(colors: [.green, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: viewModel.timerProgress)

                VStack(spacing: 6) {
                    Text(viewModel.timeString)
                        .font(.system(size: 52, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)

                    Text(viewModel.isBreak ? "☕ Break" : "📖 Focus")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(viewModel.isBreak ? .orange : .green)
                }
            }

            // Controls
            HStack(spacing: 24) {
                Button { viewModel.reset() } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)

                Button { viewModel.toggleTimer() } label: {
                    ZStack {
                        Circle()
                            .fill(viewModel.isRunning ? Color.orange : Color.green)
                            .frame(width: 64, height: 64)
                        Image(systemName: viewModel.isRunning ? "pause.fill" : "play.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                    }
                }
                .buttonStyle(.plain)

                Button { viewModel.skipToBreak() } label: {
                    Image(systemName: "forward.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            // Completed pomodoros (tomato icons)
            HStack(spacing: 6) {
                ForEach(0..<max(viewModel.completedPomodoros, 4), id: \.self) { i in
                    Text(i < viewModel.completedPomodoros ? "🍅" : "○")
                        .font(.system(size: i < viewModel.completedPomodoros ? 20 : 16))
                }
            }
        }
        .padding(24)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(.green.opacity(0.2), lineWidth: 1))
    }
}

// MARK: - Session Stats Row

struct SessionStatsRow: View {
    let viewModel: StudyModeViewModel
    var body: some View {
        HStack(spacing: 0) {
            StatCell(value: "\(viewModel.completedPomodoros)", label: "Pomodoros", emoji: "🍅")
            Divider().frame(height: 40).overlay(.white.opacity(0.1))
            StatCell(value: "\(viewModel.sessionMinutes)", label: "Minutes", emoji: "⏱")
            Divider().frame(height: 40).overlay(.white.opacity(0.1))
            StatCell(value: "+\(viewModel.completedPomodoros * 50)", label: "XP Earned", emoji: "⚡")
        }
        .padding(.vertical, 12)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14))
    }
}

struct StatCell: View {
    let value: String
    let label: String
    let emoji: String
    var body: some View {
        VStack(spacing: 4) {
            Text(emoji).font(.title3)
            Text(value).font(.system(size: 20, weight: .bold)).foregroundStyle(.white)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Subject Picker

struct SubjectPickerView: View {
    @Binding var selected: String?
    private let subjects = ["Math", "CS", "History", "English", "Science", "Art", "Business", "Law", "Medicine", "Languages"]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Studying")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(subjects, id: \.self) { subj in
                        Button { selected = selected == subj ? nil : subj } label: {
                            Text(subj)
                                .font(.system(size: 13, weight: .semibold))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(selected == subj ? Color.green.opacity(0.25) : Color.white.opacity(0.07))
                                .foregroundStyle(selected == subj ? .green : .secondary)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

// MARK: - Lofi Track Card

struct LofiTrackCard: View {
    let video: VideoItem
    let isPlaying: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottomLeading) {
                AsyncImage(url: video.thumbnailURL) { img in
                    img.resizable().scaledToFill()
                } placeholder: {
                    RoundedRectangle(cornerRadius: 12).fill(.white.opacity(0.08))
                }
                .frame(width: 130, height: 90)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isPlaying ? Color.green : .clear, lineWidth: 2)
                )
                .overlay(alignment: .center) {
                    if isPlaying {
                        Image(systemName: "pause.circle.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.white)
                            .shadow(radius: 4)
                    }
                }

                LinearGradient(colors: [.clear, .black.opacity(0.7)], startPoint: .top, endPoint: .bottom)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                Text(video.caption ?? "Lofi Track")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .padding(8)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - All-Time Stats

struct AllTimeStatsView: View {
    let stats: StudyStats
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("All-Time Study Stats", systemImage: "chart.bar.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.green)

            HStack(spacing: 12) {
                MiniStatCard(value: "\(stats.totalHours)h", label: "Studied", color: .green)
                MiniStatCard(value: "\(stats.totalPomodoros)", label: "Pomodoros", color: .orange)
                MiniStatCard(value: "\(stats.totalSessions)", label: "Sessions", color: .cyan)
            }

            if !stats.subjects.isEmpty {
                Text("Subjects: \(stats.subjects.joined(separator: " · "))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(.green.opacity(0.15), lineWidth: 1))
    }
}

struct MiniStatCard: View {
    let value: String
    let label: String
    let color: Color
    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(.system(size: 18, weight: .bold)).foregroundStyle(color)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - ViewModel

typealias VideoItem = Video  // reuse the existing Video model

@Observable
final class StudyModeViewModel {
    var lofiVideos:        [VideoItem] = []
    var isLoadingLofi      = false
    var activeTrackID:     String?
    var subject:           String?
    var allTimeStats:      StudyStats?

    // Timer state
    var isRunning          = false
    var isBreak            = false
    var secondsLeft        = 25 * 60
    var completedPomodoros = 0
    private var timer:     Timer?

    var timerProgress: CGFloat {
        let total = isBreak ? 5 * 60 : 25 * 60
        return CGFloat(total - secondsLeft) / CGFloat(total)
    }

    var timeString: String {
        String(format: "%02d:%02d", secondsLeft / 60, secondsLeft % 60)
    }

    var sessionMinutes: Int { completedPomodoros * 25 }

    func toggleTimer() {
        if isRunning { pauseTimer() } else { startTimer() }
    }

    private func startTimer() {
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            if secondsLeft > 0 {
                secondsLeft -= 1
            } else {
                if !isBreak {
                    completedPomodoros += 1
                    Task { await self.awardPomodoroXP() }
                }
                isBreak.toggle()
                secondsLeft = isBreak ? 5 * 60 : 25 * 60
            }
        }
    }

    private func pauseTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    func reset() {
        pauseTimer()
        isBreak = false
        secondsLeft = 25 * 60
    }

    func skipToBreak() {
        if !isBreak {
            completedPomodoros += 1
        }
        isBreak.toggle()
        secondsLeft = isBreak ? 5 * 60 : 25 * 60
    }

    func toggleTrack(_ video: VideoItem) {
        activeTrackID = activeTrackID == video.id ? nil : video.id
    }

    func loadLofi() async {
        isLoadingLofi = true
        defer { isLoadingLofi = false }
        do {
            struct Resp: Decodable { let videos: [VideoItem] }
            let r: Resp = try await APIClient.shared.get("/api/v1/study/lofi-feed", base: APIClient.shared.goBase)
            lofiVideos = r.videos
        } catch {
            print("Lofi load error: \(error)")
        }
    }

    func loadStats() async {
        do {
            allTimeStats = try await APIClient.shared.get(
                "/api/v1/study/stats/demo", base: APIClient.shared.goBase
            )
        } catch {}
    }

    private func awardPomodoroXP() async {
        struct AwardReq: Encodable { let profile_id: String; let action: String }
        struct AwardResp: Decodable {}
        let _: AwardResp? = try? await APIClient.shared.post(
            "/api/v1/streak/award",
            body: AwardReq(profile_id: "demo", action: "study_session"),
            base: APIClient.shared.goBase
        )
    }
}
