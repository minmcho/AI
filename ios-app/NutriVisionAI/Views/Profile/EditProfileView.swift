//
//  EditProfileView.swift
//  NutriVision AI
//
//  Edit user profile view
//

import SwiftUI

struct EditProfileView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: ProfileViewModel

    @State private var email: String = ""
    @State private var age: String = ""
    @State private var weight: String = ""
    @State private var height: String = ""
    @State private var selectedSex: Sex = .male
    @State private var selectedGoals: Set<HealthGoal> = []
    @State private var selectedRestrictions: Set<DietaryRestriction> = []
    @State private var allergiesText: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Basic Information")) {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)

                    HStack {
                        Text("Age")
                        Spacer()
                        TextField("Age", text: $age)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }

                    HStack {
                        Text("Weight (kg)")
                        Spacer()
                        TextField("Weight", text: $weight)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }

                    HStack {
                        Text("Height (cm)")
                        Spacer()
                        TextField("Height", text: $height)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }

                    Picker("Sex", selection: $selectedSex) {
                        Text("Male").tag(Sex.male)
                        Text("Female").tag(Sex.female)
                    }
                }

                Section(header: Text("Health Goals")) {
                    ForEach([HealthGoal.weightLoss, .muscleGain, .generalHealth, .athleticPerformance, .diseaseManagement], id: \.self) { goal in
                        Button(action: {
                            if selectedGoals.contains(goal) {
                                selectedGoals.remove(goal)
                            } else {
                                selectedGoals.insert(goal)
                            }
                        }) {
                            HStack {
                                Text(goal.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                                    .foregroundColor(.primary)

                                Spacer()

                                if selectedGoals.contains(goal) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.green)
                                }
                            }
                        }
                    }
                }

                Section(header: Text("Dietary Restrictions")) {
                    ForEach([DietaryRestriction.vegetarian, .vegan, .glutenFree, .dairyFree, .nutFree], id: \.self) { restriction in
                        Button(action: {
                            if selectedRestrictions.contains(restriction) {
                                selectedRestrictions.remove(restriction)
                            } else {
                                selectedRestrictions.insert(restriction)
                            }
                        }) {
                            HStack {
                                Text(restriction.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                                    .foregroundColor(.primary)

                                Spacer()

                                if selectedRestrictions.contains(restriction) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.green)
                                }
                            }
                        }
                    }
                }

                Section(header: Text("Allergies")) {
                    TextField("Comma-separated (e.g., peanuts, dairy)", text: $allergiesText)
                }

                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }

                if let success = viewModel.successMessage {
                    Section {
                        Text(success)
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveProfile()
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .onAppear {
                loadCurrentValues()
            }
        }
    }

    // MARK: - Methods

    private func loadCurrentValues() {
        guard let user = viewModel.user else { return }

        email = user.email ?? ""
        age = user.age.map { String($0) } ?? ""
        weight = user.weightKg.map { String($0) } ?? ""
        height = user.heightCm.map { String($0) } ?? ""
        selectedSex = user.sex ?? .male
        selectedGoals = Set(user.healthGoals ?? [])
        selectedRestrictions = Set(user.dietaryRestrictions ?? [])
        allergiesText = user.allergies?.joined(separator: ", ") ?? ""
    }

    private func saveProfile() {
        Task {
            let success = await viewModel.updateHealthProfile(
                age: Int(age),
                weightKg: Double(weight),
                heightCm: Int(height),
                sex: selectedSex,
                healthGoals: Array(selectedGoals),
                dietaryRestrictions: selectedRestrictions.isEmpty ? nil : Array(selectedRestrictions),
                allergies: allergiesText.isEmpty ? nil : allergiesText.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            )

            if success {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}

struct EditProfileView_Previews: PreviewProvider {
    static var previews: some View {
        EditProfileView(viewModel: ProfileViewModel())
    }
}
