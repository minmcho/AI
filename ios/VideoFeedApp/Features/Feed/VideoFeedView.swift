import SwiftUI
import AVKit

/// Full-screen vertical snap-scrolling video feed — iOS 17 ScrollView with
/// `.scrollTargetBehavior(.paging)` and `scrollPosition(id:)` for active tracking.
struct VideoFeedView: View {
    @Environment(AppState.self) private var appState
    @State private var scrollPosition: String?
    @State private var activeMood: Mood?
    @State private var showStudyMode  = false
    @State private var streakDays     = 0
    @State private var userLevel      = 1

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topTrailing) {
                // ── Main feed ─────────────────────────────────────────────────
                ScrollView(.vertical) {
                    LazyVStack(spacing: 0) {
                        ForEach(appState.videos) { video in
                            VideoPostView(video: video)
                                .frame(width: geo.size.width, height: geo.size.height)
                                .id(video.id)
                        }

                        // Infinite scroll trigger
                        if !appState.videos.isEmpty {
                            ProgressView()
                                .frame(height: 60)
                                .onAppear {
                                    Task { await appState.loadMoreVideos() }
                                }
                        }
                    }
                }
                .scrollTargetBehavior(.paging)
                .scrollPosition(id: $scrollPosition)
                .scrollIndicators(.hidden)
                .ignoresSafeArea()
                .onChange(of: scrollPosition) { _, newID in
                    appState.currentVideoID = newID
                    // Award XP when user watches a new video
                    Task { await awardWatchXP() }
                }
                .onChange(of: activeMood) { _, mood in
                    Task {
                        if let mood {
                            await appState.loadMoodFeed(mood: mood.id)
                        } else {
                            await appState.loadInitialFeed()
                        }
                    }
                }

                // ── Top-right HUD ─────────────────────────────────────────────
                VStack(alignment: .trailing, spacing: 10) {
                    // Streak badge
                    if streakDays > 0 {
                        StreakWidgetBadge(streakDays: streakDays, level: userLevel)
                    }

                    // Mood selector pill
                    MoodSelectorView(activeMood: $activeMood)

                    // Study mode quick-launch
                    Button { showStudyMode = true } label: {
                        HStack(spacing: 5) {
                            Text("📚")
                            Text("Study")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(.white.opacity(0.15))
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 60)
                .padding(.trailing, 14)
            }
        }
        .ignoresSafeArea()
        .background(.black)
        .sheet(isPresented: $showStudyMode) {
            StudyModeView()
        }
        .task {
            await appState.loadInitialFeed()
            await loadStreakData()
        }
    }

    private func loadStreakData() async {
        do {
            let data: StreakData = try await APIClient.shared.get(
                "/api/v1/streak/demo", base: APIClient.shared.goBase
            )
            streakDays = data.streakDays
            userLevel  = data.level
        } catch {}
    }

    private func awardWatchXP() async {
        struct Req: Encodable { let profile_id: String; let action: String }
        struct Resp: Decodable {}
        let _: Resp? = try? await APIClient.shared.post(
            "/api/v1/streak/award",
            body: Req(profile_id: "demo", action: "watch"),
            base: APIClient.shared.goBase
        )
    }
}
