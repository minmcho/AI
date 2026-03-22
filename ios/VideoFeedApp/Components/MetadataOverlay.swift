import SwiftUI

struct MetadataOverlay: View {
    let video: Video

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Author
            HStack(spacing: 8) {
                AsyncImage(url: video.author.avatarURL) { img in
                    img.resizable().scaledToFill()
                } placeholder: {
                    Circle().fill(.gray.opacity(0.4))
                }
                .frame(width: 36, height: 36)
                .clipShape(Circle())
                .overlay(Circle().stroke(.white, lineWidth: 1.5))

                Text("@\(video.author.username)")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
            }

            // Caption
            Text(video.caption)
                .font(.system(size: 14))
                .foregroundStyle(.white)
                .lineLimit(3)
                .multilineTextAlignment(.leading)

            // Tags
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(video.tags, id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white.opacity(0.85))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.trailing, 60)
    }
}

struct ActionButtonColumn: View {
    let video: Video
    @Binding var isMuted: Bool
    @Binding var showDJPanel: Bool
    @Binding var showDubPanel: Bool
    let onLike: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            // Like
            ActionButton(icon: "heart.fill", label: video.likes.formatted(), color: .pink, action: onLike)

            // Comment
            ActionButton(icon: "bubble.right.fill", label: video.comments.formatted(), color: .white)

            // Share
            ActionButton(icon: "arrowshape.turn.up.right.fill", label: video.shares.formatted(), color: .white)

            Divider().frame(width: 36).overlay(.white.opacity(0.3))

            // DJ Mode
            ActionButton(icon: "dial.medium.fill", label: "DJ", color: .cyan) { showDJPanel = true }

            // Dub
            ActionButton(icon: "person.wave.2.fill", label: "Dub", color: .purple) { showDubPanel = true }

            // Mute
            ActionButton(
                icon: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill",
                label: "",
                color: .white
            ) { isMuted.toggle() }
        }
    }
}

struct ActionButton: View {
    let icon: String
    let label: String
    var color: Color = .white
    var action: (() -> Void)? = nil

    var body: some View {
        Button(action: { action?() }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(color)
                    .shadow(color: color.opacity(0.6), radius: 8)
                if !label.isEmpty {
                    Text(label)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
