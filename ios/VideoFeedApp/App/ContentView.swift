import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedTab: Tab = .feed
    @State private var preferencesStore = PreferencesStore(profileID: "demo")

    var body: some View {
        TabView(selection: $selectedTab) {
            // Feed
            VideoFeedView()
                .tabItem { Label("Feed", systemImage: "play.rectangle.fill") }
                .tag(Tab.feed)

            // Search
            SearchView()
                .tabItem { Label("Search", systemImage: "magnifyingglass") }
                .tag(Tab.search)

            // Favorites
            FavoritesView()
                .tabItem { Label("Favorites", systemImage: "heart.fill") }
                .tag(Tab.favorites)

            // Preferences
            PreferencesView(store: preferencesStore)
                .tabItem { Label("Preferences", systemImage: "slider.horizontal.3") }
                .tag(Tab.preferences)

            // Profile
            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.circle.fill") }
                .tag(Tab.profile)
        }
        .tint(.cyan)
    }

    enum Tab { case feed, search, favorites, preferences, profile }
}
