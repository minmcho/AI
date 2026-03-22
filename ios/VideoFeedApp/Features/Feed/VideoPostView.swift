import SwiftUI
import AVKit

/// Single full-screen video post with overlay controls, DJ Mode and Dub Panel.
struct VideoPostView: View {
    let video: Video
    @Environment(AppState.self) private var appState

    @State private var player: AVPlayer?
    @State private var isPlaying = false
    @State private var isMuted = false
    @State private var showDJPanel = false
    @State private var showDubPanel = false
    @State private var djEngine = DJAudioEngine()
    @State private var dubSettings = DubSettings()
    @State private var dubPlayer: AVPlayer?

    private var isActive: Bool { appState.currentVideoID == video.id }

    var body: some View {
        ZStack {
            // MARK: - Video Layer
            VideoPlayerLayer(player: $player)
                .ignoresSafeArea()
                .onTapGesture { togglePlay() }

            // MARK: - Gradient Overlay
            LinearGradient(
                colors: [.clear, .black.opacity(0.7)],
                startPoint: .center,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // MARK: - UI Overlays
            HStack(alignment: .bottom) {
                // Bottom left: metadata
                MetadataOverlay(video: video)

                Spacer()

                // Right side: action buttons
                ActionButtonColumn(
                    video: video,
                    isMuted: $isMuted,
                    showDJPanel: $showDJPanel,
                    showDubPanel: $showDubPanel,
                    onLike: { Task { await appState.likeVideo(video.id) } }
                )
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 90)

            // MARK: - Active indicator & play/pause
            if !isPlaying {
                Image(systemName: "play.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.white.opacity(0.8))
                    .shadow(radius: 10)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .sheet(isPresented: $showDJPanel) {
            DJPanelView(engine: djEngine, player: player)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showDubPanel) {
            DubPanelView(video: video, settings: $dubSettings, dubPlayer: $dubPlayer, originalPlayer: player)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .onAppear { setupPlayer() }
        .onDisappear { teardownPlayer() }
        .onChange(of: isActive) { _, active in active ? play() : pause() }
        .onChange(of: isMuted) { _, muted in player?.isMuted = muted }
        .onChange(of: dubSettings.isActive) { _, active in
            player?.volume = active ? 0.1 : 1.0
        }
    }

    // MARK: - Player Lifecycle

    private func setupPlayer() {
        let item = AVPlayerItem(url: video.url)
        let p = AVPlayer(playerItem: item)
        p.actionAtItemEnd = .none
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: .main
        ) { _ in p.seek(to: .zero); p.play() }
        player = p
        if isActive { play() }
    }

    private func teardownPlayer() {
        player?.pause()
        player = nil
    }

    private func play() {
        player?.play()
        withAnimation(.easeInOut(duration: 0.15)) { isPlaying = true }
    }

    private func pause() {
        player?.pause()
        withAnimation(.easeInOut(duration: 0.15)) { isPlaying = false }
    }

    private func togglePlay() {
        isPlaying ? pause() : play()
    }
}

// MARK: - VideoPlayerLayer

struct VideoPlayerLayer: UIViewRepresentable {
    @Binding var player: AVPlayer?

    func makeUIView(context: Context) -> PlayerUIView { PlayerUIView() }

    func updateUIView(_ uiView: PlayerUIView, context: Context) {
        uiView.playerLayer.player = player
    }
}

final class PlayerUIView: UIView {
    let playerLayer = AVPlayerLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        playerLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(playerLayer)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
}
