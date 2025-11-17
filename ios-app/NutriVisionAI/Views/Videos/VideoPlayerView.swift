//
//  VideoPlayerView.swift
//  NutriVision AI
//
//  Video player for cooking tutorials
//

import SwiftUI
import AVKit

struct VideoPlayerView: View {
    let video: Video
    @State private var player: AVPlayer?
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack(spacing: 0) {
            // Video Player
            if let player = player {
                VideoPlayer(player: player)
                    .frame(height: 250)
            } else {
                Rectangle()
                    .fill(Color.black)
                    .frame(height: 250)
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    )
            }

            // Video Details
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Title
                    Text(video.title)
                        .font(.title3)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                        .padding(.top)

                    // Metadata
                    HStack(spacing: 16) {
                        // Platform
                        HStack(spacing: 4) {
                            Image(systemName: platformIcon)
                                .foregroundColor(platformColor)
                            Text(video.platform.displayName)
                                .font(.caption)
                        }

                        // Duration
                        if let duration = video.duration {
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                Text(duration)
                                    .font(.caption)
                            }
                        }

                        // Views
                        if let views = video.viewCount {
                            HStack(spacing: 4) {
                                Image(systemName: "eye")
                                Text("\(formatNumber(views)) views")
                                    .font(.caption)
                            }
                        }

                        Spacer()
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal)

                    // Channel Info
                    if let channelName = video.channelName {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(channelName)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)

                                if let likes = video.likeCount {
                                    HStack(spacing: 4) {
                                        Image(systemName: "hand.thumbsup")
                                        Text("\(formatNumber(likes)) likes")
                                    }
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                }
                            }

                            Spacer()
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }

                    // Description
                    if let description = video.description {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(.headline)

                            Text(description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                    }

                    // Open in App Button
                    Button(action: {
                        if let url = URL(string: video.videoUrl) {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Image(systemName: "arrow.up.right.square")
                            Text("Watch on \(video.platform.displayName)")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(platformColor.opacity(0.1))
                        .foregroundColor(platformColor)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)

                    Spacer()
                }
            }
        }
        .navigationTitle("Video")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            setupPlayer()
        }
        .onDisappear {
            player?.pause()
        }
    }

    private func setupPlayer() {
        guard let url = URL(string: video.videoUrl) else { return }
        player = AVPlayer(url: url)
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

// MARK: - Preview

struct VideoPlayerView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            VideoPlayerView(video: Video(
                id: "1",
                title: "How to Make Perfect Pasta",
                description: "Learn the secrets to making restaurant-quality pasta at home",
                thumbnailUrl: "",
                videoUrl: "https://example.com/video.mp4",
                platform: .youtube,
                duration: "10:30",
                viewCount: 1500000,
                likeCount: 45000,
                channelName: "Chef's Kitchen",
                channelUrl: nil,
                relevanceScore: nil
            ))
        }
    }
}
