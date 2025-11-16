//
//  NotificationManager.swift
//  NutriVision AI
//
//  Push notifications manager for meal reminders
//

import Foundation
import UserNotifications

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    @Published var isAuthorized = false

    private let notificationCenter = UNUserNotificationCenter.current()

    // MARK: - Authorization

    func requestAuthorization() async throws {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]

        let granted = try await notificationCenter.requestAuthorization(options: options)

        await MainActor.run {
            isAuthorized = granted
        }

        if granted {
            await registerCategories()
        }
    }

    func checkAuthorizationStatus() async -> Bool {
        let settings = await notificationCenter.notificationSettings()
        await MainActor.run {
            isAuthorized = settings.authorizationStatus == .authorized
        }
        return settings.authorizationStatus == .authorized
    }

    // MARK: - Categories and Actions

    private func registerCategories() async {
        // Meal reminder actions
        let eatAction = UNNotificationAction(
            identifier: "EAT_ACTION",
            title: "Log Meal",
            options: .foreground
        )

        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_ACTION",
            title: "Remind in 30 min",
            options: []
        )

        let dismissAction = UNNotificationAction(
            identifier: "DISMISS_ACTION",
            title: "Dismiss",
            options: .destructive
        )

        let mealCategory = UNNotificationCategory(
            identifier: "MEAL_REMINDER",
            actions: [eatAction, snoozeAction, dismissAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )

        // Water reminder actions
        let drinkAction = UNNotificationAction(
            identifier: "DRINK_ACTION",
            title: "Log Water",
            options: .foreground
        )

        let waterCategory = UNNotificationCategory(
            identifier: "WATER_REMINDER",
            actions: [drinkAction, dismissAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )

        notificationCenter.setNotificationCategories([mealCategory, waterCategory])
    }

    // MARK: - Schedule Meal Reminders

    func scheduleMealReminder(
        mealType: String,
        time: DateComponents,
        repeats: Bool = true
    ) async throws {
        let content = UNMutableNotificationContent()
        content.title = "\(mealType.capitalized) Time!"
        content.body = "Time for your \(mealType). Don't forget to log your meal."
        content.sound = .default
        content.categoryIdentifier = "MEAL_REMINDER"
        content.userInfo = ["mealType": mealType]

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: time,
            repeats: repeats
        )

        let identifier = "meal_\(mealType)_\(time.hour ?? 0)_\(time.minute ?? 0)"
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        try await notificationCenter.add(request)
    }

    func scheduleAllMealReminders(
        breakfast: DateComponents,
        lunch: DateComponents,
        dinner: DateComponents
    ) async throws {
        // Remove existing meal reminders
        await removeMealReminders()

        // Schedule new reminders
        try await scheduleMealReminder(mealType: "breakfast", time: breakfast)
        try await scheduleMealReminder(mealType: "lunch", time: lunch)
        try await scheduleMealReminder(mealType: "dinner", time: dinner)
    }

    func removeMealReminders() async {
        let identifiers = await getPendingMealReminderIdentifiers()
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    private func getPendingMealReminderIdentifiers() async -> [String] {
        let requests = await notificationCenter.pendingNotificationRequests()
        return requests
            .filter { $0.identifier.starts(with: "meal_") }
            .map { $0.identifier }
    }

    // MARK: - Schedule Water Reminders

    func scheduleWaterReminders(
        startHour: Int = 8,
        endHour: Int = 22,
        intervalHours: Int = 2
    ) async throws {
        await removeWaterReminders()

        var hour = startHour
        var index = 0

        while hour <= endHour {
            var dateComponents = DateComponents()
            dateComponents.hour = hour
            dateComponents.minute = 0

            let content = UNMutableNotificationContent()
            content.title = "Stay Hydrated! 💧"
            content.body = "Time to drink some water. Keep up the good work!"
            content.sound = .default
            content.categoryIdentifier = "WATER_REMINDER"

            let trigger = UNCalendarNotificationTrigger(
                dateMatching: dateComponents,
                repeats: true
            )

            let identifier = "water_\(index)"
            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: trigger
            )

            try await notificationCenter.add(request)

            hour += intervalHours
            index += 1
        }
    }

    func removeWaterReminders() async {
        let requests = await notificationCenter.pendingNotificationRequests()
        let identifiers = requests
            .filter { $0.identifier.starts(with: "water_") }
            .map { $0.identifier }

        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    // MARK: - One-Time Notifications

    func scheduleOneTimeReminder(
        title: String,
        body: String,
        date: Date,
        identifier: String? = nil
    ) async throws {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: date
        )

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: false
        )

        let id = identifier ?? UUID().uuidString
        let request = UNNotificationRequest(
            identifier: id,
            content: content,
            trigger: trigger
        )

        try await notificationCenter.add(request)
    }

    // MARK: - Meal Plan Reminders

    func scheduleMealPlanReminders(mealPlan: MealPlan) async throws {
        // Remove existing meal plan reminders
        await removeMealPlanReminders()

        let dateFormatter = ISO8601DateFormatter()

        for meal in mealPlan.meals {
            guard let date = dateFormatter.date(from: meal.date) else { continue }

            // Schedule reminder 15 minutes before meal time
            let reminderDate = date.addingTimeInterval(-15 * 60)

            guard reminderDate > Date() else { continue }

            let title = "\(meal.mealType.capitalized) Coming Up"
            let body = meal.recipe != nil
                ? "Don't forget: \(meal.recipe!.name)"
                : "Time for \(meal.mealType)"

            try await scheduleOneTimeReminder(
                title: title,
                body: body,
                date: reminderDate,
                identifier: "mealplan_\(meal.id ?? 0)"
            )
        }
    }

    func removeMealPlanReminders() async {
        let requests = await notificationCenter.pendingNotificationRequests()
        let identifiers = requests
            .filter { $0.identifier.starts(with: "mealplan_") }
            .map { $0.identifier }

        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    // MARK: - Badge Management

    func setBadge(_ number: Int) {
        UNUserNotificationCenter.current().setBadgeCount(number)
    }

    func clearBadge() {
        setBadge(0)
    }

    // MARK: - Manage All Notifications

    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await notificationCenter.pendingNotificationRequests()
    }

    func removeAllPendingNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }

    func removeNotification(withIdentifier identifier: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}

// MARK: - Notification Models

struct MealReminderSettings: Codable {
    var breakfastTime: DateComponents
    var lunchTime: DateComponents
    var dinnerTime: DateComponents
    var enabled: Bool

    static var `default`: MealReminderSettings {
        var breakfast = DateComponents()
        breakfast.hour = 8
        breakfast.minute = 0

        var lunch = DateComponents()
        lunch.hour = 12
        lunch.minute = 30

        var dinner = DateComponents()
        dinner.hour = 19
        dinner.minute = 0

        return MealReminderSettings(
            breakfastTime: breakfast,
            lunchTime: lunch,
            dinnerTime: dinner,
            enabled: false
        )
    }
}

struct WaterReminderSettings: Codable {
    var startHour: Int
    var endHour: Int
    var intervalHours: Int
    var enabled: Bool

    static var `default`: WaterReminderSettings {
        return WaterReminderSettings(
            startHour: 8,
            endHour: 22,
            intervalHours: 2,
            enabled: false
        )
    }
}
