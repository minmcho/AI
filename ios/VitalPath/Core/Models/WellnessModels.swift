// WellnessModels.swift — VitalPath AI
// Domain models used across the app (mirrors backend GraphQL types).

import Foundation

// MARK: - Enums

enum SessionType: String, Codable, CaseIterable {
    case chat            = "chat"
    case videoAnalysis   = "video_analysis"
    case habitLog        = "habit_log"
    case mindfulness     = "mindfulness"

    var displayName: String {
        switch self {
        case .chat:          return "Coaching Chat"
        case .videoAnalysis: return "Video Analysis"
        case .habitLog:      return "Habit Log"
        case .mindfulness:   return "Mindfulness"
        }
    }

    var icon: String {
        switch self {
        case .chat:          return "bubble.left.and.bubble.right.fill"
        case .videoAnalysis: return "camera.fill"
        case .habitLog:      return "checkmark.circle.fill"
        case .mindfulness:   return "leaf.fill"
        }
    }
}

enum GoalCategory: String, Codable, CaseIterable {
    case nutrition   = "nutrition"
    case exercise    = "exercise"
    case sleep       = "sleep"
    case mindfulness = "mindfulness"
    case hydration   = "hydration"
    case stress      = "stress"

    var displayName: String { rawValue.capitalized }
    var icon: String {
        switch self {
        case .nutrition:   return "fork.knife"
        case .exercise:    return "figure.run"
        case .sleep:       return "moon.fill"
        case .mindfulness: return "leaf.fill"
        case .hydration:   return "drop.fill"
        case .stress:      return "brain.head.profile"
        }
    }
    var color: String {
        switch self {
        case .nutrition:   return "vitaTeal"
        case .exercise:    return "vitaCoral"
        case .sleep:       return "vitaIndigo"
        case .mindfulness: return "vitaMint"
        case .hydration:   return "vitaLavender"
        case .stress:      return "vitaGold"
        }
    }
}

enum ResponseType: String, Codable {
    case wellness = "wellness"
    case crisis   = "crisis"
    case fallback = "fallback"
}

// MARK: - User Profile

struct WellnessProfile: Codable, Identifiable, Equatable {
    let id: String
    var displayName: String?
    var avatarURL: String?
    var preferredLanguage: String
    var dietaryPreferences: [String]
    var healthNotes: [String]
    var wellnessGoals: [String]
    var currentStreak: Int
    var longestStreak: Int
    var totalSessions: Int
    var wellnessScore: Double
    var createdAt: Date

    static var empty: WellnessProfile {
        WellnessProfile(
            id: UUID().uuidString,
            displayName: nil,
            avatarURL: nil,
            preferredLanguage: "en",
            dietaryPreferences: [],
            healthNotes: [],
            wellnessGoals: [],
            currentStreak: 0,
            longestStreak: 0,
            totalSessions: 0,
            wellnessScore: 0.0,
            createdAt: Date()
        )
    }
}

// MARK: - Chat

struct ChatMessage: Identifiable, Equatable {
    let id: UUID
    let role: MessageRole
    var content: String
    let timestamp: Date
    var isAnimating: Bool = false

    enum MessageRole: String, Codable {
        case user      = "user"
        case assistant = "assistant"
    }

    static func userMessage(_ text: String) -> ChatMessage {
        ChatMessage(id: UUID(), role: .user, content: text, timestamp: Date())
    }

    static func assistantMessage(_ text: String) -> ChatMessage {
        ChatMessage(id: UUID(), role: .assistant, content: text, timestamp: Date())
    }
}

struct ChatResponse: Codable {
    let sessionId: String
    let responseType: ResponseType
    let message: String?
    let intent: String
    let safetyIntercepted: Bool
    let crisisResources: CrisisResourceModel?
}

struct CrisisResourceModel: Codable, Equatable {
    let country: String
    let hotline: String
    let name: String
    let url: String?
}

// MARK: - Sessions

