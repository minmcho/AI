import SwiftUI

/// Floating mood pill that overlays the video feed.
/// Tapping it reveals a horizontal mood picker; selecting a mood
/// pivots the feed to mood-tagged content.
struct MoodSelectorView: View {
    @Binding var activeMood: Mood?
    @State private var moods: [Mood] = []
    @State private var isExpanded = false
    @State private var isLoading = false

    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            // ── Expanded mood strip ───────────────────────────────────────────
            if isExpanded {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        // "For You" — clears mood filter
                        MoodPill(emoji: "✨", label: "For You", color: .white,
                                 isSelected: activeMood == nil) {
                            activeMood = nil
                            withAnimation(.spring) { isExpanded = false }
                        }

                        ForEach(moods) { mood in
                            MoodPill(
                                emoji: mood.emoji,
                                label: mood.label,
                                color: mood.swiftUIColor,
                                isSelected: activeMood?.id == mood.id
                            ) {
                                withAnimation(.spring) {
                                    activeMood = mood
                                    isExpanded = false
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
                .background(.black.opacity(0.7))
                .clipShape(RoundedRectangle(cornerRadius: 28))
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }

            // ── Collapsed toggle pill ─────────────────────────────────────────
            Button {
                if moods.isEmpty { Task { await loadMoods() } }
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 6) {
                    Text(activeMood?.emoji ?? "✨")
                        .font(.system(size: 18))
                    if let mood = activeMood {
                        Text(mood.label)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    Image(systemName: isExpanded ? "chevron.right" : "chevron.left")
                        .font(.caption.bold())
                        .foregroundStyle(.white.opacity(0.7))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background((activeMood?.swiftUIColor ?? .white).opacity(0.25))
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(
                        (activeMood?.swiftUIColor ?? .white).opacity(0.4), lineWidth: 1
                    )
                )
            }
            .buttonStyle(.plain)
        }
        .task { await loadMoods() }
    }

    private func loadMoods() async {
        guard moods.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            struct Resp: Decodable { let moods: [Mood] }
            let resp: Resp = try await APIClient.shared.get("/api/v1/moods", base: APIClient.shared.goBase)
            moods = resp.moods
        } catch {
            // Use hardcoded fallback when offline
            moods = Mood.fallback
        }
    }
}

// MARK: - Pill

struct MoodPill: View {
    let emoji: String
    let label: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Text(emoji).font(.title3)
                Text(label)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(isSelected ? color : .white.opacity(0.6))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? color.opacity(0.25) : .white.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? color : .clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Fallback moods (offline)

extension Mood {
    static let fallback: [Mood] = [
        Mood(id: "hype",     emoji: "🔥", label: "Hype",     color: "#FF4500"),
        Mood(id: "chill",    emoji: "😌", label: "Chill",    color: "#5AC8FA"),
        Mood(id: "sad",      emoji: "😭", label: "Sad",      color: "#5856D6"),
        Mood(id: "funny",    emoji: "😂", label: "Funny",    color: "#FFD60A"),
        Mood(id: "study",    emoji: "📚", label: "Study",    color: "#34C759"),
        Mood(id: "dance",    emoji: "💃", label: "Dance",    color: "#FF2D92"),
        Mood(id: "romantic", emoji: "💕", label: "Romantic", color: "#FF6B6B"),
        Mood(id: "gaming",   emoji: "🎮", label: "Gaming",   color: "#BF5AF2"),
        Mood(id: "asmr",     emoji: "🎧", label: "ASMR",    color: "#30D158"),
    ]
}
