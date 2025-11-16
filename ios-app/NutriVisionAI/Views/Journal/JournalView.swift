//
//  JournalView.swift
//  NutriVision AI
//
//  Food and meal journal view
//

import SwiftUI

struct JournalView: View {
    @StateObject private var viewModel = MealPlanViewModel()
    @State private var showAddEntry = false
    @State private var selectedDate: Date = Date()

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Date picker
                DatePicker("", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .padding()
                    .onChange(of: selectedDate) { _ in
                        loadEntries()
                    }

                Divider()

                // Entries list
                ScrollView {
                    if viewModel.isLoading {
                        LoadingView(message: "Loading journal...")
                            .frame(height: 200)
                    } else if viewModel.journalEntries.isEmpty {
                        EmptyJournalView {
                            showAddEntry = true
                        }
                    } else {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.journalEntries) { entry in
                                JournalEntryCard(entry: entry)
                                    .onTapGesture {
                                        viewModel.selectedEntry = entry
                                    }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Food Journal")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddEntry = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.green)
                    }
                }
            }
            .sheet(isPresented: $showAddEntry) {
                AddJournalEntryView(viewModel: viewModel, date: selectedDate)
            }
            .sheet(item: $viewModel.selectedEntry) { entry in
                JournalEntryDetailView(entry: entry, viewModel: viewModel)
            }
            .task {
                loadEntries()
            }
        }
    }

    private func loadEntries() {
        Task {
            await viewModel.loadJournalEntries(for: selectedDate)
        }
    }
}

// MARK: - Journal Entry Card

struct JournalEntryCard: View {
    let entry: JournalEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if let mealType = entry.mealType {
                        Text(mealType.capitalized)
                            .font(.headline)
                    }

                    Text(entry.date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if let calories = entry.calories {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(calories)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)

                        Text("calories")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Description or recipe
            if let description = entry.description {
                Text(description)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(2)
            }

            // Nutrition summary
            if let protein = entry.protein, let carbs = entry.carbs, let fat = entry.fat {
                HStack(spacing: 16) {
                    MacroTag(label: "P", value: String(format: "%.0f", protein), color: .red)
                    MacroTag(label: "C", value: String(format: "%.0f", carbs), color: .blue)
                    MacroTag(label: "F", value: String(format: "%.0f", fat), color: .yellow)
                }
            }

            // Notes
            if let notes = entry.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.1), radius: 3, x: 0, y: 1)
    }
}

// MARK: - Macro Tag

struct MacroTag: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(color)

            Text(value)
                .font(.caption)
                .fontWeight(.semibold)

            Text("g")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .cornerRadius(6)
    }
}

// MARK: - Empty Journal View

struct EmptyJournalView: View {
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "book.closed")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundColor(.gray)
                .padding(.top, 60)

            Text("No Entries")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Start tracking your meals and nutrition")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            CustomButton(
                title: "Add Entry",
                icon: "plus",
                style: .primary,
                action: onAdd
            )
            .padding(.horizontal, 32)
        }
    }
}

// MARK: - Add Journal Entry View

struct AddJournalEntryView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: MealPlanViewModel

    let date: Date

    @State private var mealType: String = "breakfast"
    @State private var description: String = ""
    @State private var notes: String = ""

    let mealTypes = ["breakfast", "lunch", "dinner", "snack"]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Meal Details")) {
                    Picker("Meal Type", selection: $mealType) {
                        ForEach(mealTypes, id: \.self) { type in
                            Text(type.capitalized).tag(type)
                        }
                    }

                    TextField("What did you eat?", text: $description)
                }

                Section(header: Text("Notes")) {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
            }
            .navigationTitle("Add Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveEntry()
                    }
                    .disabled(description.isEmpty)
                }
            }
        }
    }

    private func saveEntry() {
        let formatter = ISO8601DateFormatter()
        let entry = JournalEntry(
            id: nil,
            date: formatter.string(from: date),
            mealType: mealType,
            description: description,
            calories: nil,
            protein: nil,
            carbs: nil,
            fat: nil,
            notes: notes.isEmpty ? nil : notes,
            recipe: nil
        )

        Task {
            let success = await viewModel.createJournalEntry(entry)
            if success {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

// MARK: - Journal Entry Detail View

struct JournalEntryDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    let entry: JournalEntry
    @ObservedObject var viewModel: MealPlanViewModel

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Meal type
                    if let mealType = entry.mealType {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Meal Type")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text(mealType.capitalized)
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                    }

                    // Description
                    if let description = entry.description {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("What You Ate")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text(description)
                                .font(.body)
                        }
                    }

                    // Nutrition
                    if entry.calories != nil {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Nutrition")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            HStack(spacing: 16) {
                                if let calories = entry.calories {
                                    NutritionItem(label: "Calories", value: "\(calories)", unit: "cal", color: .orange)
                                }

                                if let protein = entry.protein {
                                    NutritionItem(label: "Protein", value: String(format: "%.0f", protein), unit: "g", color: .red)
                                }
                            }

                            HStack(spacing: 16) {
                                if let carbs = entry.carbs {
                                    NutritionItem(label: "Carbs", value: String(format: "%.0f", carbs), unit: "g", color: .blue)
                                }

                                if let fat = entry.fat {
                                    NutritionItem(label: "Fat", value: String(format: "%.0f", fat), unit: "g", color: .yellow)
                                }
                            }
                        }
                    }

                    // Notes
                    if let notes = entry.notes {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Notes")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text(notes)
                                .font(.body)
                        }
                    }

                    // Delete button
                    if let entryId = entry.id {
                        Button(role: .destructive, action: {
                            Task {
                                let success = await viewModel.deleteJournalEntry(id: entryId)
                                if success {
                                    presentationMode.wrappedValue.dismiss()
                                }
                            }
                        }) {
                            Label("Delete Entry", systemImage: "trash")
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(12)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Entry Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Nutrition Item

struct NutritionItem: View {
    let label: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)

            Text(unit)
                .font(.caption2)
                .foregroundColor(.secondary)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct JournalView_Previews: PreviewProvider {
    static var previews: some View {
        JournalView()
    }
}
