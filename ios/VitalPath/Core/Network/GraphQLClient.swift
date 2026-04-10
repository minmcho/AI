// GraphQLClient.swift — VitalPath AI
// Custom async GraphQL client with:
//   - Exponential backoff retry (1s, 2s, 4s)
//   - Circuit breaker (5 consecutive failures → open)
//   - Supabase JWT auth injection
//   - Offline detection

import Foundation

// MARK: - Errors

enum GraphQLError: LocalizedError {
    case networkUnavailable
    case circuitOpen
    case httpError(Int)
    case graphqlErrors([String])
    case decodingError(Error)
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .networkUnavailable: return "No internet connection"
        case .circuitOpen:        return "Service temporarily unavailable. Please try again shortly."
        case .httpError(let c):   return "Server error (\(c))"
        case .graphqlErrors(let e): return e.joined(separator: "\n")
        case .decodingError(let e): return "Data error: \(e.localizedDescription)"
        case .unknown(let e):     return e.localizedDescription
        }
    }
}

// MARK: - Circuit Breaker State

private final class ClientCircuitBreaker {
    private(set) var state: CircuitState = .closed
    private var failureCount = 0
    private var lastFailureAt: Date?
    private let threshold: Int
    private let recoveryTimeout: TimeInterval

    enum CircuitState { case closed, open, halfOpen }

    init(threshold: Int = 5, recoveryTimeout: TimeInterval = 60) {
        self.threshold = threshold
        self.recoveryTimeout = recoveryTimeout
    }

    var isOpen: Bool {
        if state == .open {
            if let last = lastFailureAt, Date().timeIntervalSince(last) > recoveryTimeout {
                state = .halfOpen
                return false
            }
            return true
        }
        return false
    }

    func recordSuccess() {
        failureCount = 0
        state = .closed
    }

    func recordFailure() {
        failureCount += 1
        lastFailureAt = Date()
        if failureCount >= threshold { state = .open }
    }
}

// MARK: - GraphQL Response

private struct GraphQLResponse<T: Decodable>: Decodable {
    let data: T?
    let errors: [GraphQLErrorItem]?

    struct GraphQLErrorItem: Decodable {
        let message: String
    }
}

// MARK: - Client

@MainActor
final class GraphQLClient: ObservableObject {

    static let shared = GraphQLClient()

    private let baseURL: URL
    private let session: URLSession
    private let breaker = ClientCircuitBreaker(threshold: 5, recoveryTimeout: 60)
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    // Auth token provided by Supabase session
    var authToken: String?
    var userId: String?

    private init() {
        let urlString = Bundle.main.infoDictionary?["GRAPHQL_ENDPOINT"] as? String
            ?? "http://localhost:8000/graphql"
        self.baseURL = URL(string: urlString)!

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)

        self.decoder = JSONDecoder()
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder.dateDecodingStrategy = .iso8601

        self.encoder = JSONEncoder()
        self.encoder.keyEncodingStrategy = .convertToSnakeCase
    }

    // MARK: - Core request

    func execute<T: Decodable>(
        query: String,
        variables: [String: Any]? = nil,
        type: T.Type,
        retries: Int = 3
    ) async throws -> T {
        guard !breaker.isOpen else { throw GraphQLError.circuitOpen }

        var lastError: Error = GraphQLError.unknown(NSError(domain: "unknown", code: -1))

        for attempt in 0..<retries {
            do {
                let result = try await _performRequest(query: query, variables: variables, type: type)
                breaker.recordSuccess()
                return result
            } catch let error as GraphQLError {
                // GraphQL logical errors — don't retry
                if case .graphqlErrors = error {
                    breaker.recordSuccess() // Server responded, circuit stays closed
                    throw error
                }
                lastError = error
                breaker.recordFailure()
            } catch {
                lastError = error
                breaker.recordFailure()
            }

            if attempt < retries - 1 {
                let delay = pow(2.0, Double(attempt)) // 1s, 2s, 4s
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }

        throw lastError
    }

    // MARK: - Convenience: Mutation with named data key

    func mutation<T: Decodable>(
        _ gql: String,
        variables: [String: Any]? = nil,
        dataKey: String,
        returning type: T.Type
    ) async throws -> T {
        let wrapper = try await execute(
            query: gql,
            variables: variables,
            type: AnyDecodable.self
        )
        guard let dict = wrapper.value as? [String: Any],
              let target = dict[dataKey] else {
            throw GraphQLError.decodingError(NSError(domain: "missing key \(dataKey)", code: -2))
        }
        let data = try JSONSerialization.data(withJSONObject: target)
        return try decoder.decode(type, from: data)
    }

    // MARK: - Internal

    private func _performRequest<T: Decodable>(
        query: String,
        variables: [String: Any]?,
        type: T.Type
    ) async throws -> T {
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let uid = userId {
            request.setValue(uid, forHTTPHeaderField: "X-User-ID")
        }

        var body: [String: Any] = ["query": query]
        if let vars = variables { body["variables"] = vars }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        if let httpResponse = response as? HTTPURLResponse,
           !(200...299).contains(httpResponse.statusCode) {
            throw GraphQLError.httpError(httpResponse.statusCode)
        }

        // Decode wrapper
        struct DataWrapper<U: Decodable>: Decodable { let data: U? }
        struct ErrorsWrapper: Decodable { let errors: [GraphQLErrorItem]? }
        struct GraphQLErrorItem: Decodable { let message: String }

        // Check for GraphQL errors first
        if let errWrapper = try? decoder.decode(ErrorsWrapper.self, from: data),
           let errors = errWrapper.errors, !errors.isEmpty {
            throw GraphQLError.graphqlErrors(errors.map(\.message))
        }

        do {
            let wrapper = try decoder.decode(DataWrapper<T>.self, from: data)
            guard let result = wrapper.data else {
                throw GraphQLError.decodingError(NSError(domain: "nil data", code: -3))
            }
            return result
        } catch {
            throw GraphQLError.decodingError(error)
        }
    }
}

