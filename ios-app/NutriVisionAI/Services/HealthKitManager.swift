//
//  HealthKitManager.swift
//  NutriVision AI
//
//  Apple Health integration manager
//

import Foundation
import HealthKit

class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()

    private let healthStore = HKHealthStore()

    @Published var isAuthorized = false
    @Published var todayCalories: Double = 0
    @Published var todayProtein: Double = 0
    @Published var todayCarbs: Double = 0
    @Published var todayFat: Double = 0
    @Published var todayWater: Double = 0
    @Published var currentWeight: Double?
    @Published var currentHeight: Double?

    // MARK: - Health Types

    private var readTypes: Set<HKObjectType> {
        let types: [HKQuantityType] = [
            .quantityType(forIdentifier: .dietaryEnergyConsumed)!,
            .quantityType(forIdentifier: .dietaryProtein)!,
            .quantityType(forIdentifier: .dietaryCarbohydrates)!,
            .quantityType(forIdentifier: .dietaryFatTotal)!,
            .quantityType(forIdentifier: .dietaryWater)!,
            .quantityType(forIdentifier: .bodyMass)!,
            .quantityType(forIdentifier: .height)!,
            .quantityType(forIdentifier: .activeEnergyBurned)!,
            .quantityType(forIdentifier: .stepCount)!
        ]
        return Set(types)
    }

    private var writeTypes: Set<HKSampleType> {
        let types: [HKQuantityType] = [
            .quantityType(forIdentifier: .dietaryEnergyConsumed)!,
            .quantityType(forIdentifier: .dietaryProtein)!,
            .quantityType(forIdentifier: .dietaryCarbohydrates)!,
            .quantityType(forIdentifier: .dietaryFatTotal)!,
            .quantityType(forIdentifier: .dietaryWater)!,
            .quantityType(forIdentifier: .dietaryFiber)!,
            .quantityType(forIdentifier: .dietarySugar)!,
            .quantityType(forIdentifier: .dietarySodium)!,
            .quantityType(forIdentifier: .dietaryCholesterol)!
        ]
        return Set(types)
    }

    // MARK: - Authorization

    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }

        try await healthStore.requestAuthorization(toShare: writeTypes, read: readTypes)

        await MainActor.run {
            isAuthorized = true
        }
    }

    func checkAuthorizationStatus() -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else { return false }

        let status = healthStore.authorizationStatus(for: .quantityType(forIdentifier: .dietaryEnergyConsumed)!)
        return status == .sharingAuthorized
    }

    // MARK: - Read Data

    func fetchTodayNutrition() async throws {
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)

        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: now,
            options: .strictStartDate
        )

        // Fetch calories
        let calories = try await fetchQuantitySum(
            type: .quantityType(forIdentifier: .dietaryEnergyConsumed)!,
            predicate: predicate,
            unit: .kilocalorie()
        )

        // Fetch protein
        let protein = try await fetchQuantitySum(
            type: .quantityType(forIdentifier: .dietaryProtein)!,
            predicate: predicate,
            unit: .gram()
        )

        // Fetch carbs
        let carbs = try await fetchQuantitySum(
            type: .quantityType(forIdentifier: .dietaryCarbohydrates)!,
            predicate: predicate,
            unit: .gram()
        )

        // Fetch fat
        let fat = try await fetchQuantitySum(
            type: .quantityType(forIdentifier: .dietaryFatTotal)!,
            predicate: predicate,
            unit: .gram()
        )

        // Fetch water
        let water = try await fetchQuantitySum(
            type: .quantityType(forIdentifier: .dietaryWater)!,
            predicate: predicate,
            unit: .literUnit(with: .milli)
        )

        await MainActor.run {
            self.todayCalories = calories
            self.todayProtein = protein
            self.todayCarbs = carbs
            self.todayFat = fat
            self.todayWater = water
        }
    }

    func fetchCurrentWeight() async throws -> Double? {
        let type = HKQuantityType.quantityType(forIdentifier: .bodyMass)!
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }

                let weight = sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
                continuation.resume(returning: weight)
            }

            healthStore.execute(query)
        }
    }

    func fetchCurrentHeight() async throws -> Double? {
        let type = HKQuantityType.quantityType(forIdentifier: .height)!
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }

                let height = sample.quantity.doubleValue(for: .meterUnit(with: .centi))
                continuation.resume(returning: height)
            }

            healthStore.execute(query)
        }
    }

    private func fetchQuantitySum(
        type: HKQuantityType,
        predicate: NSPredicate,
        unit: HKUnit
    ) async throws -> Double {
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                let sum = statistics?.sumQuantity()?.doubleValue(for: unit) ?? 0
                continuation.resume(returning: sum)
            }

            healthStore.execute(query)
        }
    }

    // MARK: - Write Data

    func saveMealToHealth(
        calories: Double,
        protein: Double,
        carbs: Double,
        fat: Double,
        mealTime: Date = Date()
    ) async throws {
        var samples: [HKQuantitySample] = []

        // Calories
        if calories > 0 {
            let calorieType = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed)!
            let calorieQuantity = HKQuantity(unit: .kilocalorie(), doubleValue: calories)
            let calorieSample = HKQuantitySample(
                type: calorieType,
                quantity: calorieQuantity,
                start: mealTime,
                end: mealTime
            )
            samples.append(calorieSample)
        }

        // Protein
        if protein > 0 {
            let proteinType = HKQuantityType.quantityType(forIdentifier: .dietaryProtein)!
            let proteinQuantity = HKQuantity(unit: .gram(), doubleValue: protein)
            let proteinSample = HKQuantitySample(
                type: proteinType,
                quantity: proteinQuantity,
                start: mealTime,
                end: mealTime
            )
            samples.append(proteinSample)
        }

        // Carbs
        if carbs > 0 {
            let carbsType = HKQuantityType.quantityType(forIdentifier: .dietaryCarbohydrates)!
            let carbsQuantity = HKQuantity(unit: .gram(), doubleValue: carbs)
            let carbsSample = HKQuantitySample(
                type: carbsType,
                quantity: carbsQuantity,
                start: mealTime,
                end: mealTime
            )
            samples.append(carbsSample)
        }

        // Fat
        if fat > 0 {
            let fatType = HKQuantityType.quantityType(forIdentifier: .dietaryFatTotal)!
            let fatQuantity = HKQuantity(unit: .gram(), doubleValue: fat)
            let fatSample = HKQuantitySample(
                type: fatType,
                quantity: fatQuantity,
                start: mealTime,
                end: mealTime
            )
            samples.append(fatSample)
        }

        try await healthStore.save(samples)

        // Refresh today's data
        try await fetchTodayNutrition()
    }

    func saveWater(milliliters: Double) async throws {
        let waterType = HKQuantityType.quantityType(forIdentifier: .dietaryWater)!
        let waterQuantity = HKQuantity(unit: .literUnit(with: .milli), doubleValue: milliliters)
        let waterSample = HKQuantitySample(
            type: waterType,
            quantity: waterQuantity,
            start: Date(),
            end: Date()
        )

        try await healthStore.save(waterSample)
        try await fetchTodayNutrition()
    }

    // MARK: - Sync with Backend

    func syncProfileFromHealth() async throws -> (weight: Double?, height: Double?) {
        let weight = try await fetchCurrentWeight()
        let height = try await fetchCurrentHeight()

        await MainActor.run {
            self.currentWeight = weight
            self.currentHeight = height
        }

        return (weight, height)
    }
}

// MARK: - Errors

enum HealthKitError: Error, LocalizedError {
    case notAvailable
    case notAuthorized
    case saveFailed
    case fetchFailed

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "Health data is not available on this device"
        case .notAuthorized:
            return "Health data access not authorized"
        case .saveFailed:
            return "Failed to save data to Health"
        case .fetchFailed:
            return "Failed to fetch data from Health"
        }
    }
}
