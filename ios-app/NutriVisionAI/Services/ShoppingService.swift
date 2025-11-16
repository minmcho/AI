//
//  ShoppingService.swift
//  NutriVision AI
//
//  Shopping list service
//

import Foundation

class ShoppingService {
    private let apiClient = APIClient.shared

    // MARK: - Get Shopping Lists

    func getShoppingLists() async throws -> [ShoppingList] {
        return try await apiClient.request(
            endpoint: Config.Endpoints.shoppingLists,
            method: "GET"
        )
    }

    // MARK: - Create Shopping List

    func createShoppingList(name: String) async throws -> ShoppingList {
        let request = ["name": name]

        return try await apiClient.request(
            endpoint: Config.Endpoints.shoppingLists,
            method: "POST",
            body: request
        )
    }

    // MARK: - Generate Shopping List from Meal Plan

    struct GenerateListRequest: Codable {
        let mealPlanId: Int

        enum CodingKeys: String, CodingKey {
            case mealPlanId = "meal_plan_id"
        }
    }

    func generateShoppingList(from MealPlanId: Int) async throws -> ShoppingList {
        let request = GenerateListRequest(mealPlanId: mealPlanId)

        return try await apiClient.request(
            endpoint: Config.Endpoints.generateShoppingList,
            method: "POST",
            body: request
        )
    }

    // MARK: - Update Shopping List Item

    func toggleItemPurchased(listId: Int, itemId: Int) async throws -> ShoppingListItem {
        return try await apiClient.request(
            endpoint: "\(Config.Endpoints.shoppingLists)/\(listId)/items/\(itemId)/toggle",
            method: "PUT"
        )
    }

    // MARK: - Add Item to Shopping List

    struct AddItemRequest: Codable {
        let name: String
        let quantity: String?
        let unit: String?
        let category: String?
    }

    func addItemToList(
        listId: Int,
        name: String,
        quantity: String? = nil,
        unit: String? = nil,
        category: String? = nil
    ) async throws -> ShoppingListItem {
        let request = AddItemRequest(
            name: name,
            quantity: quantity,
            unit: unit,
            category: category
        )

        return try await apiClient.request(
            endpoint: "\(Config.Endpoints.shoppingLists)/\(listId)/items",
            method: "POST",
            body: request
        )
    }

    // MARK: - Delete Shopping List

    func deleteShoppingList(id: Int) async throws {
        let _: EmptyResponse = try await apiClient.request(
            endpoint: "\(Config.Endpoints.shoppingLists)/\(id)",
            method: "DELETE"
        )
    }

    // MARK: - Delete Item

    func deleteItem(listId: Int, itemId: Int) async throws {
        let _: EmptyResponse = try await apiClient.request(
            endpoint: "\(Config.Endpoints.shoppingLists)/\(listId)/items/\(itemId)",
            method: "DELETE"
        )
    }
}