// MARK: - AnyDecodable helper

struct AnyDecodable: Decodable {
    let value: Any

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let int = try? container.decode(Int.self)      { value = int }
        else if let double = try? container.decode(Double.self) { value = double }
        else if let string = try? container.decode(String.self) { value = string }
        else if let bool = try? container.decode(Bool.self)    { value = bool }
        else if let dict = try? container.decode([String: AnyDecodable].self) {
            value = dict.mapValues(\.value)
        } else if let array = try? container.decode([AnyDecodable].self) {
            value = array.map(\.value)
        } else {
            value = NSNull()
        }
    }
}

// MARK: - GraphQL Query / Mutation strings

enum GQL {
    // ── Chat ──────────────────────────────────────────────────
    static let sendMessage = """
    mutation SendMessage($input: SendMessageInput!) {
      sendMessage(input: $input) {
        sessionId
        responseType
        message
        intent
        safetyIntercepted
        crisisResources {
          country
          hotline
          name
          url
        }
      }
    }
    """

    // ── Profile ───────────────────────────────────────────────
    static let myProfile = """
    query MyProfile {
      myProfile {
        id displayName avatarUrl preferredLanguage
        dietaryPreferences healthNotes wellnessGoals
        currentStreak longestStreak totalSessions wellnessScore createdAt
      }
    }
    """

    static let updateProfile = """
    mutation UpdateProfile($input: UpdateProfileInput!) {
      updateProfile(input: $input) {
        id displayName preferredLanguage dietaryPreferences healthNotes wellnessGoals
      }
    }
    """

    // ── Streak ────────────────────────────────────────────────
    static let streakInfo = """
    query StreakInfo {
      streakInfo { currentStreak longestStreak freezeAvailable lastSessionAt }
    }
    """

    static let freezeStreak = """
    mutation FreezeStreak { freezeStreak { currentStreak longestStreak freezeAvailable } }
    """

    // ── Goals ─────────────────────────────────────────────────
    static let myGoals = """
    query MyGoals($activeOnly: Boolean) {
      myGoals(activeOnly: $activeOnly) {
        id category title description targetValue currentValue unit
        aiSuggested isActive targetDate completedAt createdAt
      }
    }
    """

    static let createGoal = """
    mutation CreateGoal($input: CreateGoalInput!) {
      createGoal(input: $input) {
        id category title targetValue unit isActive createdAt
      }
    }
    """

    static let suggestedGoals = """
    query SuggestedGoals { suggestedGoals { category title rationale targetValue unit } }
    """

    // ── Habits ────────────────────────────────────────────────
    static let logHabit = """
    mutation LogHabit($input: LogHabitInput!) {
      logHabit(input: $input) { id sessionType title createdAt }
    }
    """

    // ── Wellness Score ────────────────────────────────────────
    static let wellnessScore = """
    query WellnessScore {
      wellnessScore {
        overall
        breakdown { nutrition exercise sleep mindfulness consistency }
      }
    }
    """

    // ── Video ─────────────────────────────────────────────────
    static let initiateVideoAnalysis = """
    mutation InitiateVideoAnalysis($input: InitiateVideoAnalysisInput!) {
      initiateVideoAnalysis(input: $input) { taskId status }
    }
    """

    static let videoAnalysisResult = """
    query VideoAnalysisResult($taskId: String!) {
      videoAnalysisResult(taskId: $taskId) {
        taskId status feedback nutritionEstimate formNotes safetyFlag
      }
    }
    """
}
