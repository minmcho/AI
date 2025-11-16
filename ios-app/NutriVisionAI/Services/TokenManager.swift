//
//  TokenManager.swift
//  NutriVision AI
//
//  Secure token storage and management
//

import Foundation
import Security

class TokenManager {
    static let shared = TokenManager()

    private init() {}

    // MARK: - Token Storage

    func saveTokens(accessToken: String, refreshToken: String) {
        saveToKeychain(key: "access_token", value: accessToken)
        saveToKeychain(key: "refresh_token", value: refreshToken)
        UserDefaults.standard.set(true, forKey: "is_logged_in")
    }

    func getAccessToken() -> String? {
        return getFromKeychain(key: "access_token")
    }

    func getRefreshToken() -> String? {
        return getFromKeychain(key: "refresh_token")
    }

    func clearTokens() {
        deleteFromKeychain(key: "access_token")
        deleteFromKeychain(key: "refresh_token")
        UserDefaults.standard.set(false, forKey: "is_logged_in")
        UserDefaults.standard.removeObject(forKey: Config.UserDefaultsKeys.userEmail)
        UserDefaults.standard.removeObject(forKey: Config.UserDefaultsKeys.userId)
    }

    func isLoggedIn() -> Bool {
        return UserDefaults.standard.bool(forKey: "is_logged_in") && getAccessToken() != nil
    }

    // MARK: - Keychain Operations

    private func saveToKeychain(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]

        // Delete any existing item
        SecItemDelete(query as CFDictionary)

        // Add new item
        SecItemAdd(query as CFDictionary, nil)
    }

    private func getFromKeychain(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }

        return value
    }

    private func deleteFromKeychain(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]

        SecItemDelete(query as CFDictionary)
    }
}
