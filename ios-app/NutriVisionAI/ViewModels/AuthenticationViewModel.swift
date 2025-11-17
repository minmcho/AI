//
//  AuthenticationViewModel.swift
//  NutriVision AI
//
//  Handles user authentication and registration
//

import Foundation
import Combine

@MainActor
class AuthenticationViewModel: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: User?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let apiClient = APIClient.shared
    private let tokenManager = TokenManager.shared

    init() {
        checkAuthenticationStatus()
    }

    // MARK: - Authentication Status

    func checkAuthenticationStatus() {
        isAuthenticated = tokenManager.isLoggedIn()
        if isAuthenticated {
            Task {
                await fetchCurrentUser()
            }
        }
    }

    // MARK: - Login

    func login(username: String, password: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let request = LoginRequest(username: username, password: password)

            // Create form data for OAuth2 password flow
            let response: LoginResponse = try await apiClient.request(
                endpoint: Config.Endpoints.login,
                method: "POST",
                body: request,
                requiresAuth: false
            )

            // Save tokens
            tokenManager.saveTokens(
                accessToken: response.accessToken,
                refreshToken: response.refreshToken
            )

            // Fetch user data (API doesn't return it in login response)
            await fetchCurrentUser()
            isAuthenticated = true
            isLoading = false

        } catch let error as APIError {
            errorMessage = error.localizedDescription
            isLoading = false
        } catch {
            errorMessage = "Login failed. Please try again."
            isLoading = false
        }
    }

    // MARK: - Register

    func register(
        email: String,
        username: String,
        password: String,
        age: Int? = nil,
        weightKg: Double? = nil,
        heightCm: Int? = nil,
        sex: Sex? = nil,
        allergies: [String]? = nil,
        dietaryRestrictions: [DietaryRestriction]? = nil,
        healthGoals: [HealthGoal]? = nil,
        activityLevel: ActivityLevel? = nil
    ) async {
        isLoading = true
        errorMessage = nil

        do {
            let request = RegisterRequest(
                email: email,
                username: username,
                password: password,
                age: age,
                weightKg: weightKg,
                heightCm: heightCm,
                sex: sex,
                allergies: allergies,
                dietaryRestrictions: dietaryRestrictions,
                healthGoals: healthGoals,
                activityLevel: activityLevel
            )

            let response: LoginResponse = try await apiClient.request(
                endpoint: Config.Endpoints.register,
                method: "POST",
                body: request,
                requiresAuth: false
            )

            // Save tokens
            tokenManager.saveTokens(
                accessToken: response.accessToken,
                refreshToken: response.refreshToken
            )

            // Fetch user data (API doesn't return it in register response)
            await fetchCurrentUser()
            isAuthenticated = true
            isLoading = false

        } catch let error as APIError {
            errorMessage = error.localizedDescription
            isLoading = false
        } catch {
            errorMessage = "Registration failed. Please try again."
            isLoading = false
        }
    }

    // MARK: - Logout

    func logout() {
        tokenManager.clearTokens()
        currentUser = nil
        isAuthenticated = false
    }

    // MARK: - Fetch Current User

    private func fetchCurrentUser() async {
        do {
            let user: User = try await apiClient.request(
                endpoint: Config.Endpoints.me,
                method: "GET",
                requiresAuth: true
            )
            currentUser = user
        } catch {
            // If fetching user fails, log out
            logout()
        }
    }

    // MARK: - Update Profile

    func updateProfile(user: User) async {
        isLoading = true
        errorMessage = nil

        do {
            let updatedUser: User = try await apiClient.request(
                endpoint: Config.Endpoints.profile,
                method: "PUT",
                body: user,
                requiresAuth: true
            )

            currentUser = updatedUser
            isLoading = false

        } catch let error as APIError {
            errorMessage = error.localizedDescription
            isLoading = false
        } catch {
            errorMessage = "Profile update failed."
            isLoading = false
        }
    }
}
