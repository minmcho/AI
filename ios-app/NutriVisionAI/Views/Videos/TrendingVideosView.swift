//
//  TrendingVideosView.swift
//  NutriVision AI
//
//  Browse trending cooking videos
//

import SwiftUI

struct TrendingVideosView: View {
    @StateObject private var viewModel = TrendingVideosViewModel()
    @State private var selectedCuisine: String?

    let cuisineOptions = ["All", "Italian", "Chinese", "Japanese", "Korean", "Thai", "Mexican", "French"]

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Cuisine Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(cuisineOptions, id: \.self) { cuisine in
                            CuisineFilterChip(
                                cuisine: cuisine,
                                isSelected: selectedCuisine == cuisine || (selectedCuisine == nil && cuisine == "All")
                            ) {
                                selectedCuisine = cuisine == "All" ? nil : cuisine
                                Task {
                                    await viewModel.loadTrendingVideos(cuisine: selectedCuisine)
                                }
                            }
                        }
                    }
                    .padding()
                }

                // Content
                if viewModel.isLoading {
                    Spacer()
                    ProgressView("Loading trending videos...")
                    Spacer()
                } else if let error = viewModel.errorMessage {
                    Spacer()
                    ErrorView(message: error) {
                        Task {
                            await viewModel.loadTrendingVideos(cuisine: selectedCuisine)
                        }
                    }
                    Spacer()
                } else if let response = viewModel.trendingResponse {
                    ScrollView {
                        VStack(spacing: 16) {
                            // Header Stats
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(response.totalCount) Videos")
                                        .font(.title3)
                                        .fontWeight(.bold)

                                    if let cuisine = response.cuisine {
                                        Text("\(cuisine) Cuisine")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    } else {
                                        Text("Trending Now")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)

                            // Video List
                            ForEach(response.videos) { video in
                                NavigationLink(destination: VideoPlayerView(video: video)) {
                                    TrendingVideoCard(video: video)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.bottom)
                    }
                } else {
                    Spacer()
                    Text("No videos available")
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
            .navigationTitle("Trending Videos")
            .navigationBarTitleDisplayMode(.large)
            .task {
                await viewModel.loadTrendingVideos(cuisine: selectedCuisine)
            }
        }
    }
}

// MARK: - Cuisine Filter Chip

struct CuisineFilterChip: View {
    let cuisine: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(cuisine)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

// MARK: - Trending Video Card

struct TrendingVideoCard: View {
    let video: Video

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Thumbnail
            AsyncImage(url: URL(string: video.thumbnailUrl)) { phase in
                switch phase {
                case .empty:
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 200)
                        .overlay(
                            ProgressView()
                        )
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)
                        .clipped()
                case .failure:
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 200)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                        )
                @unknown default:
                    EmptyView()
                }
            }
            .overlay(
                // Platform Badge
                HStack {
                    Spacer()
                    VStack {
                        HStack(spacing: 4) {
                            Image(systemName: platformIcon)
                            Text(video.platform.displayName)
                                .font(.caption2)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(platformColor)
                        .foregroundColor(.white)
                        .cornerRadius(6)
                        .padding(8)
                        Spacer()
                    }
                }
            )
            .overlay(
                // Duration Badge
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        if let duration = video.duration {
                            Text(duration)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.black.opacity(0.8))
                                .foregroundColor(.white)
                                .cornerRadius(4)
                                .padding(8)
                        }
                    }
                }
            )

            // Video Info
            VStack(alignment: .leading, spacing: 8) {
                Text(video.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(2)

                if let channelName = video.channelName {
                    Text(channelName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 12) {
                    if let views = video.viewCount {
                        HStack(spacing: 4) {
                            Image(systemName: "eye")
                            Text(formatNumber(views))
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }

                    if let likes = video.likeCount {
                        HStack(spacing: 4) {
                            Image(systemName: "hand.thumbsup")
                            Text(formatNumber(likes))
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }

                    if let score = video.relevanceScore {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                            Text("\(Int(score * 100))%")
                        }
                        .font(.caption)
                        .foregroundColor(.yellow)
                    }
                }
            }
            .padding()
        }
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }

    private var platformIcon: String {
        switch video.platform {
        case .youtube: return "play.rectangle.fill"
        case .tiktok: return "music.note"
        case .instagram: return "camera.fill"
        case .other: return "video.fill"
        }
    }

    private var platformColor: Color {
        switch video.platform {
        case .youtube: return .red
        case .tiktok: return .pink
        case .instagram: return .purple
        case .other: return .blue
        }
    }

    private func formatNumber(_ number: Int) -> String {
        if number >= 1_000_000 {
            return String(format: "%.1fM", Double(number) / 1_000_000)
        } else if number >= 1_000 {
            return String(format: "%.1fK", Double(number) / 1_000)
        }
        return "\(number)"
    }
}

// MARK: - ViewModel

@MainActor
class TrendingVideosViewModel: ObservableObject {
    @Published var trendingResponse: TrendingVideosResponse?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let videoService = VideoService()

    func loadTrendingVideos(cuisine: String?) async {
        isLoading = true
        errorMessage = nil

        do {
            trendingResponse = try await videoService.getTrendingVideos(
                cuisine: cuisine
            )
        } catch {
            errorMessage = "Failed to load videos: \(error.localizedDescription)"
        }

        isLoading = false
    }
}

// MARK: - Preview

struct TrendingVideosView_Previews: PreviewProvider {
    static var previews: some View {
        TrendingVideosView()
    }
}
