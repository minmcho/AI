//
//  JournalEntryView.swift
//  NutriVision AI
//
//  Create and edit food journal entries
//

import SwiftUI

struct JournalEntryView: View {
    @StateObject private var viewModel = JournalEntryViewModel()
    @Environment(\.presentationMode) var presentationMode

    @State private var title: String = ""
    @State private var content: String = ""
    @State private var mood: String = "Neutral"
    @State private var energyLevel: Double = 5.0
    @State private var selectedTags: Set<String> = []
    @State private var isPrivate: Bool = false

    let moods = ["Great", "Good", "Neutral", "Not Great", "Poor"]
    let suggestedTags = ["Meal Prep", "Eating Out", "Cravings", "Healthy Choice", "Indulgence", "Mindful Eating", "Stress Eating", "Social"]

    var body: some View {
        NavigationView {
            Form {
                // Title
                Section("Title") {
                    TextField("What's on your mind?", text: $title)
                }

                // Mood Selection
                Section("How are you feeling?") {
                    Picker("Mood", selection: $mood) {
                        ForEach(moods, id: \.self) { mood in
                            HStack {
                                Text(moodEmoji(mood))
                                Text(mood)
                            }
                            .tag(mood)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Energy Level
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Energy Level")
                            Spacer()
                            Text("\(Int(energyLevel))/10")
                                .foregroundColor(.secondary)
                        }

                        Slider(value: $energyLevel, in: 1...10, step: 1)
                            .tint(energyLevelColor(energyLevel))
                    }
                } header: {
                    Text("Energy Level")
                } footer: {
                    Text("How energetic do you feel right now?")
                }

                // Content
                Section("Journal Entry") {
                    TextEditor(text: $content)
                        .frame(minHeight: 150)
                }

                // Tags
                Section("Tags") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                        ForEach(suggestedTags, id: \.self) { tag in
                            TagChip(
                                tag: tag,
                                isSelected: selectedTags.contains(tag)
                            ) {
                                if selectedTags.contains(tag) {
                                    selectedTags.remove(tag)
                                } else {
                                    selectedTags.insert(tag)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }

                // Privacy
                Section {
                    Toggle("Private Entry", isOn: $isPrivate)
                } footer: {
                    Text("Private entries are only visible to you")
                }

                // Save Button
                Section {
                    Button(action: {
                        Task {
                            await viewModel.saveEntry(
                                title: title,
                                content: content,
                                mood: mood,
                                energyLevel: Int(energyLevel),
                                tags: Array(selectedTags),
                                isPrivate: isPrivate
                            )
                            if viewModel.errorMessage == nil {
                                presentationMode.wrappedValue.dismiss()
                            }
                        }
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Save Entry")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canSave ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(!canSave || viewModel.isLoading)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }

                // Error Message
                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("New Journal Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }

    private var canSave: Bool {
        !title.isEmpty && !content.isEmpty
    }

    private func moodEmoji(_ mood: String) -> String {
        switch mood {
        case "Great": return "😄"
        case "Good": return "🙂"
        case "Neutral": return "😐"
        case "Not Great": return "😕"
        case "Poor": return "😞"
        default: return "😐"
        }
    }

    private func energyLevelColor(_ level: Double) -> Color {
        if level >= 8 {
            return .green
        } else if level >= 5 {
            return .yellow
        } else {
            return .orange
        }
    }
}

// MARK: - Tag Chip

struct TagChip: View {
    let tag: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(tag)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

// MARK: - ViewModel

@MainActor
class JournalEntryViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?

    func saveEntry(title: String, content: String, mood: String, energyLevel: Int, tags: [String], isPrivate: Bool) async {
        isLoading = true
        errorMessage = nil

        // Validate
        if let error = ValidationUtils.lengthValidationError(title, fieldName: "Title", min: 1, max: 100) {
            errorMessage = error
            isLoading = false
            return
        }

        if let error = ValidationUtils.lengthValidationError(content, fieldName: "Content", min: 1, max: 5000) {
            errorMessage = error
            isLoading = false
            return
        }

        // TODO: Call API to save journal entry
        // For now, simulate success
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        isLoading = false
    }
}

// MARK: - Preview

struct JournalEntryView_Previews: PreviewProvider {
    static var previews: some View {
        JournalEntryView()
    }
}
