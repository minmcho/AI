import SwiftUI
import AVKit

/// Full-screen vertical snap-scrolling video feed — iOS 17 ScrollView with
/// `.scrollTargetBehavior(.paging)` and `scrollPosition(id:)` for active tracking.
struct VideoFeedView: View {
    @Environment(AppState.self) private var appState
    @State private var scrollPosition: String?

    var body: some View {
        GeometryReader { geo in
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
            .scrollTargetBehavior(.paging)                      // iOS 17 snap scrolling
            .scrollPosition(id: $scrollPosition)               // iOS 17 active item tracking
            .scrollIndicators(.hidden)
            .ignoresSafeArea()
            .onChange(of: scrollPosition) { _, newID in
                appState.currentVideoID = newID
            }
        }
        .ignoresSafeArea()
        .background(.black)
        .task { await appState.loadInitialFeed() }
    }
}
