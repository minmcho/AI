//
//  ValidationUtils.swift
//  NutriVision AI
//
//  Form validation and input sanitization utilities
//

import Foundation

struct ValidationUtils {

    // MARK: - Email Validation

    static func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    static func emailValidationError(_ email: String) -> String? {
        if email.isEmpty {
            return "Email is required"
        }
        if !isValidEmail(email) {
            return "Please enter a valid email address"
        }
        return nil
    }

    // MARK: - Password Validation

    static func isValidPassword(_ password: String) -> Bool {
        // At least 8 characters, 1 uppercase, 1 lowercase, 1 number
        return password.count >= 8 &&
               password.rangeOfCharacter(from: .uppercaseLetters) != nil &&
               password.rangeOfCharacter(from: .lowercaseLetters) != nil &&
               password.rangeOfCharacter(from: .decimalDigits) != nil
    }

    static func passwordValidationError(_ password: String) -> String? {
        if password.isEmpty {
            return "Password is required"
        }
        if password.count < 8 {
            return "Password must be at least 8 characters"
        }
        if password.rangeOfCharacter(from: .uppercaseLetters) == nil {
            return "Password must contain at least one uppercase letter"
        }
        if password.rangeOfCharacter(from: .lowercaseLetters) == nil {
            return "Password must contain at least one lowercase letter"
        }
        if password.rangeOfCharacter(from: .decimalDigits) == nil {
            return "Password must contain at least one number"
        }
        return nil
    }

    static func passwordsMatch(_ password: String, _ confirmPassword: String) -> Bool {
        return !password.isEmpty && password == confirmPassword
    }

    // MARK: - Name Validation

    static func isValidName(_ name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count >= 2 && trimmed.count <= 50
    }

