//
//  ShoppingListGeneratorView.swift
//  NutriVision AI
//
//  Generate shopping lists from recipes and meal plans
//

import SwiftUI

struct ShoppingListGeneratorView: View {
    @StateObject private var viewModel = ShoppingListGeneratorViewModel()
    @Environment(\.presentationMode) var presentationMode

    @State private var selectedRecipes: Set<String> = []
    @State private var selectedMealPlan: MealPlan?
    @State private var servingsMultiplier: Double = 1.0
    @State private var showingRecipePicker = false
    @State private var showingMealPlanPicker = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "cart.fill")
                                .font(.title)
                                .foregroundColor(.green)
                            Text("Shopping List Generator")
                                .font(.title2)
                                .fontWeight(.bold)
                        }

                        Text("Create a shopping list from your recipes or meal plan")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)

                    // Source Selection
                    VStack(alignment: .leading, spacing: 16) {
                        Text("What would you like to shop for?")
                            .font(.headline)
                            .padding(.horizontal)

                        // From Recipes
                        VStack(alignment: .leading, spacing: 12) {
                            Button(action: {
                                showingRecipePicker = true
                            }) {
                                HStack {
                                    Image(systemName: "book.fill")
                                        .foregroundColor(.blue)
                                    Text("Add Recipes")
                                    Spacer()
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(.blue)
                                }
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(12)
                            }
                            .padding(.horizontal)

                            if !selectedRecipes.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(Array(selectedRecipes), id: \.self) { recipeId in
                                        HStack {
                                            Text("Recipe \(recipeId)")
                                                .font(.subheadline)
                                            Spacer()
                                            Button(action: {
                                                selectedRecipes.remove(recipeId)
                                            }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundColor(.gray)
                                            }
                                        }
                                        .padding()
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(8)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }

                        Text("OR")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)

                        // From Meal Plan
                        VStack(alignment: .leading, spacing: 12) {
                            Button(action: {
                                showingMealPlanPicker = true
                            }) {
                                HStack {
                                    Image(systemName: "calendar")
                                        .foregroundColor(.purple)
                                    Text("From Meal Plan")
                                    Spacer()
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(.purple)
                                }
                                .padding()
                                .background(Color.purple.opacity(0.1))
                                .cornerRadius(12)
                            }
                            .padding(.horizontal)

                            if let mealPlan = selectedMealPlan {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(mealPlan.name)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                        if let startDate = mealPlan.startDate {
                                            Text("Starting \(DateUtils.formatShort(startDate))")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    Spacer()
                                    Button(action: {
                                        selectedMealPlan = nil
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                                .padding(.horizontal)
                            }
                        }
                    }

                    // Servings Multiplier
                    if !selectedRecipes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Adjust Servings")
                                .font(.headline)
                                .padding(.horizontal)

                            VStack(spacing: 8) {
                                HStack {
                                    Text("Multiplier")
                                    Spacer()
                                    Text("\(String(format: "%.1f", servingsMultiplier))x")
                                        .foregroundColor(.secondary)
                                }

                                Slider(value: $servingsMultiplier, in: 0.5...5.0, step: 0.5)
                                    .tint(.blue)

                                HStack {
                                    Text("0.5x")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("5.0x")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                    }

                    // Generate Button
                    Button(action: {
                        Task {
                            await viewModel.generateShoppingList(
                                recipeIds: Array(selectedRecipes),
                                mealPlanId: selectedMealPlan?.id,
                                servingsMultiplier: servingsMultiplier
                            )
                        }
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "sparkles")
                                Text("Generate Shopping List")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canGenerate ? Color.green : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(!canGenerate || viewModel.isLoading)
                    .padding(.horizontal)

                    // Error Message
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.horizontal)
                    }

                    // Generated Shopping List
                    if let shoppingList = viewModel.generatedList {
                        VStack(alignment: .leading, spacing: 16) {
                            Divider()

                            HStack {
                                Text("Shopping List")
                                    .font(.headline)
                                Spacer()
                                Button(action: {
                                    Task {
                                        await viewModel.saveShoppingList()
                                        if viewModel.errorMessage == nil {
                                            presentationMode.wrappedValue.dismiss()
                                        }
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                        Text("Save")
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(20)
                                }
                            }
                            .padding(.horizontal)

                            // Grouped by Category
                            ForEach(shoppingList.categories) { category in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(category.name)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.blue)
                                        .padding(.horizontal)

                                    ForEach(category.items) { item in
                                        HStack {
                                            Image(systemName: item.checked ? "checkmark.circle.fill" : "circle")
                                                .foregroundColor(item.checked ? .green : .gray)

                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(item.name)
                                                    .font(.subheadline)
                                                if let quantity = item.quantity, let unit = item.unit {
                                                    Text("\(quantity) \(unit)")
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                }
                                            }

                                            Spacer()
                                        }
                                        .padding()
                                        .background(Color.gray.opacity(0.05))
                                        .cornerRadius(8)
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        .padding(.vertical)
                    }

                    Spacer()
                }
                .padding(.vertical)
            }
            .navigationTitle("Shopping List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingRecipePicker) {
                MultiRecipePickerView(selectedRecipes: $selectedRecipes)
            }
            .sheet(isPresented: $showingMealPlanPicker) {
                MealPlanPickerView(selectedMealPlan: $selectedMealPlan)
            }
        }
    }

    private var canGenerate: Bool {
        !selectedRecipes.isEmpty || selectedMealPlan != nil
    }
}

// MARK: - Multi Recipe Picker

struct MultiRecipePickerView: View {
    @Binding var selectedRecipes: Set<String>
    @Environment(\.presentationMode) var presentationMode
    @State private var recipes: [Recipe] = [] // TODO: Load from API

    var body: some View {
        NavigationView {
            List(recipes) { recipe in
                Button(action: {
                    if selectedRecipes.contains(recipe.id) {
                        selectedRecipes.remove(recipe.id)
                    } else {
                        selectedRecipes.insert(recipe.id)
                    }
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(recipe.name)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            if let cuisine = recipe.cuisine {
                                Text(cuisine)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        if selectedRecipes.contains(recipe.id) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                        } else {
                            Image(systemName: "circle")
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .navigationTitle("Select Recipes")
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

// MARK: - Meal Plan Picker

struct MealPlanPickerView: View {
    @Binding var selectedMealPlan: MealPlan?
    @Environment(\.presentationMode) var presentationMode
    @State private var mealPlans: [MealPlan] = [] // TODO: Load from API

    var body: some View {
        NavigationView {
            List(mealPlans) { plan in
                Button(action: {
                    selectedMealPlan = plan
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(plan.name)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            if let startDate = plan.startDate {
                                Text("Starting \(DateUtils.formatShort(startDate))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        if selectedMealPlan?.id == plan.id {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Select Meal Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - ViewModel

@MainActor
class ShoppingListGeneratorViewModel: ObservableObject {
    @Published var generatedList: GeneratedShoppingList?
    @Published var isLoading = false
    @Published var errorMessage: String?

    func generateShoppingList(recipeIds: [String], mealPlanId: String?, servingsMultiplier: Double) async {
        isLoading = true
        errorMessage = nil

        // Simulate API call
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        // Mock generated list
        generatedList = GeneratedShoppingList(
            id: UUID().uuidString,
            categories: [
                ShoppingListCategory(
                    id: "1",
                    name: "Produce",
                    items: [
                        ShoppingListItem(id: "1", name: "Tomatoes", quantity: "4", unit: "pcs", checked: false),
                        ShoppingListItem(id: "2", name: "Onions", quantity: "2", unit: "pcs", checked: false),
                        ShoppingListItem(id: "3", name: "Garlic", quantity: "1", unit: "head", checked: false)
                    ]
                ),
                ShoppingListCategory(
                    id: "2",
                    name: "Dairy",
                    items: [
                        ShoppingListItem(id: "4", name: "Milk", quantity: "1", unit: "liter", checked: false),
                        ShoppingListItem(id: "5", name: "Cheese", quantity: "200", unit: "g", checked: false)
                    ]
                ),
                ShoppingListCategory(
                    id: "3",
                    name: "Pantry",
                    items: [
                        ShoppingListItem(id: "6", name: "Pasta", quantity: "500", unit: "g", checked: false),
                        ShoppingListItem(id: "7", name: "Olive Oil", quantity: "1", unit: "bottle", checked: false)
                    ]
                )
            ]
        )

        isLoading = false
    }

    func saveShoppingList() async {
        isLoading = true
        errorMessage = nil

        // TODO: Save to API
        try? await Task.sleep(nanoseconds: 500_000_000)

        isLoading = false
    }
}

// MARK: - Models

struct GeneratedShoppingList {
    let id: String
    let categories: [ShoppingListCategory]
}

struct ShoppingListCategory: Identifiable {
    let id: String
    let name: String
    let items: [ShoppingListItem]
}

struct ShoppingListItem: Identifiable {
    let id: String
    let name: String
    let quantity: String?
    let unit: String?
    let checked: Bool
}

// MARK: - Preview

struct ShoppingListGeneratorView_Previews: PreviewProvider {
    static var previews: some View {
        ShoppingListGeneratorView()
    }
}
