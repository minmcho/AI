import SwiftUI
import Observation

@Observable
final class AppState {
    var videos: [Video] = []
    var currentVideoID: String?
    var isLoadingFeed = false
    var feedError: Error?

    private var page = 0
    private let supabaseService = SupabaseService()

    func loadInitialFeed() async {
        guard !isLoadingFeed else { return }
        isLoadingFeed = true
        defer { isLoadingFeed = false }
        do {
            videos = try await supabaseService.fetchFeed(page: 0)
            page = 1
            currentVideoID = videos.first?.id
        } catch {
            feedError = error
        }
    }

    func loadMoreVideos() async {
        guard !isLoadingFeed else { return }
        isLoadingFeed = true
        defer { isLoadingFeed = false }
        do {
            let next = try await supabaseService.fetchFeed(page: page)
            videos.append(contentsOf: next)
            page += 1
        } catch {
            feedError = error
        }
    }

    func likeVideo(_ videoID: String) async {
        guard let index = videos.firstIndex(where: { $0.id == videoID }) else { return }
        videos[index].likes += 1
        try? await supabaseService.likeVideo(id: videoID)
    }

    /// Load a mood-filtered feed from the backend.
    func loadMoodFeed(mood: String) async {
        guard !isLoadingFeed else { return }
        isLoadingFeed = true
        defer { isLoadingFeed = false }
        do {
            struct Resp: Decodable { let videos: [Video] }
            let resp: Resp = try await APIClient.shared.get(
                "/api/v1/feed/mood?mood=\(mood)&limit=30",
                base: APIClient.shared.goBase
            )
            videos = resp.videos.isEmpty ? videos : resp.videos  // keep existing if no results
            page = 1
            currentVideoID = videos.first?.id
        } catch {
            feedError = error
        }
    }
}
