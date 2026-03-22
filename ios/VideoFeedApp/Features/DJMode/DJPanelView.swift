import SwiftUI
import AVKit

/// DJ Mode panel — real-time playback speed, pitch preservation, and AutoMix crossfader.
struct DJPanelView: View {
    @Bindable var engine: DJAudioEngine  // @Bindable requires @Observable
    var player: AVPlayer?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        // Header waveform decoration
                        WaveformHeader(color: .cyan)

                        // Speed Control
                        SectionCard(title: "Playback Speed", icon: "speedometer", accent: .cyan) {
                            VStack(spacing: 12) {
                                HStack {
                                    Text("0.5×").font(.caption).foregroundStyle(.secondary)
                                    Spacer()
                                    Text("\(engine.settings.playbackSpeed, specifier: "%.2f")×")
                                        .font(.system(size: 22, weight: .bold, design: .rounded))
                                        .foregroundStyle(.cyan)
                                    Spacer()
                                    Text("2.0×").font(.caption).foregroundStyle(.secondary)
                                }
                                Slider(value: Binding(
                                    get: { Double(engine.settings.playbackSpeed) },
                                    set: {
                                        engine.setSpeed(Float($0))
                                        player?.rate = Float($0)
                                    }
                                ), in: 0.5...2.0, step: 0.05)
                                .tint(.cyan)

                                // Quick speed presets
                                HStack(spacing: 12) {
                                    ForEach([0.75, 1.0, 1.25, 1.5, 2.0], id: \.self) { speed in
                                        SpeedChip(
                                            label: "\(speed)×",
                                            isSelected: abs(Double(engine.settings.playbackSpeed) - speed) < 0.01
                                        ) {
                                            engine.setSpeed(Float(speed))
                                            player?.rate = Float(speed)
                                        }
                                    }
                                }
                            }
                        }

                        // Pitch Toggle
                        SectionCard(title: "Pitch Mode", icon: "waveform.path", accent: .purple) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(engine.settings.preservePitch ? "Preserved" : "Vinyl Effect")
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundStyle(.white)
                                    Text(engine.settings.preservePitch
                                         ? "Tempo changes, pitch stays constant"
                                         : "Pitch shifts with speed — classic vinyl feel")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Toggle("", isOn: Binding(
                                    get: { engine.settings.preservePitch },
                                    set: { engine.setPreservePitch($0) }
                                ))
                                .toggleStyle(SwitchToggleStyle(tint: .purple))
                                .labelsHidden()
                            }
                        }

                        // AutoMix Crossfader
                        SectionCard(title: "AutoMix", icon: "music.note.list", accent: .orange) {
                            VStack(spacing: 16) {
                                HStack {
                                    Text("Enable AutoMix")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundStyle(.white)
                                    Spacer()
                                    Toggle("", isOn: Binding(
                                        get: { engine.settings.autoMixEnabled },
                                        set: { engine.setAutoMix(enabled: $0) }
                                    ))
                                    .toggleStyle(SwitchToggleStyle(tint: .orange))
                                    .labelsHidden()
                                }

                                if engine.settings.autoMixEnabled {
                                    VStack(spacing: 8) {
                                        CrossfaderView(value: Binding(
                                            get: { Double(engine.settings.autoMixVolume) },
                                            set: { engine.setMixVolume(Float($0)) }
                                        ))
                                        HStack {
                                            Label("Original", systemImage: "video.fill")
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                            Spacer()
                                            Label("Mix Track", systemImage: "music.note")
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .transition(.move(edge: .top).combined(with: .opacity))
                                }
                            }
                            .animation(.spring(duration: 0.3), value: engine.settings.autoMixEnabled)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("DJ Mode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Sub-components

struct WaveformHeader: View {
    let color: Color
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<24, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(color.opacity(0.6 + 0.4 * sin(Double(i) * 0.6)))
                    .frame(width: 5, height: CGFloat.random(in: 12...40))
            }
        }
        .frame(height: 44)
    }
}

struct SectionCard<Content: View>: View {
    let title: String
    let icon: String
    let accent: Color
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label(title, systemImage: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(accent)
            content
        }
        .padding(16)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(accent.opacity(0.2), lineWidth: 1))
    }
}

struct SpeedChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.cyan : Color.white.opacity(0.1))
                .foregroundStyle(isSelected ? .black : .white)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct CrossfaderView: View {
    @Binding var value: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.white.opacity(0.1))
                    .frame(height: 8)

                Capsule()
                    .fill(LinearGradient(
                        colors: [.blue, .orange],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .frame(width: geo.size.width * value, height: 8)

                Circle()
                    .fill(.white)
                    .frame(width: 24, height: 24)
                    .shadow(radius: 4)
                    .offset(x: geo.size.width * value - 12)
                    .gesture(DragGesture().onChanged { drag in
                        value = max(0, min(1, drag.location.x / geo.size.width))
                    })
            }
        }
        .frame(height: 24)
    }
}
