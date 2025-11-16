//
//  HealthProfileSetupView.swift
//  NutriVision AI
//
//  Health profile setup during onboarding
//

import SwiftUI

struct HealthProfileSetupView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @StateObject private var profileViewModel = ProfileViewModel()

    @State private var currentStep = 0
    @State private var age: String = ""
    @State private var weight: String = ""
    @State private var height: String = ""
    @State private var selectedSex: Sex = .male
    @State private var selectedGoals: Set<HealthGoal> = []
    @State private var selectedRestrictions: Set<DietaryRestriction> = []
    @State private var allergiesText: String = ""
    @State private var selectedLanguage: Language = .en

    let steps = ["Basic Info", "Health Goals", "Dietary Preferences", "Language"]

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress indicator
                ProgressView(value: Double(currentStep + 1), total: Double(steps.count))
                    .progressViewStyle(LinearProgressViewStyle(tint: .green))
                    .padding()

                // Step indicator
                Text("Step \(currentStep + 1) of \(steps.count): \(steps[currentStep])")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 20)

                // Step content
                TabView(selection: $currentStep) {
                    // Step 1: Basic Info
                    BasicInfoStepView(
                        age: $age,
                        weight: $weight,
                        height: $height,
                        selectedSex: $selectedSex
                    )
                    .tag(0)

                    // Step 2: Health Goals
                    HealthGoalsStepView(selectedGoals: $selectedGoals)
                        .tag(1)

                    // Step 3: Dietary Preferences
                    DietaryPreferencesStepView(
                        selectedRestrictions: $selectedRestrictions,
                        allergiesText: $allergiesText
                    )
                    .tag(2)

                    // Step 4: Language
                    LanguageStepView(selectedLanguage: $selectedLanguage)
                        .tag(3)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))

                // Navigation buttons
                HStack(spacing: 16) {
                    if currentStep > 0 {
                        Button(action: { currentStep -= 1 }) {
                            Text("Previous")
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(12)
                        }
                    }

                    Button(action: handleNext) {
                        if profileViewModel.isLoading {
                            ProgressView()
                        } else {
                            Text(currentStep < steps.count - 1 ? "Next" : "Complete")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(canProceed ? Color.green : Color.gray)
                    .cornerRadius(12)
                    .disabled(!canProceed || profileViewModel.isLoading)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
            .navigationTitle("Complete Your Profile")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Skip") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }

    // MARK: - Computed Properties

    private var canProceed: Bool {
        switch currentStep {
        case 0:
            return !age.isEmpty && !weight.isEmpty && !height.isEmpty
        case 1:
            return !selectedGoals.isEmpty
        case 2:
            return true // Dietary preferences are optional
        case 3:
            return true // Language has default
        default:
            return false
        }
    }

    // MARK: - Methods

    private func handleNext() {
        if currentStep < steps.count - 1 {
            withAnimation {
                currentStep += 1
            }
        } else {
            saveProfile()
        }
    }

    private func saveProfile() {
        Task {
            let success = await profileViewModel.updateHealthProfile(
                age: Int(age),
                weightKg: Double(weight),
                heightCm: Int(height),
                sex: selectedSex,
                healthGoals: Array(selectedGoals),
                dietaryRestrictions: selectedRestrictions.isEmpty ? nil : Array(selectedRestrictions),
                allergies: allergiesText.isEmpty ? nil : allergiesText.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            )

            if success {
                // Update language
                _ = await profileViewModel.updateLanguage(selectedLanguage)
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

// MARK: - Basic Info Step

struct BasicInfoStepView: View {
    @Binding var age: String
    @Binding var weight: String
    @Binding var height: String
    @Binding var selectedSex: Sex

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Age
                VStack(alignment: .leading, spacing: 8) {
                    Text("Age")
                        .font(.headline)
                    TextField("Enter your age", text: $age)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedTextFieldStyle())
                }

                // Weight
                VStack(alignment: .leading, spacing: 8) {
                    Text("Weight (kg)")
                        .font(.headline)
                    TextField("Enter your weight", text: $weight)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedTextFieldStyle())
                }

                // Height
                VStack(alignment: .leading, spacing: 8) {
                    Text("Height (cm)")
                        .font(.headline)
                    TextField("Enter your height", text: $height)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedTextFieldStyle())
                }

                // Sex
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sex")
                        .font(.headline)

                    Picker("Sex", selection: $selectedSex) {
                        ForEach([Sex.male, Sex.female], id: \.self) { sex in
                            Text(sex.rawValue.capitalized).tag(sex)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 20)
        }
    }
}

// MARK: - Health Goals Step

struct HealthGoalsStepView: View {
    @Binding var selectedGoals: Set<HealthGoal>

    let goals: [HealthGoal] = [.weightLoss, .muscleGain, .generalHealth, .athleticPerformance, .diseaseManagement]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("What are your health goals?")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .padding(.bottom, 8)

                ForEach(goals, id: \.self) { goal in
                    HealthGoalCard(
                        goal: goal,
                        isSelected: selectedGoals.contains(goal),
                        action: {
                            if selectedGoals.contains(goal) {
                                selectedGoals.remove(goal)
                            } else {
                                selectedGoals.insert(goal)
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 20)
        }
    }
}

struct HealthGoalCard: View {
    let goal: HealthGoal
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(goal.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .green : .gray)
                    .font(.title2)
            }
            .padding()
            .background(isSelected ? Color.green.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.green : Color.clear, lineWidth: 2)
            )
        }
    }
}

