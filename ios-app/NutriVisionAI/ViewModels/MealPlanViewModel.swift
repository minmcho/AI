//
//  MealPlanViewModel.swift
//  NutriVision AI
//
//  Meal planning and journal view model
//

import Foundation
import SwiftUI

@MainActor
class MealPlanViewModel: ObservableObject {
    // Meal Plans
    @Published var mealPlans: [MealPlan] = []
    @Published var selectedMealPlan: MealPlan?
    @Published var currentWeekPlan: MealPlan?

    // Journal
    @Published var journalEntries: [JournalEntry] = []
    @Published var selectedEntry: JournalEntry?
    @Published var todayEntry: JournalEntry?

    // Social Feed
    @Published var socialPosts: [MealPlanService.SocialPost] = []
    @Published var selectedPost: MealPlanService.SocialPost?

    // Meal Plan Generation
    @Published var generationDays: Int = 7
    @Published var preferences: [String: String] = [:]

    // Calendar
    @Published var selectedDate: Date = Date()
    @Published var calendarMeals: [Date: [Meal]] = [:]

    // General
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let mealPlanService = MealPlanService()
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    // MARK: - Load Meal Plans

    func loadMealPlans() async {
        isLoading = true
        errorMessage = nil

        do {
            mealPlans = try await mealPlanService.getMealPlans()

            // Set current week plan if available
            if let thisWeek = mealPlans.first(where: { isCurrentWeek($0) }) {
                currentWeekPlan = thisWeek
            }

            isLoading = false
        } catch {
            errorMessage = "Failed to load meal plans: \(error.localizedDescription)"
            isLoading = false
        }
    }

    // MARK: - Generate Meal Plan

    func generateMealPlan(days: Int = 7, preferences: [String: String]? = nil) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            let newPlan = try await mealPlanService.generateMealPlan(
                days: days,
                preferences: preferences
            )
            mealPlans.insert(newPlan, at: 0)
            currentWeekPlan = newPlan
            selectedMealPlan = newPlan
            isLoading = false
            return true
        } catch {
            errorMessage = "Failed to generate meal plan: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }

    // MARK: - Get Meal Plan Details

    func loadMealPlanDetails(id: Int) async {
        isLoading = true
        errorMessage = nil

        do {
            selectedMealPlan = try await mealPlanService.getMealPlanDetails(id: id)
            isLoading = false
        } catch {
            errorMessage = "Failed to load meal plan details: \(error.localizedDescription)"
            isLoading = false
        }
    }

    // MARK: - Update Meal Plan

    func updateMealPlan(id: Int, mealPlan: MealPlan) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            let updated = try await mealPlanService.updateMealPlan(id: id, mealPlan: mealPlan)
            if let index = mealPlans.firstIndex(where: { $0.id == id }) {
                mealPlans[index] = updated
            }
            selectedMealPlan = updated
            isLoading = false
            return true
        } catch {
            errorMessage = "Failed to update meal plan: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }

    // MARK: - Delete Meal Plan

    func deleteMealPlan(id: Int) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            try await mealPlanService.deleteMealPlan(id: id)
            mealPlans.removeAll { $0.id == id }
            if selectedMealPlan?.id == id {
                selectedMealPlan = nil
            }
            if currentWeekPlan?.id == id {
                currentWeekPlan = nil
            }
            isLoading = false
            return true
        } catch {
            errorMessage = "Failed to delete meal plan: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }

    // MARK: - Journal Entries

    func loadJournalEntries(for date: Date? = nil) async {
        isLoading = true
        errorMessage = nil

        let dateString = date.map { dateFormatter.string(from: $0) }

        do {
            journalEntries = try await mealPlanService.getJournalEntries(date: dateString)

            // Set today's entry if loading today
            if date == nil || Calendar.current.isDateInToday(date ?? Date()) {
                todayEntry = journalEntries.first
            }

            isLoading = false
        } catch {
            errorMessage = "Failed to load journal entries: \(error.localizedDescription)"
            isLoading = false
        }
    }

    func createJournalEntry(_ entry: JournalEntry) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            let newEntry = try await mealPlanService.createJournalEntry(entry)
            journalEntries.insert(newEntry, at: 0)

            if Calendar.current.isDateInToday(Date()) {
                todayEntry = newEntry
            }

            isLoading = false
            return true
        } catch {
            errorMessage = "Failed to create journal entry: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }

    func updateJournalEntry(id: Int, entry: JournalEntry) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            let updated = try await mealPlanService.updateJournalEntry(id: id, entry: entry)
            if let index = journalEntries.firstIndex(where: { $0.id == id }) {
                journalEntries[index] = updated
            }
            selectedEntry = updated
            isLoading = false
            return true
        } catch {
            errorMessage = "Failed to update journal entry: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }

    func deleteJournalEntry(id: Int) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            try await mealPlanService.deleteJournalEntry(id: id)
            journalEntries.removeAll { $0.id == id }
            if selectedEntry?.id == id {
                selectedEntry = nil
            }
            if todayEntry?.id == id {
                todayEntry = nil
            }
            isLoading = false
            return true
        } catch {
            errorMessage = "Failed to delete journal entry: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }

    // MARK: - Social Feed

    func loadSocialFeed(limit: Int = 20, offset: Int = 0) async {
        isLoading = true
        errorMessage = nil

        do {
            let posts = try await mealPlanService.getSocialFeed(limit: limit, offset: offset)

            if offset == 0 {
                socialPosts = posts
            } else {
                socialPosts.append(contentsOf: posts)
            }

            isLoading = false
        } catch {
            errorMessage = "Failed to load social feed: \(error.localizedDescription)"
            isLoading = false
        }
    }

    func createPost(content: String, imageUrl: String? = nil) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            let newPost = try await mealPlanService.createPost(content: content, imageUrl: imageUrl)
            socialPosts.insert(newPost, at: 0)
            isLoading = false
            return true
        } catch {
            errorMessage = "Failed to create post: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }

    // MARK: - Calendar Helpers

    func getMealsForDate(_ date: Date) -> [Meal] {
        return calendarMeals[date] ?? []
    }

    func loadCalendarMeals(for mealPlan: MealPlan) {
        // Build calendar from meal plan
        calendarMeals = [:]

        for meal in mealPlan.meals {
            if let date = parseDate(meal.date) {
                if calendarMeals[date] == nil {
                    calendarMeals[date] = []
                }
                calendarMeals[date]?.append(meal)
            }
        }
    }

    // MARK: - Helper Methods

    private func isCurrentWeek(_ mealPlan: MealPlan) -> Bool {
        let calendar = Calendar.current
        let now = Date()

        if let startDate = parseDate(mealPlan.startDate),
           let endDate = parseDate(mealPlan.endDate) {
            return startDate <= now && now <= endDate
        }

        return false
    }

    private func parseDate(_ dateString: String) -> Date? {
        return dateFormatter.date(from: dateString)
    }

    func clearSelection() {
        selectedMealPlan = nil
        selectedEntry = nil
        selectedPost = nil
    }
}
