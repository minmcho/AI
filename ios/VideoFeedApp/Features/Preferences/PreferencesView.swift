import SwiftUI

/// Full user preferences screen: music genres/moods, video types,
/// countries, social platforms, and feed settings.
struct PreferencesView: View {
    @Bindable var store: PreferencesStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {

                        // ── Social Platforms ──────────────────────────────────
                        PrefsSection(title: "Platforms", icon: "antenna.radiowaves.left.and.right", accent: .cyan) {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                ForEach(SocialPlatform.allCases) { platform in
                                    PlatformToggleCard(
                                        platform: platform,
                                        isOn: store.preferences.platforms.contains(platform)
                                    ) { store.toggle(platform: platform) }
                                }
                            }
                        }

                        // ── Countries ─────────────────────────────────────────
                        PrefsSection(title: "Countries", icon: "globe", accent: .blue) {
                            if store.options.countries.isEmpty {
                                ProgressView().tint(.blue)
                            } else {
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                                    ForEach(store.options.countries) { country in
                                        CountryCard(
                                            country: country,
                                            isSelected: store.preferences.countries.contains(country.code)
                                        ) { store.toggle(country: country.code) }
                                    }
                                }
                            }
                        }

                        // ── Music Genres ──────────────────────────────────────
                        PrefsSection(title: "Music Genres", icon: "music.note", accent: .purple) {
                            FlowLayout(spacing: 8) {
                                ForEach(store.options.musicGenres, id: \.self) { genre in
                                    TagToggle(
                                        label: genre.capitalized,
                                        isSelected: store.preferences.musicGenres.contains(genre),
                                        color: .purple
                                    ) { store.toggle(genre: genre) }
                                }
                            }
                        }

                        // ── Music Moods ───────────────────────────────────────
                        PrefsSection(title: "Music Moods", icon: "waveform.path.ecg", accent: .indigo) {
                            FlowLayout(spacing: 8) {
                                ForEach(store.options.musicMoods, id: \.self) { mood in
                                    TagToggle(
                                        label: mood.capitalized,
                                        isSelected: store.preferences.musicMoods.contains(mood),
                                        color: .indigo
                                    ) { store.toggle(mood: mood) }
                                }
                            }
                        }

                        // ── Video Types ───────────────────────────────────────
                        PrefsSection(title: "Video Types", icon: "video.fill", accent: .orange) {
                            FlowLayout(spacing: 8) {
                                ForEach(store.options.videoTypes, id: \.self) { type in
                                    TagToggle(
                                        label: type.capitalized,
                                        isSelected: store.preferences.videoTypes.contains(type),
                                        color: .orange
                                    ) { store.toggle(videoType: type) }
                                }
                            }
                        }

                        // ── Feed Settings ─────────────────────────────────────
                        PrefsSection(title: "Feed Settings", icon: "gearshape.fill", accent: .gray) {
                            VStack(spacing: 0) {
                                SettingsToggleRow(
                                    label: "Prefer Dubbed Videos",
                                    description: "Show AI-dubbed videos in your preferred language",
                                    icon: "person.wave.2.fill",
                                    isOn: $store.preferences.preferDubbed
                                )
                                Divider().overlay(.white.opacity(0.1))
                                SettingsToggleRow(
                                    label: "Always Show Subtitles",
                                    description: "Display subtitles on all videos",
                                    icon: "captions.bubble.fill",
                                    isOn: $store.preferences.preferSubtitles
                                )
                                Divider().overlay(.white.opacity(0.1))
                                SettingsToggleRow(
                                    label: "Autoplay Muted",
                                    description: "Videos start muted in the feed",
                                    icon: "speaker.slash.fill",
                                    isOn: $store.preferences.autoplayMuted
                                )
                            }
                        }

                        // Save button
                        PrimaryButton(
                            label: store.isSaving ? "Saving..." : "Save Preferences",
                            icon: store.isSaving ? "hourglass" : "checkmark.circle.fill",
                            color: .cyan
                        ) {
                            Task { await store.save() }
                        }
                        .disabled(store.isSaving)
                        .padding(.top, 4)
                    }
                    .padding()
                }
            }
            .navigationTitle("Preferences")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
        .task { await store.load() }
    }
}

// MARK: - Sub-components

struct PrefsSection<Content: View>: View {
    let title: String
    let icon: String
    let accent: Color
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(title, systemImage: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(accent)
            content
        }
        .padding(16)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(accent.opacity(0.15), lineWidth: 1))
    }
}

struct PlatformToggleCard: View {
    let platform: SocialPlatform
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: platform.icon)
                    .font(.system(size: 18))
                    .foregroundStyle(isOn ? .white : .secondary)
                Text(platform.label)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isOn ? .white : .secondary)
                Spacer()
                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isOn ? .cyan : .secondary)
            }
            .padding(12)
            .background(isOn ? Color.white.opacity(0.12) : Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(isOn ? Color.cyan.opacity(0.4) : .clear, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

struct CountryCard: View {
    let country: CountryOption
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(country.flag)
                    .font(.title2)
                Text(country.code)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(isSelected ? .white : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isSelected ? Color.blue.opacity(0.3) : Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(isSelected ? Color.blue : .clear, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
    }
}

struct TagToggle: View {
    let label: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? color.opacity(0.3) : Color.white.opacity(0.07))
                .foregroundStyle(isSelected ? color : .secondary)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(isSelected ? color.opacity(0.6) : .clear, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

struct SettingsToggleRow: View {
    let label: String
    let description: String
    let icon: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(.secondary)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: .cyan))
                .labelsHidden()
        }
        .padding(.vertical, 10)
    }
}

// MARK: - FlowLayout (wrapping tag cloud)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var x: CGFloat = 0, y: CGFloat = 0, rowH: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 { y += rowH + spacing; x = 0; rowH = 0 }
            x += size.width + spacing
            rowH = max(rowH, size.height)
        }
        return CGSize(width: width, height: y + rowH)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowH: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX { y += rowH + spacing; x = bounds.minX; rowH = 0 }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowH = max(rowH, size.height)
        }
    }
}