    static func nameValidationError(_ name: String, fieldName: String = "Name") -> String? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return "\(fieldName) is required"
        }
        if trimmed.count < 2 {
            return "\(fieldName) must be at least 2 characters"
        }
        if trimmed.count > 50 {
            return "\(fieldName) must not exceed 50 characters"
        }
        return nil
    }

    // MARK: - Phone Number Validation

    static func isValidPhoneNumber(_ phone: String) -> Bool {
        let phoneRegex = #"^[\d\s\-\+\(\)]{10,}$"#
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return phonePredicate.evaluate(with: phone)
    }

    static func phoneValidationError(_ phone: String) -> String? {
        if phone.isEmpty {
            return nil // Phone is optional in most cases
        }
        if !isValidPhoneNumber(phone) {
            return "Please enter a valid phone number"
        }
        return nil
    }

    // MARK: - URL Validation

    static func isValidURL(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString) else { return false }
        return url.scheme != nil && url.host != nil
    }

    static func urlValidationError(_ urlString: String) -> String? {
        if urlString.isEmpty {
            return nil // URL is often optional
        }
        if !isValidURL(urlString) {
            return "Please enter a valid URL"
        }
        return nil
    }

    // MARK: - Numeric Validation

    static func isValidNumber(_ value: String, min: Double? = nil, max: Double? = nil) -> Bool {
        guard let number = Double(value) else { return false }

        if let min = min, number < min {
            return false
        }
        if let max = max, number > max {
            return false
        }
        return true
    }

    static func numberValidationError(_ value: String, fieldName: String = "Value", min: Double? = nil, max: Double? = nil) -> String? {
        if value.isEmpty {
            return "\(fieldName) is required"
        }

        guard let number = Double(value) else {
            return "\(fieldName) must be a valid number"
        }

        if let min = min, number < min {
            return "\(fieldName) must be at least \(min)"
        }
        if let max = max, number > max {
            return "\(fieldName) must not exceed \(max)"
        }
        return nil
    }

    // MARK: - Age Validation

    static func isValidAge(_ age: Int) -> Bool {
        return age >= 13 && age <= 120
    }

    static func ageValidationError(_ age: Int?) -> String? {
        guard let age = age else {
            return "Age is required"
        }
        if age < 13 {
            return "You must be at least 13 years old"
        }
        if age > 120 {
            return "Please enter a valid age"
        }
        return nil
    }

    // MARK: - Date Validation

    static func isValidBirthDate(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: date, to: Date())
        guard let age = ageComponents.year else { return false }
        return age >= 13 && age <= 120
    }

    static func birthDateValidationError(_ date: Date?) -> String? {
        guard let date = date else {
            return "Birth date is required"
        }
        if date > Date() {
            return "Birth date cannot be in the future"
        }
        if !isValidBirthDate(date) {
            let calendar = Calendar.current
            let ageComponents = calendar.dateComponents([.year], from: date, to: Date())
            if let age = ageComponents.year, age < 13 {
                return "You must be at least 13 years old"
            }
            return "Please enter a valid birth date"
        }
        return nil
    }

    // MARK: - Nutrition Validation

    static func isValidCalories(_ calories: Double) -> Bool {
        return calories >= 0 && calories <= 10000
    }

    static func caloriesValidationError(_ calories: Double?) -> String? {
        guard let calories = calories else {
            return "Calories are required"
        }
        if calories < 0 {
            return "Calories cannot be negative"
        }
        if calories > 10000 {
            return "Calories value seems too high"
        }
        return nil
    }

    static func isValidMacro(_ value: Double) -> Bool {
        return value >= 0 && value <= 1000
    }

    static func macroValidationError(_ value: Double?, macroName: String = "Macro") -> String? {
        guard let value = value else {
            return nil // Macros are often optional
        }
        if value < 0 {
            return "\(macroName) cannot be negative"
        }
        if value > 1000 {
            return "\(macroName) value seems too high"
        }
        return nil
    }

    // MARK: - Recipe Validation

    static func isValidServings(_ servings: Int) -> Bool {
        return servings >= 1 && servings <= 100
    }

    static func servingsValidationError(_ servings: Int?) -> String? {
        guard let servings = servings else {
            return "Servings are required"
        }
        if servings < 1 {
            return "Must serve at least 1 person"
        }
        if servings > 100 {
            return "Servings cannot exceed 100"
        }
        return nil
    }

    static func isValidPrepTime(_ minutes: Int) -> Bool {
        return minutes >= 1 && minutes <= 1440 // Up to 24 hours
    }

    static func prepTimeValidationError(_ minutes: Int?) -> String? {
        guard let minutes = minutes else {
            return "Prep time is required"
        }
        if minutes < 1 {
            return "Prep time must be at least 1 minute"
        }
        if minutes > 1440 {
            return "Prep time cannot exceed 24 hours"
        }
        return nil
    }

    // MARK: - Text Length Validation

    static func isValidLength(_ text: String, min: Int = 0, max: Int = Int.max) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count >= min && trimmed.count <= max
    }

    static func lengthValidationError(_ text: String, fieldName: String = "Field", min: Int = 0, max: Int = Int.max) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        if min > 0 && trimmed.isEmpty {
            return "\(fieldName) is required"
        }
        if trimmed.count < min {
            return "\(fieldName) must be at least \(min) characters"
        }
        if trimmed.count > max {
            return "\(fieldName) must not exceed \(max) characters"
        }
        return nil
    }

    // MARK: - Health Metrics Validation

    static func isValidWeight(_ weight: Double, unit: WeightUnit = .kg) -> Bool {
        switch unit {
        case .kg:
            return weight >= 20 && weight <= 300
        case .lbs:
            return weight >= 44 && weight <= 661
        }
    }

    static func weightValidationError(_ weight: Double?, unit: WeightUnit = .kg) -> String? {
        guard let weight = weight else {
            return "Weight is required"
        }

        switch unit {
        case .kg:
            if weight < 20 {
                return "Weight must be at least 20 kg"
            }
            if weight > 300 {
                return "Weight cannot exceed 300 kg"
            }
        case .lbs:
            if weight < 44 {
                return "Weight must be at least 44 lbs"
            }
            if weight > 661 {
                return "Weight cannot exceed 661 lbs"
            }
        }
        return nil
    }

    static func isValidHeight(_ height: Double, unit: HeightUnit = .cm) -> Bool {
        switch unit {
        case .cm:
            return height >= 50 && height <= 300
        case .inches:
            return height >= 20 && height <= 118
        }
    }

    static func heightValidationError(_ height: Double?, unit: HeightUnit = .cm) -> String? {
        guard let height = height else {
            return "Height is required"
        }

        switch unit {
        case .cm:
            if height < 50 {
                return "Height must be at least 50 cm"
            }
            if height > 300 {
                return "Height cannot exceed 300 cm"
            }
        case .inches:
            if height < 20 {
                return "Height must be at least 20 inches"
            }
            if height > 118 {
                return "Height cannot exceed 118 inches"
            }
        }
        return nil
    }

    // MARK: - Supporting Enums

    enum WeightUnit {
        case kg
        case lbs
    }

    enum HeightUnit {
        case cm
        case inches
    }

    // MARK: - Sanitization

    static func sanitize(_ text: String) -> String {
        return text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n+", with: "\n", options: .regularExpression)
    }

    static func sanitizeEmail(_ email: String) -> String {
        return email
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    static func sanitizeName(_ name: String) -> String {
        return name
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }
}
