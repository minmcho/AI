import SwiftUI
import Combine

@main
struct HealthRashAIApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var themeManager = ThemeManager()

    init() {
        setupAppearance()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(themeManager)
                .preferredColorScheme(.light)
        }
    }

    private func setupAppearance() {
        // Navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.theme.primary)
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 18, weight: .semibold)
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().tintColor = .white

        // Tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor.systemBackground
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
}

// MARK: - App State
class AppState: ObservableObject {
    @Published var selectedLanguage: Language = .spanish
    @Published var hasSeenOnboarding: Bool = false
    @Published var isProcessing: Bool = false

    enum Language: String, CaseIterable, Identifiable {
        case spanish = "es"
        case burmese = "my"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .spanish: return "Español"
            case .burmese: return "မြန်မာဘာသာ"
            }
        }

        var englishName: String {
            switch self {
            case .spanish: return "Spanish"
            case .burmese: return "Burmese"
            }
        }

        var flag: String {
            switch self {
            case .spanish: return "🇪🇸"
            case .burmese: return "🇲🇲"
            }
        }

        var locale: String {
            switch self {
            case .spanish: return "es-ES"
            case .burmese: return "my-MM"
            }
        }
    }
}

// MARK: - Theme Manager
class ThemeManager: ObservableObject {
    @Published var currentTheme: Theme = .medical

    enum Theme {
        case medical
        case modern
        case accessible
    }
}

// MARK: - Color Extension
extension Color {
    static let theme = ColorTheme()
}

struct ColorTheme {
    // Primary colors
    let primary = Color(red: 0.15, green: 0.39, blue: 0.92) // Medical Blue
    let primaryLight = Color(red: 0.37, green: 0.58, blue: 0.95)
    let primaryDark = Color(red: 0.09, green: 0.24, blue: 0.55)

    // Secondary colors
    let secondary = Color(red: 0.09, green: 0.64, blue: 0.29) // Medical Green
    let secondaryLight = Color(red: 0.53, green: 0.94, blue: 0.67)
    let secondaryDark = Color(red: 0.05, green: 0.39, blue: 0.18)

    // Accent colors
    let accent = Color(red: 0.96, green: 0.62, blue: 0.04) // Warning Orange
    let accentLight = Color(red: 0.99, green: 0.91, blue: 0.54)

    // Status colors
    let success = Color(red: 0.09, green: 0.64, blue: 0.29)
    let warning = Color(red: 0.96, green: 0.62, blue: 0.04)
    let danger = Color(red: 0.94, green: 0.26, blue: 0.26)
    let info = Color(red: 0.15, green: 0.39, blue: 0.92)

    // Neutral colors
    let background = Color(UIColor.systemGroupedBackground)
    let surface = Color(UIColor.systemBackground)
    let cardBackground = Color.white

    // Text colors
    let textPrimary = Color(UIColor.label)
    let textSecondary = Color(UIColor.secondaryLabel)
    let textTertiary = Color(UIColor.tertiaryLabel)

    // Gradients
    var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [primary, primaryLight],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var successGradient: LinearGradient {
        LinearGradient(
            colors: [secondary, secondaryLight],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var warningGradient: LinearGradient {
        LinearGradient(
            colors: [accent, accentLight],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var heroGradient: LinearGradient {
        LinearGradient(
            colors: [primary, primaryLight, Color.white.opacity(0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
