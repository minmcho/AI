//
//  ShoppingListView.swift
//  NutriVision AI
//
//  Shopping list main view
//

import SwiftUI

struct ShoppingListView: View {
    @StateObject private var viewModel = ShoppingViewModel()
    @State private var showCreateList = false
    @State private var showGenerateFromMealPlan = false

    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading && viewModel.shoppingLists.isEmpty {
                    LoadingView(message: "Loading shopping lists...")
                } else if viewModel.shoppingLists.isEmpty {
                    EmptyShoppingListView {
                        showCreateList = true
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Active list
                            if let activeList = viewModel.activeList {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Text("Active List")
                                            .font(.headline)

                                        Spacer()

                                        Text("\(viewModel.remainingItems)/\(viewModel.totalItems)")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }

                                    ActiveShoppingListCard(
                                        list: activeList,
                                        viewModel: viewModel
                                    )
                                }
                                .padding(.horizontal)

                                Divider()
                                    .padding(.vertical)
                            }

                            // All lists
                            VStack(alignment: .leading, spacing: 12) {
                                Text("All Lists")
                                    .font(.headline)
                                    .padding(.horizontal)

                                ForEach(viewModel.shoppingLists) { list in
                                    NavigationLink(destination: ShoppingListDetailView(list: list)) {
                                        ShoppingListRow(list: list, viewModel: viewModel)
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        .padding(.vertical)
                    }
                    .refreshable {
                        await viewModel.loadShoppingLists()
                    }
                }
            }
            .navigationTitle("Shopping Lists")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showCreateList = true }) {
                            Label("Create New List", systemImage: "plus.circle")
                        }

                        Button(action: { showGenerateFromMealPlan = true }) {
                            Label("Generate from Meal Plan", systemImage: "wand.and.stars")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.green)
                    }
                }
            }
            .sheet(isPresented: $showCreateList) {
                CreateShoppingListView(viewModel: viewModel)
            }
            .sheet(isPresented: $showGenerateFromMealPlan) {
                GenerateShoppingListView(viewModel: viewModel)
            }
            .task {
                if viewModel.shoppingLists.isEmpty {
                    await viewModel.loadShoppingLists()
                }
            }
        }
    }
}

// MARK: - Active Shopping List Card

struct ActiveShoppingListCard: View {
    let list: ShoppingList
    @ObservedObject var viewModel: ShoppingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(list.name)
                .font(.title3)
                .fontWeight(.semibold)

            // Progress bar
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Progress")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text(String(format: "%.0f%%", viewModel.getProgress(for: list) * 100))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)
                            .cornerRadius(4)

                        Rectangle()
                            .fill(Color.green)
                            .frame(width: geometry.size.width * CGFloat(viewModel.getProgress(for: list)), height: 8)
                            .cornerRadius(4)
                    }
                }
                .frame(height: 8)
            }

            // Quick items
            if !list.items.isEmpty {
                VStack(spacing: 8) {
                    ForEach(list.items.prefix(3)) { item in
                        QuickItemRow(item: item) {
                            Task {
                                _ = await viewModel.toggleItemPurchased(
                                    listId: list.id,
                                    itemId: item.id
                                )
                            }
                        }
                    }

                    if list.items.count > 3 {
                        NavigationLink(destination: ShoppingListDetailView(list: list)) {
                            Text("View all \(list.items.count) items")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Quick Item Row

struct QuickItemRow: View {
    let item: ShoppingListItem
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack {
                Image(systemName: item.isPurchased ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(item.isPurchased ? .green : .gray)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .foregroundColor(.primary)
                        .strikethrough(item.isPurchased)

                    if let quantity = item.quantity, let unit = item.unit {
                        Text("\(quantity) \(unit)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }
            .padding(.vertical, 4)
        }
    }
}

// MARK: - Shopping List Row

struct ShoppingListRow: View {
    let list: ShoppingList
    @ObservedObject var viewModel: ShoppingViewModel

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(list.name)
                    .font(.headline)
                    .foregroundColor(.primary)

                HStack(spacing: 16) {
                    Label("\(list.items.count) items", systemImage: "list.bullet")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    let purchased = list.items.filter { $0.isPurchased }.count
                    if purchased > 0 {
                        Text("\(purchased) checked")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }

            Spacer()

            // Progress indicator
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 4)
                    .frame(width: 40, height: 40)

                Circle()
                    .trim(from: 0, to: CGFloat(viewModel.getProgress(for: list)))
                    .stroke(Color.green, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(-90))

                Text("\(Int(viewModel.getProgress(for: list) * 100))%")
                    .font(.caption2)
                    .fontWeight(.bold)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.1), radius: 3, x: 0, y: 1)
    }
}

// MARK: - Empty State

struct EmptyShoppingListView: View {
    let onCreate: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "cart")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.green)

            Text("No Shopping Lists")
                .font(.title2)
                .fontWeight(.bold)

            Text("Create a shopping list manually or generate one from your meal plan")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            CustomButton(
                title: "Create Shopping List",
                icon: "plus",
                style: .primary,
                action: onCreate
            )
            .padding(.horizontal, 32)
        }
    }
}

// MARK: - Create Shopping List View

struct CreateShoppingListView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: ShoppingViewModel

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                TextField("List name", text: $viewModel.newListName)
                    .textFieldStyle(RoundedTextFieldStyle())
                    .padding(.horizontal, 24)

                CustomButton(
                    title: "Create",
                    icon: "plus",
                    style: .primary,
                    isLoading: viewModel.isLoading
                ) {
                    Task {
                        let success = await viewModel.createShoppingList(name: viewModel.newListName)
                        if success {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
                .padding(.horizontal, 24)
                .disabled(viewModel.newListName.isEmpty)

                Spacer()
            }
            .padding(.top, 24)
            .navigationTitle("New Shopping List")
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
}

// MARK: - Generate Shopping List View

struct GenerateShoppingListView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: ShoppingViewModel
    @StateObject private var mealPlanViewModel = MealPlanViewModel()

    var body: some View {
        NavigationView {
            List {
                if mealPlanViewModel.isLoading {
                    ProgressView()
                } else if mealPlanViewModel.mealPlans.isEmpty {
                    Text("No meal plans available")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(mealPlanViewModel.mealPlans) { plan in
                        Button(action: {
                            generateFromPlan(plan)
                        }) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(plan.name)
                                    .font(.headline)

                                Text("\(plan.startDate) - \(plan.endDate)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Meal Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .task {
                await mealPlanViewModel.loadMealPlans()
            }
        }
    }

    private func generateFromPlan(_ plan: MealPlan) {
        Task {
            let success = await viewModel.generateShoppingListFromMealPlan(mealPlanId: plan.id)
            if success {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

struct ShoppingListView_Previews: PreviewProvider {
    static var previews: some View {
        ShoppingListView()
    }
}
