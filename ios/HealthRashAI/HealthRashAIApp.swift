import SwiftUI

@main
struct HealthRashAIApp: App {
    @StateObject private var appState = AppState()

    init() {
        // Configure appearance
        configureAppearance()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .preferredColorScheme(.light)
        }
    }

    private func configureAppearance() {
        // Configure navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 0.15, green: 0.39, blue: 0.92, alpha: 1.0)
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().tintColor = .white
    }
}

// MARK: - App State
class AppState: ObservableObject {
    @Published var selectedLanguage: Language = .spanish
    @Published var hasSeenOnboarding: Bool = false

    enum Language: String, CaseIterable {
        case spanish = "es"
        case burmese = "my"

        var displayName: String {
            switch self {
            case .spanish: return "Español"
            case .burmese: return "မြန်မာဘာသာ"
            }
        }

        var flag: String {
            switch self {
            case .spanish: return "🇪🇸"
            case .burmese: return "🇲🇲"
            }
        }
    }
}
