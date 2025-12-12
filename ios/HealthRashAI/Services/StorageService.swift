import Foundation
import CryptoKit

// MARK: - Storage Stats
struct StorageStats {
    let analysesCount: Int
    let storageUsed: String
}

// MARK: - Analysis Record
struct AnalysisRecord: Codable {
    let id: String
    let timestamp: Date
    let question: String
    let language: String
    let severity: String
    let response: String
    let careInstructions: [String]
    let seekMedicalAttention: Bool
}

class StorageService {
    static let shared = StorageService()

    private let userDefaults = UserDefaults.standard
    private let analysesKey = "saved_analyses"
    private let maxStoredAnalyses = 100

    private init() {}

    // MARK: - Save Analysis
    func saveAnalysis(question: String, language: String, result: AnalysisResult) {
        let record = AnalysisRecord(
            id: UUID().uuidString,
            timestamp: Date(),
            question: question,
            language: language,
            severity: result.severity,
            response: result.response,
            careInstructions: result.careInstructions,
            seekMedicalAttention: result.seekMedicalAttention
        )

        var analyses = getAnalyses()
        analyses.append(record)

        // Keep only last 100 analyses
        if analyses.count > maxStoredAnalyses {
            analyses = Array(analyses.suffix(maxStoredAnalyses))
        }

        saveAnalyses(analyses)
    }

    // MARK: - Get Analyses
    func getAnalyses() -> [AnalysisRecord] {
        guard let data = userDefaults.data(forKey: analysesKey),
              let analyses = try? JSONDecoder().decode([AnalysisRecord].self, from: data) else {
            return []
        }
        return analyses
    }

    // MARK: - Delete Analysis
    func deleteAnalysis(id: String) {
        var analyses = getAnalyses()
        analyses.removeAll { $0.id == id }
        saveAnalyses(analyses)
    }

    // MARK: - Clear All Data
    func clearAllData() {
        userDefaults.removeObject(forKey: analysesKey)
    }

    // MARK: - Get Storage Stats
    func getStorageStats() -> StorageStats {
        let analyses = getAnalyses()

        guard let data = userDefaults.data(forKey: analysesKey) else {
            return StorageStats(analysesCount: 0, storageUsed: "0 KB")
        }

        let bytes = data.count
        let kb = Double(bytes) / 1024.0
        let storageUsed = String(format: "%.2f KB", kb)

        return StorageStats(
            analysesCount: analyses.count,
            storageUsed: storageUsed
        )
    }

    // MARK: - Auto-delete old analyses
    func deleteOldAnalyses(olderThan days: Int) {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        var analyses = getAnalyses()
        analyses.removeAll { $0.timestamp < cutoffDate }
        saveAnalyses(analyses)
    }

    // MARK: - Private Helpers
    private func saveAnalyses(_ analyses: [AnalysisRecord]) {
        guard let data = try? JSONEncoder().encode(analyses) else { return }
        userDefaults.set(data, forKey: analysesKey)
    }
}