struct WellnessSession: Codable, Identifiable, Equatable {
    let id: String
    let sessionType: SessionType
    var title: String?
    var summary: String?
    var aiModelUsed: String?
    var intentDetected: String?
    var languageDetected: String
    var moodBefore: Int?
    var moodAfter: Int?
    var durationSeconds: Int
    var flaggedForReview: Bool
    var safetyIntercepted: Bool
    var createdAt: Date
    var completedAt: Date?
}

// MARK: - Goals

struct WellnessGoal: Codable, Identifiable, Equatable {
    let id: String
    var category: GoalCategory
    var title: String
    var description: String?
    var targetValue: Double?
    var currentValue: Double
    var unit: String?
    var aiSuggested: Bool
    var isActive: Bool
    var targetDate: Date?
    var completedAt: Date?
    var createdAt: Date

    var progress: Double {
        guard let target = targetValue, target > 0 else { return 0 }
        return min(currentValue / target, 1.0)
    }

    var isCompleted: Bool { completedAt != nil }
}

struct AIGoalSuggestion: Codable, Identifiable {
    var id = UUID()
    let category: GoalCategory
    let title: String
    let rationale: String
    let targetValue: Double?
    let unit: String?
}

// MARK: - Wearable / HealthKit

struct WearableData: Codable, Equatable {
    let platform: String
    var isConnected: Bool
    var dailySteps: Int
    var restingHeartRate: Double?
    var sleepHours: Double?
    var activeCalories: Int
    var hrvMs: Double?
    var lastSyncedAt: Date?
}

// MARK: - Streak

struct StreakInfo: Codable, Equatable {
    var currentStreak: Int
    var longestStreak: Int
    var freezeAvailable: Bool
    var lastSessionAt: Date?
}

// MARK: - Wellness Score

struct WellnessScore: Codable, Equatable {
    var overall: Double
    var breakdown: WellnessBreakdown
}

struct WellnessBreakdown: Codable, Equatable {
    var nutrition: Double
    var exercise: Double
    var sleep: Double
    var mindfulness: Double
    var consistency: Double
}

// MARK: - Video Analysis

struct VideoAnalysisResult: Codable, Equatable {
    let taskId: String
    var status: AnalysisStatus
    var feedback: String?
    var nutritionEstimate: String?
    var formNotes: String?
    var safetyFlag: Bool

    enum AnalysisStatus: String, Codable {
        case pending    = "pending"
        case processing = "processing"
        case completed  = "completed"
        case failed     = "failed"

        var displayText: String {
            switch self {
            case .pending:    return "Uploading…"
            case .processing: return "Analyzing with AI…"
            case .completed:  return "Analysis Complete"
            case .failed:     return "Analysis Failed"
            }
        }

        var icon: String {
            switch self {
            case .pending:    return "arrow.up.circle"
            case .processing: return "brain"
            case .completed:  return "checkmark.circle.fill"
            case .failed:     return "xmark.circle.fill"
            }
        }
    }
}

// MARK: - Habit log

struct HabitLog: Codable {
    let category: GoalCategory
    let value: Double
    let unit: String
    var notes: String?
    var moodRating: Int?
    let loggedAt: Date
}

// MARK: - Language

enum AppLanguage: String, CaseIterable, Codable {
    case en = "en"
    case my = "my"
    case th = "th"
    case zh = "zh"
    case ja = "ja"
    case ko = "ko"

    var displayName: String {
        switch self {
        case .en: return "English"
        case .my: return "မြန်မာ"
        case .th: return "ภาษาไทย"
        case .zh: return "中文"
        case .ja: return "日本語"
        case .ko: return "한국어"
        }
    }

    var flag: String {
        switch self {
        case .en: return "🇺🇸"
        case .my: return "🇲🇲"
        case .th: return "🇹🇭"
        case .zh: return "🇨🇳"
        case .ja: return "🇯🇵"
        case .ko: return "🇰🇷"
        }
    }
}
