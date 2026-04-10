// VitalPathApp.swift — VitalPath AI
// Root app entry point. Sets up SwiftData container, auth, and navigation.

import SwiftUI
import SwiftData

@main
struct VitalPathApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .modelContainer(VitalPathSchema.modelContainer)
                .preferredColorScheme(.dark)
                .tint(.vitaTeal)
        }
    }
}

// MARK: - App State

@MainActor
final class AppState: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUserId: String?
    @Published var profile: WellnessProfile?
    @Published var selectedTab: Tab = .home
    @Published var showCrisisModal = false
    @Published var crisisResource: CrisisResource?
    @Published var networkAvailable = true

    enum Tab: Int, CaseIterable {
        case home, chat, video, sessions, profile

        var title: String {
            switch self {
            case .home:     return "Home"
            case .chat:     return "Coach"
            case .video:    return "Analyze"
            case .sessions: return "Progress"
            case .profile:  return "Profile"
            }
        }

        var icon: String {
            switch self {
            case .home:     return "house.fill"
            case .chat:     return "bubble.left.and.bubble.right.fill"
            case .video:    return "camera.fill"
            case .sessions: return "chart.bar.fill"
            case .profile:  return "person.crop.circle.fill"
            }
        }
    }

    func triggerCrisis(resource: CrisisResource) {
        crisisResource = resource
        showCrisisModal = true
    }

    func setAuthenticated(userId: String, token: String) {
        currentUserId = userId
        GraphQLClient.shared.authToken = token
        GraphQLClient.shared.userId = userId
        withAnimation(AppAnimation.smooth) { isAuthenticated = true }
    }

    func signOut() {
        currentUserId = nil
        profile = nil
        GraphQLClient.shared.authToken = nil
        GraphQLClient.shared.userId = nil
        withAnimation(AppAnimation.smooth) { isAuthenticated = false }
    }
}

// MARK: - Content View (Router)

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            if appState.isAuthenticated {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .overlay {
            if appState.showCrisisModal, let resource = appState.crisisResource {
                CrisisModal(
                    isPresented: $appState.showCrisisModal,
                    resource: resource
                )
                .transition(.opacity)
                .zIndex(999)
            }
        }
        .animation(AppAnimation.smooth, value: appState.isAuthenticated)
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @State private var tabBarOpacity: Double = 0

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            HomeView()
                .tag(AppState.Tab.home)
                .tabItem { Label("Home", systemImage: "house.fill") }

            ChatView()
                .tag(AppState.Tab.chat)
                .tabItem { Label("Coach", systemImage: "bubble.left.and.bubble.right.fill") }

            VideoAnalysisView()
                .tag(AppState.Tab.video)
                .tabItem { Label("Analyze", systemImage: "camera.fill") }

            SessionsView()
                .tag(AppState.Tab.sessions)
                .tabItem { Label("Progress", systemImage: "chart.bar.fill") }

            ProfileView()
                .tag(AppState.Tab.profile)
                .tabItem { Label("Profile", systemImage: "person.crop.circle.fill") }
        }
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .tint(.vitaTeal)
    }
}

// MARK: - Onboarding (placeholder)

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var appear = false

    var body: some View {
        ZStack {
            AnimatedMeshBackground()
            VStack(spacing: AppSpacing.xl) {
                Spacer()
                // Logo
                VStack(spacing: AppSpacing.md) {
                    ZStack {
                        Circle()
                            .fill(AppGradient.primaryButton)
                            .frame(width: 100, height: 100)
                            .shadow(color: .vitaPurple.opacity(0.5), radius: 30, x: 0, y: 10)
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .scaleEffect(appear ? 1 : 0.5)
                    .opacity(appear ? 1 : 0)

                    Text("VitalPath AI")
                        .font(AppFont.display(38))
                        .foregroundStyle(.white)
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear ? 0 : 20)

                    Text("Wellness, Not Medicine.")
                        .font(AppFont.body(18))
                        .foregroundStyle(.vitaTeal)
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear ? 0 : 10)
                }

                Spacer()

                // Sign in (demo — wire to Supabase Auth in production)
                VStack(spacing: AppSpacing.md) {
                    PrimaryGlassButton(title: "Get Started", icon: "arrow.right.circle.fill") {
                        // Demo auth — replace with Supabase sign-in flow
                        appState.setAuthenticated(userId: "demo-user-001", token: "demo-token")
                    }
                    Text("By continuing, you agree to our Wellness Terms.\nThis app is not a medical service.")
                        .font(AppFont.caption(11))
                        .foregroundStyle(.white.opacity(0.45))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, AppSpacing.lg)
                .opacity(appear ? 1 : 0)
                .offset(y: appear ? 0 : 30)

                Spacer().frame(height: AppSpacing.xxl)
            }
        }
        .onAppear {
            withAnimation(AppAnimation.entrance.delay(0.3)) { appear = true }
        }
    }
}
