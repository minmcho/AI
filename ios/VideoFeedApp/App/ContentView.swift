import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedTab: Tab = .feed
    @State private var preferencesStore = PreferencesStore(profileID: "demo")

    var body: some View {
        TabView(selection: $selectedTab) {
            // ── Feed (with Mood selector + Study Mode overlay) ────────────────
            VideoFeedView()
                .tabItem { Label("Feed", systemImage: "play.rectangle.fill") }
                .tag(Tab.feed)

            // ── Search (cross-platform: YouTube, Spotify, SoundCloud…) ────────
            SearchView()
                .tabItem { Label("Search", systemImage: "magnifyingglass") }
                .tag(Tab.search)

            // ── Challenge Hub (viral challenges + leaderboards) ───────────────
            ChallengeHubView()
                .tabItem { Label("Challenges", systemImage: "trophy.fill") }
                .tag(Tab.challenges)

            // ── Vibe Match (find taste twins via pgvector) ────────────────────
            VibeMatchView()
                .tabItem { Label("Vibe", systemImage: "person.2.wave.2.fill") }
                .tag(Tab.vibeMatch)

            // ── Myanmar Translator ────────────────────────────────────────────
            TranslationView()
                .tabItem { Label("Translate", systemImage: "character.bubble.fill") }
                .tag(Tab.translate)

            // ── Profile (streak, XP, badges, favorites, preferences) ──────────
            ProfileHubView(preferencesStore: preferencesStore)
                .tabItem { Label("Me", systemImage: "person.circle.fill") }
                .tag(Tab.profile)
        }
        .tint(.cyan)
    }

    enum Tab { case feed, search, challenges, vibeMatch, translate, profile }
}

// MARK: - Profile Hub (combines Profile + Streak + Favorites + Preferences)

struct ProfileHubView: View {
    let preferencesStore: PreferencesStore
    @State private var selectedSection: ProfileSection = .streak

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 0) {
                    // Section picker
                    Picker("Section", selection: $selectedSection) {
                        ForEach(ProfileSection.allCases) { s in
                            Label(s.label, systemImage: s.icon).tag(s)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding()

                    // Content
                    switch selectedSection {
                    case .streak:  StreakView()
                    case .favorites: FavoritesView()
                    case .preferences: PreferencesView(store: preferencesStore)
                    case .profile: ProfileView()
                    }
                }
            }
            .navigationTitle("My Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }

    enum ProfileSection: String, CaseIterable, Identifiable {
        case streak, favorites, preferences, profile
        var id: String { rawValue }
        var label: String {
            switch self {
            case .streak: return "Streak"
            case .favorites: return "Saved"
            case .preferences: return "Prefs"
            case .profile: return "Profile"
            }
        }
        var icon: String {
            switch self {
            case .streak: return "flame.fill"
            case .favorites: return "heart.fill"
            case .preferences: return "slider.horizontal.3"
            case .profile: return "person.fill"
            }
        }
    }
}
