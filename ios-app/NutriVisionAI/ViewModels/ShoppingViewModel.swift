//
//  ShoppingViewModel.swift
//  NutriVision AI
//
//  Shopping list view model
//

import Foundation
import SwiftUI

@MainActor
class ShoppingViewModel: ObservableObject {
    @Published var shoppingLists: [ShoppingList] = []
    @Published var selectedList: ShoppingList?
    @Published var activeList: ShoppingList?

    // Item management
    @Published var newItemName: String = ""
    @Published var newItemQuantity: String = ""
    @Published var newItemUnit: String = ""
    @Published var newItemCategory: String = ""

    // List creation
    @Published var newListName: String = ""
    @Published var selectedMealPlanId: Int?

    // Statistics
    @Published var totalItems: Int = 0
    @Published var purchasedItems: Int = 0
    @Published var remainingItems: Int = 0

    // General
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let shoppingService = ShoppingService()

    // MARK: - Load Shopping Lists

    func loadShoppingLists() async {
        isLoading = true
        errorMessage = nil

        do {
            shoppingLists = try await shoppingService.getShoppingLists()

            // Set active list (first incomplete list)
            if activeList == nil {
                activeList = shoppingLists.first { !isListCompleted($0) }
            }

            updateStatistics()
            isLoading = false
        } catch {
            errorMessage = "Failed to load shopping lists: \(error.localizedDescription)"
            isLoading = false
        }
    }

    // MARK: - Create Shopping List

    func createShoppingList(name: String) async -> Bool {
        guard !name.isEmpty else {
            errorMessage = "Please enter a list name"
            return false
        }

        isLoading = true
        errorMessage = nil

        do {
            let newList = try await shoppingService.createShoppingList(name: name)
            shoppingLists.insert(newList, at: 0)
            selectedList = newList
            activeList = newList
            newListName = ""
            isLoading = false
            return true
        } catch {
            errorMessage = "Failed to create shopping list: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }

    // MARK: - Generate Shopping List from Meal Plan

    func generateShoppingListFromMealPlan(mealPlanId: Int) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            let newList = try await shoppingService.generateShoppingList(from: mealPlanId)
            shoppingLists.insert(newList, at: 0)
            selectedList = newList
            activeList = newList
            isLoading = false
            return true
        } catch {
            errorMessage = "Failed to generate shopping list: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }

    // MARK: - Add Item to List

    func addItem(
        to listId: Int,
        name: String,
        quantity: String? = nil,
        unit: String? = nil,
        category: String? = nil
    ) async -> Bool {
        guard !name.isEmpty else {
            errorMessage = "Please enter an item name"
            return false
        }

        isLoading = true
        errorMessage = nil

        do {
            let newItem = try await shoppingService.addItemToList(
                listId: listId,
                name: name,
                quantity: quantity?.isEmpty == false ? quantity : nil,
                unit: unit?.isEmpty == false ? unit : nil,
                category: category?.isEmpty == false ? category : nil
            )

            // Update the list in memory
            if let index = shoppingLists.firstIndex(where: { $0.id == listId }) {
                shoppingLists[index].items.append(newItem)
            }

            if selectedList?.id == listId {
                selectedList?.items.append(newItem)
            }

            if activeList?.id == listId {
                activeList?.items.append(newItem)
            }

            // Clear form
            newItemName = ""
            newItemQuantity = ""
            newItemUnit = ""
            newItemCategory = ""

            updateStatistics()
            isLoading = false
            return true
        } catch {
            errorMessage = "Failed to add item: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }

    // MARK: - Toggle Item Purchased

    func toggleItemPurchased(listId: Int, itemId: Int) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            let updatedItem = try await shoppingService.toggleItemPurchased(
                listId: listId,
                itemId: itemId
            )

            // Update the item in all relevant lists
            updateItemInLists(listId: listId, itemId: itemId, with: updatedItem)

            updateStatistics()
            isLoading = false
            return true
        } catch {
            errorMessage = "Failed to update item: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }

    // MARK: - Delete Item

    func deleteItem(listId: Int, itemId: Int) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            try await shoppingService.deleteItem(listId: listId, itemId: itemId)

            // Remove from all lists
            removeItemFromLists(listId: listId, itemId: itemId)

            updateStatistics()
            isLoading = false
            return true
        } catch {
            errorMessage = "Failed to delete item: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }

    // MARK: - Delete Shopping List

    func deleteShoppingList(id: Int) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            try await shoppingService.deleteShoppingList(id: id)
            shoppingLists.removeAll { $0.id == id }

            if selectedList?.id == id {
                selectedList = nil
            }

            if activeList?.id == id {
                activeList = shoppingLists.first { !isListCompleted($0) }
            }

            updateStatistics()
            isLoading = false
            return true
        } catch {
            errorMessage = "Failed to delete shopping list: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }

    // MARK: - Helper Methods

    private func updateItemInLists(listId: Int, itemId: Int, with updatedItem: ShoppingListItem) {
        // Update in shoppingLists
        if let listIndex = shoppingLists.firstIndex(where: { $0.id == listId }),
           let itemIndex = shoppingLists[listIndex].items.firstIndex(where: { $0.id == itemId }) {
            shoppingLists[listIndex].items[itemIndex] = updatedItem
        }

        // Update in selectedList
        if selectedList?.id == listId,
           let itemIndex = selectedList?.items.firstIndex(where: { $0.id == itemId }) {
            selectedList?.items[itemIndex] = updatedItem
        }

        // Update in activeList
        if activeList?.id == listId,
           let itemIndex = activeList?.items.firstIndex(where: { $0.id == itemId }) {
            activeList?.items[itemIndex] = updatedItem
        }
    }

    private func removeItemFromLists(listId: Int, itemId: Int) {
        // Remove from shoppingLists
        if let listIndex = shoppingLists.firstIndex(where: { $0.id == listId }) {
            shoppingLists[listIndex].items.removeAll { $0.id == itemId }
        }

        // Remove from selectedList
        if selectedList?.id == listId {
            selectedList?.items.removeAll { $0.id == itemId }
        }

        // Remove from activeList
        if activeList?.id == listId {
            activeList?.items.removeAll { $0.id == itemId }
        }
    }

    private func updateStatistics() {
        guard let active = activeList else {
            totalItems = 0
            purchasedItems = 0
            remainingItems = 0
            return
        }

        totalItems = active.items.count
        purchasedItems = active.items.filter { $0.isPurchased }.count
        remainingItems = totalItems - purchasedItems
    }

    private func isListCompleted(_ list: ShoppingList) -> Bool {
        guard !list.items.isEmpty else { return false }
        return list.items.allSatisfy { $0.isPurchased }
    }

    func getProgress(for list: ShoppingList) -> Double {
        guard !list.items.isEmpty else { return 0 }
        let purchased = list.items.filter { $0.isPurchased }.count
        return Double(purchased) / Double(list.items.count)
    }

    func getItemsByCategory(from list: ShoppingList) -> [String: [ShoppingListItem]] {
        var categorized: [String: [ShoppingListItem]] = [:]

        for item in list.items {
            let category = item.category ?? "Other"
            if categorized[category] == nil {
                categorized[category] = []
            }
            categorized[category]?.append(item)
        }

        return categorized
    }

    func clearForm() {
        newItemName = ""
        newItemQuantity = ""
        newItemUnit = ""
        newItemCategory = ""
        newListName = ""
    }
}
