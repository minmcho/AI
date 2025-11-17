//
//  RecipeFilterView.swift
//  NutriVision AI
//
//  Advanced recipe filtering
//

import SwiftUI

struct RecipeFilterView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var filters: RecipeFilters

    let cuisines = ["Italian", "Chinese", "Japanese", "Korean", "Thai", "Mexican", "French", "Indian", "Greek", "American"]
    let difficulties = ["Easy", "Medium", "Hard"]
    let dietaryTags = ["Vegetarian", "Vegan", "Gluten-Free", "Dairy-Free", "Keto", "Low-Carb", "Paleo", "Halal", "Kosher"]

    var body: some View {
        NavigationView {
            Form {
                // Cuisine Section
                Section(header: Text("Cuisine")) {
                    ForEach(cuisines, id: \.self) { cuisine in
                        HStack {
                            Text(cuisine)
                            Spacer()
                            if filters.cuisine == cuisine {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if filters.cuisine == cuisine {
                                filters.cuisine = nil
                            } else {
                                filters.cuisine = cuisine
                            }
                        }
                    }
                }

                // Difficulty Section
                Section(header: Text("Difficulty")) {
                    ForEach(difficulties, id: \.self) { difficulty in
                        HStack {
                            Text(difficulty)
                            Spacer()
                            if filters.difficulty == difficulty {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if filters.difficulty == difficulty {
                                filters.difficulty = nil
                            } else {
                                filters.difficulty = difficulty
                            }
                        }
                    }
                }

                // Prep Time Section
                Section(header: Text("Maximum Prep Time")) {
                    HStack {
                        Slider(
                            value: Binding(
                                get: { Double(filters.maxPrepTime ?? 60) },
                                set: { filters.maxPrepTime = Int($0) }
                            ),
                            in: 5...120,
                            step: 5
                        )

                        Text("\(filters.maxPrepTime ?? 60) min")
                            .frame(width: 60, alignment: .trailing)
                    }

                    Toggle("No limit", isOn: Binding(
                        get: { filters.maxPrepTime == nil },
                        set: { if $0 { filters.maxPrepTime = nil } else { filters.maxPrepTime = 30 } }
                    ))
                }

                // Dietary Tags Section
                Section(header: Text("Dietary Preferences")) {
                    ForEach(dietaryTags, id: \.self) { tag in
                        HStack {
                            Text(tag)
                            Spacer()
                            if filters.dietaryTags?.contains(tag) == true {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if filters.dietaryTags?.contains(tag) == true {
                                filters.dietaryTags?.removeAll { $0 == tag }
                            } else {
                                if filters.dietaryTags == nil {
                                    filters.dietaryTags = []
                                }
                                filters.dietaryTags?.append(tag)
                            }
                        }
                    }
                }

                // Active Filters Summary
                if hasActiveFilters {
                    Section(header: Text("Active Filters")) {
                        if let cuisine = filters.cuisine {
                            HStack {
                                Text("Cuisine: \(cuisine)")
                                Spacer()
                                Button(action: { filters.cuisine = nil }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                        }

                        if let difficulty = filters.difficulty {
                            HStack {
                                Text("Difficulty: \(difficulty)")
                                Spacer()
                                Button(action: { filters.difficulty = nil }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                        }

                        if let maxPrepTime = filters.maxPrepTime {
                            HStack {
                                Text("Max prep: \(maxPrepTime) min")
                                Spacer()
                                Button(action: { filters.maxPrepTime = nil }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                        }

                        if let tags = filters.dietaryTags, !tags.isEmpty {
                            ForEach(tags, id: \.self) { tag in
                                HStack {
                                    Text(tag)
                                    Spacer()
                                    Button(action: {
                                        filters.dietaryTags?.removeAll { $0 == tag }
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                        }

                        Button(action: clearAllFilters) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Clear All Filters")
                            }
                            .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("Filter Recipes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private var hasActiveFilters: Bool {
        filters.cuisine != nil ||
        filters.difficulty != nil ||
        filters.maxPrepTime != nil ||
        !(filters.dietaryTags?.isEmpty ?? true)
    }

    private func clearAllFilters() {
        filters = RecipeFilters()
    }
}

// MARK: - Recipe Filters Model

struct RecipeFilters {
    var cuisine: String?
    var difficulty: String?
    var maxPrepTime: Int?
    var dietaryTags: [String]?

    var isActive: Bool {
        cuisine != nil ||
        difficulty != nil ||
        maxPrepTime != nil ||
        !(dietaryTags?.isEmpty ?? true)
    }

    var activeCount: Int {
        var count = 0
        if cuisine != nil { count += 1 }
        if difficulty != nil { count += 1 }
        if maxPrepTime != nil { count += 1 }
        count += dietaryTags?.count ?? 0
        return count
    }
}

// MARK: - Preview

struct RecipeFilterView_Previews: PreviewProvider {
    static var previews: some View {
        RecipeFilterView(filters: .constant(RecipeFilters()))
    }
}
