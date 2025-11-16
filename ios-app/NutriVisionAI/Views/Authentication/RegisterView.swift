//
//  RegisterView.swift
//  NutriVision AI
//
//  User registration view
//

import SwiftUI

struct RegisterView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authViewModel: AuthenticationViewModel

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var showPassword: Bool = false
    @State private var agreedToTerms: Bool = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "person.crop.circle.fill.badge.plus")
                            .resizable()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.green)

                        Text("Create Account")
                            .font(.system(size: 28, weight: .bold))

                        Text("Join NutriVision AI today")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)

                    // Registration form
                    VStack(spacing: 16) {
                        // Email field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.footnote)
                                .foregroundColor(.secondary)

                            HStack {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(.gray)
                                TextField("Enter your email", text: $email)
                                    .textContentType(.emailAddress)
                                    .autocapitalization(.none)
                                    .keyboardType(.emailAddress)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }

                        // Password field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.footnote)
                                .foregroundColor(.secondary)

                            HStack {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.gray)

                                if showPassword {
                                    TextField("Enter password", text: $password)
                                } else {
                                    SecureField("Enter password", text: $password)
                                }

                                Button(action: { showPassword.toggle() }) {
                                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)

                            // Password strength indicator
                            PasswordStrengthView(password: password)
                        }

                        // Confirm password field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm Password")
                                .font(.footnote)
                                .foregroundColor(.secondary)

                            HStack {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.gray)

                                SecureField("Re-enter password", text: $confirmPassword)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)

                            if !confirmPassword.isEmpty && password != confirmPassword {
                                Text("Passwords do not match")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }

                        // Terms and conditions
                        HStack(alignment: .top, spacing: 12) {
                            Button(action: { agreedToTerms.toggle() }) {
                                Image(systemName: agreedToTerms ? "checkmark.square.fill" : "square")
                                    .foregroundColor(agreedToTerms ? .green : .gray)
                            }

                            Text("I agree to the Terms of Service and Privacy Policy")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.top, 8)

                        // Error message
                        if let error = authViewModel.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }

                        // Register button
                        Button(action: register) {
                            if authViewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Create Account")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(isFormValid ? Color.green : Color.gray)
                        .cornerRadius(12)
                        .disabled(!isFormValid || authViewModel.isLoading)
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 32)

                    // Login link
                    HStack {
                        Text("Already have an account?")
                            .foregroundColor(.secondary)

                        Button(action: { presentationMode.wrappedValue.dismiss() }) {
                            Text("Log In")
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                        }
                    }
                    .padding(.top, 16)
                }
            }
            .navigationBarTitle("Sign Up", displayMode: .inline)
            .navigationBarItems(trailing: Button("Close") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }

    // MARK: - Computed Properties

    private var isFormValid: Bool {
        !email.isEmpty &&
        email.contains("@") &&
        !password.isEmpty &&
        password.count >= 8 &&
        password == confirmPassword &&
        agreedToTerms
    }

    // MARK: - Methods

    private func register() {
        Task {
            await authViewModel.register(email: email, password: password)

            if authViewModel.isAuthenticated {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

// MARK: - Password Strength View

struct PasswordStrengthView: View {
    let password: String

    var strength: Int {
        var score = 0
        if password.count >= 8 { score += 1 }
        if password.range(of: "[A-Z]", options: .regularExpression) != nil { score += 1 }
        if password.range(of: "[0-9]", options: .regularExpression) != nil { score += 1 }
        if password.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil { score += 1 }
        return score
    }

    var strengthLabel: String {
        switch strength {
        case 0...1: return "Weak"
        case 2: return "Fair"
        case 3: return "Good"
        case 4: return "Strong"
        default: return ""
        }
    }

    var strengthColor: Color {
        switch strength {
        case 0...1: return .red
        case 2: return .orange
        case 3: return .yellow
        case 4: return .green
        default: return .gray
        }
    }

    var body: some View {
        if !password.isEmpty {
            HStack {
                ForEach(0..<4) { index in
                    Rectangle()
                        .fill(index < strength ? strengthColor : Color.gray.opacity(0.3))
                        .frame(height: 4)
                }

                Text(strengthLabel)
                    .font(.caption)
                    .foregroundColor(strengthColor)
            }
        }
    }
}

struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterView()
            .environmentObject(AuthenticationViewModel())
    }
}
