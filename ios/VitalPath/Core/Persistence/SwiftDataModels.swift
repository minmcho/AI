// SwiftDataModels.swift — VitalPath AI
// SwiftData schema for offline-first local persistence.
// Syncs to Supabase/Backend when network available.

import SwiftData
import Foundation

// MARK: - Local Wellness Profile

@Model
final class LocalWellnessProfile {
    @Attribute(.unique) var id: String
    var supabaseUID: String
    var displayName: String?
    var avatarURL: String?
    var preferredLanguage: String

    var dietaryPreferences: [String]
    var healthNotes: [String]
    var wellnessGoals: [String]
    var preferredSessionTime: String?

    var currentStreak: Int
    var longestStreak: Int
    var freezeStreakUsedThisMonth: Bool
    var totalSessions: Int
    var wellnessScore: Double

    var createdAt: Date
    var updatedAt: Date
    var lastSyncedAt: Date?

    // Relationships
    @Relationship(deleteRule: .cascade)
    var sessions: [LocalWellnessSession]

    @Relationship(deleteRule: .cascade)
    var goals: [LocalWellnessGoal]

    init(
        id: String = UUID().uuidString,
        supabaseUID: String,
        displayName: String? = nil,
        preferredLanguage: String = "en"
    ) {
        self.id = id
        self.supabaseUID = supabaseUID
        self.displayName = displayName
        self.preferredLanguage = preferredLanguage
        self.dietaryPreferences = []
        self.healthNotes = []
        self.wellnessGoals = []
        self.currentStreak = 0
        self.longestStreak = 0
        self.freezeStreakUsedThisMonth = false
        self.totalSessions = 0
        self.wellnessScore = 0.0
        self.sessions = []
        self.goals = []
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Local Session

@Model
final class LocalWellnessSession {
    @Attribute(.unique) var id: String
    var profileId: String
    var sessionType: String            // "chat" | "video_analysis" | "habit_log" | "mindfulness"
    var title: String?
    var summary: String?

    // Stored as JSON string for flexibility
    var messagesJSON: String
    var aiModelUsed: String?
    var intentDetected: String?
    var languageDetected: String

    // Video
    var videoURL: String?
    var videoAnalysisResultJSON: String?

    // Metrics
    var moodBefore: Int?
    var moodAfter: Int?
    var energyLevel: Int?
    var stressLevel: Int?
    var durationSeconds: Int

    // Flags
    var flaggedForReview: Bool
    var safetyIntercepted: Bool
    var isSynced: Bool

    var createdAt: Date
    var completedAt: Date?

    init(
        id: String = UUID().uuidString,
        profileId: String,
        sessionType: String,
        title: String? = nil
    ) {
        self.id = id
        self.profileId = profileId
        self.sessionType = sessionType
        self.title = title
        self.messagesJSON = "[]"
        self.languageDetected = "en"
        self.durationSeconds = 0
        self.flaggedForReview = false
        self.safetyIntercepted = false
        self.isSynced = false
        self.createdAt = Date()
    }

    // Computed: decode messages from JSON
    var messages: [[String: String]] {
        get {
            guard let data = messagesJSON.data(using: .utf8),
                  let decoded = try? JSONDecoder().decode([[String: String]].self, from: data)
            else { return [] }
            return decoded
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
               let str = String(data: data, encoding: .utf8) {
                messagesJSON = str
            }
        }
    }
}

// MARK: - Local Goal

@Model
final class LocalWellnessGoal {
    @Attribute(.unique) var id: String
    var profileId: String
    var category: String              // GoalCategory.rawValue
    var title: String
    var goalDescription: String?
    var targetValue: Double?
    var currentValue: Double
    var unit: String?
    var aiSuggested: Bool
    var isActive: Bool
    var isSynced: Bool
    var targetDate: Date?
    var completedAt: Date?
    var createdAt: Date

    init(
        id: String = UUID().uuidString,
        profileId: String,
        category: String,
        title: String
    ) {
        self.id = id
        self.profileId = profileId
        self.category = category
        self.title = title
        self.currentValue = 0.0
        self.aiSuggested = false
        self.isActive = true
        self.isSynced = false
        self.createdAt = Date()
    }

    var progress: Double {
        guard let target = targetValue, target > 0 else { return 0 }
        return min(currentValue / target, 1.0)
    }
}

// MARK: - Offline Chat Draft

@Model
final class OfflineChatDraft {
    @Attribute(.unique) var id: String
    var profileId: String
    var message: String
    var sessionId: String?
    var language: String
    var createdAt: Date
    var retryCount: Int

    init(profileId: String, message: String, language: String = "en") {
        self.id = UUID().uuidString
        self.profileId = profileId
        self.message = message
        self.language = language
        self.createdAt = Date()
        self.retryCount = 0
    }
}

// MARK: - Schema

struct VitalPathSchema: PersistentModel {
    static var schema: Schema {
        Schema([
            LocalWellnessProfile.self,
            LocalWellnessSession.self,
            LocalWellnessGoal.self,
            OfflineChatDraft.self,
        ])
    }

    static var modelContainer: ModelContainer {
        let config = ModelConfiguration(
            "VitalPathDB",
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )
        do {
            return try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("Failed to create SwiftData container: \(error)")
        }
    }
}

// MARK: - Sync helper extensions

extension LocalWellnessProfile {
    func toDomainModel() -> WellnessProfile {
        WellnessProfile(
            id: id,
            displayName: displayName,
            avatarURL: avatarURL,
            preferredLanguage: preferredLanguage,
            dietaryPreferences: dietaryPreferences,
            healthNotes: healthNotes,
            wellnessGoals: wellnessGoals,
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            totalSessions: totalSessions,
            wellnessScore: wellnessScore,
            createdAt: createdAt
        )
    }
}
