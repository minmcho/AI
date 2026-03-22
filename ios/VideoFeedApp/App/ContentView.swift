import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedTab: Tab = .feed

    var body: some View {
        TabView(selection: $selectedTab) {
            VideoFeedView()
                .tabItem { Label("Feed", systemImage: "play.rectangle.fill") }
                .tag(Tab.feed)

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.circle.fill") }
                .tag(Tab.profile)
        }
        .tint(.white)
    }

    enum Tab { case feed, profile }
}
