import AVFoundation
import Combine

/// Wraps AVAudioEngine to provide real-time pitch/speed control and AutoMix crossfading.
@Observable
final class DJAudioEngine {
    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let mixPlayerNode = AVAudioPlayerNode()
    private let timePitchEffect = AVAudioUnitTimePitch()
    private let mainMixer = AVAudioMixerNode()

    var settings = DJSettings()

    init() {
        setupGraph()
    }

    // MARK: - Graph Setup

    private func setupGraph() {
        engine.attach(playerNode)
        engine.attach(mixPlayerNode)
        engine.attach(timePitchEffect)
        engine.attach(mainMixer)

        // Main video audio: player -> timePitch -> mainMixer -> output
        engine.connect(playerNode, to: timePitchEffect, format: nil)
        engine.connect(timePitchEffect, to: mainMixer, format: nil)

        // AutoMix track: mixPlayer -> mainMixer -> output
        engine.connect(mixPlayerNode, to: mainMixer, format: nil)
        engine.connect(mainMixer, to: engine.outputNode, format: nil)

        try? engine.start()
    }

    // MARK: - Playback Speed

    func setSpeed(_ speed: Float) {
        settings.playbackSpeed = speed
        timePitchEffect.rate = speed
        if settings.preservePitch {
            // Pitch stays constant; only tempo changes
            timePitchEffect.pitch = 0
        } else {
            // Vinyl effect: pitch shifts with rate (semitones = 12 * log2(rate))
            timePitchEffect.pitch = 1200 * log2(speed)
        }
    }

    func setPreservePitch(_ preserve: Bool) {
        settings.preservePitch = preserve
        setSpeed(settings.playbackSpeed)
    }

    // MARK: - AutoMix Crossfade

    func setAutoMix(enabled: Bool, mixVolume: Float = 0.5) {
        settings.autoMixEnabled = enabled
        settings.autoMixVolume = mixVolume
        applyVolumes()
    }

    func setMixVolume(_ volume: Float) {
        settings.autoMixVolume = volume
        applyVolumes()
    }

    private func applyVolumes() {
        playerNode.volume = settings.originalVolume
        mixPlayerNode.volume = settings.autoMixEnabled ? settings.autoMixVolume : 0
    }

    // MARK: - Mix Track Loading

    func loadMixTrack(url: URL) {
        guard let file = try? AVAudioFile(forReading: url) else { return }
        mixPlayerNode.scheduleFile(file, at: nil, completionHandler: nil)
        if settings.autoMixEnabled { mixPlayerNode.play() }
    }

    func stopMixTrack() {
        mixPlayerNode.stop()
    }

    // MARK: - Engine Lifecycle

    func start() { try? engine.start() }
    func stop() { engine.stop() }
}
