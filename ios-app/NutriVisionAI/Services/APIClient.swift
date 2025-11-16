//
//  APIClient.swift
//  NutriVision AI
//
//  Network layer for API communication
//

import Foundation
import Combine

enum APIError: Error {
    case invalidURL
    case requestFailed(Error)
    case invalidResponse
    case decodingFailed(Error)
    case unauthorized
    case serverError(String)
    case networkError

    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .requestFailed(let error):
            return "Request failed: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingFailed(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .unauthorized:
            return "Unauthorized. Please log in again."
        case .serverError(let message):
            return "Server error: \(message)"
        case .networkError:
            return "Network connection error"
        }
    }
}

class APIClient {
    static let shared = APIClient()

    private let session: URLSession
    private var cancellables = Set<AnyCancellable>()

    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 300
        self.session = URLSession(configuration: configuration)
    }

    // MARK: - Generic Request Methods

    func request<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: Encodable? = nil,
        requiresAuth: Bool = true
    ) async throws -> T {
        guard let url = URL(string: Config.baseURL + endpoint) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Add authorization token if required
        if requiresAuth {
            if let token = TokenManager.shared.getAccessToken() {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
        }

        // Add request body if provided
        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            // Handle different status codes
            switch httpResponse.statusCode {
            case 200...299:
                // Success
                do {
                    return try JSONDecoder().decode(T.self, from: data)
                } catch {
                    throw APIError.decodingFailed(error)
                }

            case 401:
                // Unauthorized - try to refresh token
                if requiresAuth, await refreshTokenIfNeeded() {
                    // Retry the request once with new token
                    return try await request(endpoint: endpoint, method: method, body: body, requiresAuth: requiresAuth)
                }
                throw APIError.unauthorized

            case 400...499:
                // Client error
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    throw APIError.serverError(errorResponse.detail)
                }
                throw APIError.invalidResponse

            case 500...599:
                // Server error
                throw APIError.serverError("Server error (\(httpResponse.statusCode))")

            default:
                throw APIError.invalidResponse
            }

        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.requestFailed(error)
        }
    }

    // MARK: - Multipart Form Data (File Upload)

    func uploadImage<T: Decodable>(
        endpoint: String,
        image: Data,
        additionalParams: [String: String] = [:],
        requiresAuth: Bool = true
    ) async throws -> T {
        guard let url = URL(string: Config.baseURL + endpoint) else {
            throw APIError.invalidURL
        }

        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        if requiresAuth {
            if let token = TokenManager.shared.getAccessToken() {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
        }

        // Create multipart body
        var body = Data()

        // Add additional parameters
        for (key, value) in additionalParams {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }

        // Add image file
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(image)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            switch httpResponse.statusCode {
            case 200...299:
                return try JSONDecoder().decode(T.self, from: data)
            case 401:
                throw APIError.unauthorized
            default:
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    throw APIError.serverError(errorResponse.detail)
                }
                throw APIError.invalidResponse
            }

        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.requestFailed(error)
        }
    }

    // MARK: - Token Refresh

    private func refreshTokenIfNeeded() async -> Bool {
        guard let refreshToken = TokenManager.shared.getRefreshToken() else {
            return false
        }

        do {
            let response: TokenResponse = try await request(
                endpoint: Config.Endpoints.refreshToken,
                method: "POST",
                body: RefreshTokenRequest(refreshToken: refreshToken),
                requiresAuth: false
            )

            TokenManager.shared.saveTokens(
                accessToken: response.accessToken,
                refreshToken: response.refreshToken
            )
            return true
        } catch {
            TokenManager.shared.clearTokens()
            return false
        }
    }
}

// MARK: - Helper Models

struct ErrorResponse: Codable {
    let detail: String
}

struct RefreshTokenRequest: Codable {
    let refreshToken: String

    enum CodingKeys: String, CodingKey {
        case refreshToken = "refresh_token"
    }
}

struct TokenResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let tokenType: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case tokenType = "token_type"
    }
}
