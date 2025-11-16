//
//  NutriVisionAIApp.swift
//  NutriVision AI
//
//  Main application entry point
//

import SwiftUI

@main
struct NutriVisionAIApp: App {
    @StateObject private var authViewModel = AuthenticationViewModel()
    @StateObject private var appState = AppState()

    init() {
        // Configure app appearance
        configureAppearance()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .environmentObject(appState)
                .preferredColorScheme(appState.colorScheme)
        }
    }

    private func configureAppearance() {
        // Configure navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance

        // Configure tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor.systemBackground

        UITabBar.appearance().standardAppearance = tabBarAppearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }
    }
}

// MARK: - App State

class AppState: ObservableObject {
    @Published var colorScheme: ColorScheme? = nil
    @Published var selectedLanguage: Language = .en
    @Published var showOnboarding: Bool

    init() {
        // Check if onboarding has been completed
        self.showOnboarding = !UserDefaults.standard.bool(forKey: Config.UserDefaultsKeys.isOnboardingComplete)

        // Load saved language preference
        if let languageCode = UserDefaults.standard.string(forKey: Config.UserDefaultsKeys.preferredLanguage),
           let language = Language(rawValue: languageCode) {
            self.selectedLanguage = language
        }
    }

    func completeOnboarding() {
        showOnboarding = false
        UserDefaults.standard.set(true, forKey: Config.UserDefaultsKeys.isOnboardingComplete)
    }

    func setLanguage(_ language: Language) {
        selectedLanguage = language
        UserDefaults.standard.set(language.rawValue, forKey: Config.UserDefaultsKeys.preferredLanguage)
    }
}

// MARK: - Content View

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            if appState.showOnboarding {
                OnboardingView()
            } else if authViewModel.isAuthenticated {
                MainTabView()
            } else {
                LoginView()
            }
        }
        .onAppear {
            authViewModel.checkAuthenticationStatus()
        }
    }
}
