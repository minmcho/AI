// HomeViewModel.swift — VitalPath AI

import SwiftUI
import Combine

@MainActor
@Observable
final class HomeViewModel {

    // ── State ────────────────────────────────────────────────
    var profile: WellnessProfile = .empty
    var streakInfo: StreakInfo = StreakInfo(currentStreak: 0, longestStreak: 0, freezeAvailable: true)
    var wellnessScore: WellnessScore = WellnessScore(
        overall: 0,
        breakdown: WellnessBreakdown(nutrition: 0, exercise: 0, sleep: 0, mindfulness: 0, consistency: 0)
    )
    var recentSessions: [WellnessSession] = []
    var suggestedGoals: [AIGoalSuggestion] = []
    var greeting: String = "Good morning"
    var isLoading = false
    var error: String?

    private let client = GraphQLClient.shared

    // ── Load ─────────────────────────────────────────────────
    func loadDashboard() async {
        isLoading = true
        error = nil
        updateGreeting()

        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadProfile() }
            group.addTask { await self.loadStreak() }
            group.addTask { await self.loadWellnessScore() }
        }

        isLoading = false
    }

    private func loadProfile() async {
        do {
            struct ProfileData: Decodable { let myProfile: WellnessProfile }
            let data = try await client.execute(query: GQL.myProfile, type: ProfileData.self)
            profile = data.myProfile
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func loadStreak() async {
        do {
            struct StreakData: Decodable { let streakInfo: StreakInfo }
            let data = try await client.execute(query: GQL.streakInfo, type: StreakData.self)
            streakInfo = data.streakInfo
        } catch {}
    }

    private func loadWellnessScore() async {
        do {
            struct ScoreData: Decodable { let wellnessScore: WellnessScore }
            let data = try await client.execute(query: GQL.wellnessScore, type: ScoreData.self)
            withAnimation(AppAnimation.spring) { wellnessScore = data.wellnessScore }
        } catch {}
    }

    func freezeStreak() async {
        do {
            struct FreezeData: Decodable { let freezeStreak: StreakInfo }
            let data = try await client.execute(query: GQL.freezeStreak, type: FreezeData.self)
            withAnimation(AppAnimation.spring) { streakInfo = data.freezeStreak }
        } catch {
            self.error = error.localizedDescription
        }
    }

    // ── Helpers ──────────────────────────────────────────────
    private func updateGreeting() {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  greeting = "Good morning"
        case 12..<17: greeting = "Good afternoon"
        case 17..<21: greeting = "Good evening"
        default:      greeting = "Good night"
        }
    }

    var firstName: String {
        profile.displayName?.components(separatedBy: " ").first ?? "there"
    }

    var streakEmoji: String {
        switch streakInfo.currentStreak {
        case 0:     return "✨"
        case 1...3: return "🌱"
        case 4...7: return "🔥"
        case 8...14: return "⚡"
        case 15...30: return "💎"
        default:    return "🏆"
        }
    }
}