// MARK: - Dietary Preferences Step

struct DietaryPreferencesStepView: View {
    @Binding var selectedRestrictions: Set<DietaryRestriction>
    @Binding var allergiesText: String

    let restrictions: [DietaryRestriction] = [.vegetarian, .vegan, .glutenFree, .dairyFree, .nutFree, .halal, .kosher]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Dietary Restrictions")
                    .font(.title3)
                    .fontWeight(.semibold)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(restrictions, id: \.self) { restriction in
                        DietaryRestrictionButton(
                            restriction: restriction,
                            isSelected: selectedRestrictions.contains(restriction),
                            action: {
                                if selectedRestrictions.contains(restriction) {
                                    selectedRestrictions.remove(restriction)
                                } else {
                                    selectedRestrictions.insert(restriction)
                                }
                            }
                        )
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Allergies (comma-separated)")
                        .font(.headline)

                    TextEditor(text: $allergiesText)
                        .frame(height: 100)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 20)
        }
    }
}

struct DietaryRestrictionButton: View {
    let restriction: DietaryRestriction
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(restriction.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.vertical, 12)
                .padding(.horizontal, 8)
                .frame(maxWidth: .infinity)
                .background(isSelected ? Color.green : Color(.systemGray6))
                .cornerRadius(10)
        }
    }
}

// MARK: - Language Step

struct LanguageStepView: View {
    @Binding var selectedLanguage: Language

    let languages: [Language] = [.en, .zh, .ja, .ko, .th, .my]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Select Your Language")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .padding(.bottom, 8)

                ForEach(languages, id: \.self) { language in
                    LanguageCard(
                        language: language,
                        isSelected: selectedLanguage == language,
                        action: { selectedLanguage = language }
                    )
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 20)
        }
    }
}

struct LanguageCard: View {
    let language: Language
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(language.flag)
                    .font(.largeTitle)

                Text(language.displayName)
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .green : .gray)
                    .font(.title2)
            }
            .padding()
            .background(isSelected ? Color.green.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.green : Color.clear, lineWidth: 2)
            )
        }
    }
}

// MARK: - Custom Text Field Style

struct RoundedTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
    }
}

// MARK: - Extensions

extension HealthGoal {
    var description: String {
        switch self {
        case .weightLoss:
            return "Lose weight in a healthy, sustainable way"
        case .muscleGain:
            return "Build muscle and increase strength"
        case .generalHealth:
            return "Maintain overall health and wellness"
        case .athleticPerformance:
            return "Enhance athletic performance"
        case .diseaseManagement:
            return "Manage chronic conditions"
        }
    }
}

struct HealthProfileSetupView_Previews: PreviewProvider {
    static var previews: some View {
        HealthProfileSetupView()
            .environmentObject(AuthenticationViewModel())
    }
}
