//
//  ShoppingListDetailView.swift
//  NutriVision AI
//
//  Detailed shopping list view with item management
//

import SwiftUI

struct ShoppingListDetailView: View {
    @StateObject private var viewModel = ShoppingViewModel()
    let list: ShoppingList

    @State private var showAddItem = false
    @State private var groupByCategory = true

    var body: some View {
        VStack(spacing: 0) {
            // Progress header
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(viewModel.remainingItems) items left")
                            .font(.headline)

                        Text("\(viewModel.purchasedItems) of \(viewModel.totalItems) completed")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Text(String(format: "%.0f%%", viewModel.getProgress(for: list) * 100))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }

                // Progress bar
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
                            .animation(.easeInOut, value: viewModel.getProgress(for: list))
                    }
                }
                .frame(height: 8)
            }
            .padding()
            .background(Color(.systemBackground))

            Divider()

            // Items list
            List {
                if groupByCategory {
                    let categorized = viewModel.getItemsByCategory(from: list)
                    ForEach(categorized.keys.sorted(), id: \.self) { category in
                        Section(header: Text(category)) {
                            ForEach(categorized[category] ?? []) { item in
                                ShoppingItemRow(
                                    item: item,
                                    onToggle: {
                                        toggleItem(item)
                                    },
                                    onDelete: {
                                        deleteItem(item)
                                    }
                                )
                            }
                        }
                    }
                } else {
                    ForEach(list.items) { item in
                        ShoppingItemRow(
                            item: item,
                            onToggle: {
                                toggleItem(item)
                            },
                            onDelete: {
                                deleteItem(item)
                            }
                        )
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
        }
        .navigationTitle(list.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showAddItem = true }) {
                        Label("Add Item", systemImage: "plus")
                    }

                    Button(action: { groupByCategory.toggle() }) {
                        Label(
                            groupByCategory ? "Show All" : "Group by Category",
                            systemImage: groupByCategory ? "list.bullet" : "square.grid.2x2"
                        )
                    }

                    Divider()

                    Button(role: .destructive, action: deleteList) {
                        Label("Delete List", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showAddItem) {
            AddItemView(list: list, viewModel: viewModel)
        }
        .onAppear {
            viewModel.selectedList = list
            viewModel.activeList = list
            viewModel.shoppingLists = [list]
        }
    }

    // MARK: - Methods

    private func toggleItem(_ item: ShoppingListItem) {
        Task {
            _ = await viewModel.toggleItemPurchased(listId: list.id, itemId: item.id)
        }
    }

    private func deleteItem(_ item: ShoppingListItem) {
        Task {
            _ = await viewModel.deleteItem(listId: list.id, itemId: item.id)
        }
    }

    private func deleteList() {
        Task {
            _ = await viewModel.deleteShoppingList(id: list.id)
        }
    }
}

// MARK: - Shopping Item Row

struct ShoppingItemRow: View {
    let item: ShoppingListItem
    let onToggle: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Checkbox
            Button(action: onToggle) {
                Image(systemName: item.isPurchased ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(item.isPurchased ? .green : .gray)
                    .font(.title3)
            }
            .buttonStyle(BorderlessButtonStyle())

            // Item details
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.body)
                    .strikethrough(item.isPurchased)
                    .foregroundColor(item.isPurchased ? .secondary : .primary)

                if let quantity = item.quantity, let unit = item.unit {
                    Text("\(quantity) \(unit)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Delete button
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(BorderlessButtonStyle())
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add Item View

struct AddItemView: View {
    @Environment(\.presentationMode) var presentationMode
    let list: ShoppingList
    @ObservedObject var viewModel: ShoppingViewModel

    let categories = ["Produce", "Meat", "Dairy", "Bakery", "Pantry", "Frozen", "Beverages", "Other"]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Item Details")) {
                    TextField("Item name", text: $viewModel.newItemName)

                    TextField("Quantity (optional)", text: $viewModel.newItemQuantity)
                        .keyboardType(.decimalPad)

                    TextField("Unit (optional)", text: $viewModel.newItemUnit)
                }

                Section(header: Text("Category")) {
                    Picker("Category", selection: $viewModel.newItemCategory) {
                        Text("None").tag("")
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                }

                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addItem()
                    }
                    .disabled(viewModel.newItemName.isEmpty || viewModel.isLoading)
                }
            }
        }
    }

    private func addItem() {
        Task {
            let success = await viewModel.addItem(
                to: list.id,
                name: viewModel.newItemName,
                quantity: viewModel.newItemQuantity,
                unit: viewModel.newItemUnit,
                category: viewModel.newItemCategory.isEmpty ? nil : viewModel.newItemCategory
            )

            if success {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

struct ShoppingListDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ShoppingListDetailView(list: ShoppingList(
                id: 1,
                name: "Weekly Groceries",
                items: []
            ))
        }
    }
}
