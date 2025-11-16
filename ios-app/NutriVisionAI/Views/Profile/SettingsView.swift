//
//  SettingsView.swift
//  NutriVision AI
//
//  App settings view
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var profileViewModel = ProfileViewModel()

    @State private var selectedLanguage: Language = .en
    @State private var notificationsEnabled = true
    @State private var biometricsEnabled = false
    @State private var showLanguageSelection = false

    @State private var healthKitEnabled = false
    @State private var mealRemindersEnabled = false
    @State private var waterRemindersEnabled = false
    @State private var showMealReminderSettings = false

    @StateObject private var healthKit = HealthKitManager.shared
    @StateObject private var notificationManager = NotificationManager.shared

    var body: some View {
        NavigationView {
            List {
                // Language
                Section(header: Text("Language & Region")) {
                    Button(action: { showLanguageSelection = true }) {
                        HStack {
                            Image(systemName: "globe")
                                .foregroundColor(.green)

                            Text("Language")
                                .foregroundColor(.primary)

                            Spacer()

                            HStack {
                                Text(selectedLanguage.flag)
                                Text(selectedLanguage.displayName)
                                    .foregroundColor(.secondary)
                            }

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }

                // Apple Health Integration
                Section(header: Text("Apple Health"),
                        footer: Text("Sync nutrition data with Apple Health app")) {
                    Toggle(isOn: $healthKitEnabled) {
                        HStack {
                            Image(systemName: "heart.text.square.fill")
                                .foregroundColor(.red)
                            Text("Apple Health Sync")
                        }
                    }
                    .tint(.green)
                    .onChange(of: healthKitEnabled) { enabled in
                        if enabled {
                            Task {
                                try? await healthKit.requestAuthorization()
                            }
                        }
                    }
                }

                // Meal Reminders
                Section(header: Text("Meal Reminders"),
                        footer: Text("Get notifications for breakfast, lunch, and dinner")) {
                    Toggle(isOn: $mealRemindersEnabled) {
                        HStack {
                            Image(systemName: "bell.badge.fill")
                                .foregroundColor(.orange)
                            Text("Meal Reminders")
                        }
                    }
                    .tint(.green)
                    .onChange(of: mealRemindersEnabled) { enabled in
                        if enabled {
                            Task {
                                try? await notificationManager.requestAuthorization()
                                let settings = MealReminderSettings.default
                                try? await notificationManager.scheduleAllMealReminders(
                                    breakfast: settings.breakfastTime,
                                    lunch: settings.lunchTime,
                                    dinner: settings.dinnerTime
                                )
                            }
                        } else {
                            Task {
                                await notificationManager.removeMealReminders()
                            }
                        }
                    }

                    if mealRemindersEnabled {
                        Button(action: { showMealReminderSettings = true }) {
                            HStack {
                                Text("Customize Times")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .foregroundColor(.primary)
                        }
                    }
                }

                // Water Reminders
                Section(header: Text("Water Reminders"),
                        footer: Text("Stay hydrated with periodic reminders")) {
                    Toggle(isOn: $waterRemindersEnabled) {
                        HStack {
                            Image(systemName: "drop.fill")
                                .foregroundColor(.cyan)
                            Text("Water Reminders")
                        }
                    }
                    .tint(.green)
                    .onChange(of: waterRemindersEnabled) { enabled in
                        if enabled {
                            Task {
                                try? await notificationManager.requestAuthorization()
                                try? await notificationManager.scheduleWaterReminders()
                            }
                        } else {
                            Task {
                                await notificationManager.removeWaterReminders()
                            }
                        }
                    }
                }

                // Notifications
                Section(header: Text("Notifications"),
                        footer: Text("Receive reminders for meals and health goals")) {
                    Toggle(isOn: $notificationsEnabled) {
                        HStack {
                            Image(systemName: "bell.fill")
                                .foregroundColor(.orange)
                            Text("Push Notifications")
                        }
                    }
                    .tint(.green)
                    .onChange(of: notificationsEnabled) { enabled in
                        if enabled {
                            Task {
                                try? await notificationManager.requestAuthorization()
                            }
                        }
                    }
                }

                // Privacy & Security
                Section(header: Text("Privacy & Security")) {
                    Toggle(isOn: $biometricsEnabled) {
                        HStack {
                            Image(systemName: "faceid")
                                .foregroundColor(.blue)
                            Text("Biometric Authentication")
                        }
                    }
                    .tint(.green)
                }

                // Data & Storage
                Section(header: Text("Data & Storage")) {
                    Button(action: {}) {
                        HStack {
                            Image(systemName: "arrow.down.circle.fill")
                                .foregroundColor(.green)
                            Text("Download My Data")
                                .foregroundColor(.primary)
                        }
                    }

                    Button(action: {}) {
                        HStack {
                            Image(systemName: "trash.circle.fill")
                                .foregroundColor(.red)
                            Text("Clear Cache")
                                .foregroundColor(.primary)
                        }
                    }
                }

                // About
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }

                    NavigationLink(destination: Text("Terms of Service")) {
                        HStack {
                            Image(systemName: "doc.text.fill")
                                .foregroundColor(.blue)
                            Text("Terms of Service")
                        }
                    }

                    NavigationLink(destination: Text("Privacy Policy")) {
                        HStack {
                            Image(systemName: "hand.raised.fill")
                                .foregroundColor(.purple)
                            Text("Privacy Policy")
                        }
                    }

                    NavigationLink(destination: Text("Licenses")) {
                        HStack {
                            Image(systemName: "text.book.closed.fill")
                                .foregroundColor(.orange)
                            Text("Open Source Licenses")
                        }
                    }
                }

                // Support
                Section(header: Text("Support")) {
                    Button(action: {}) {
                        HStack {
                            Image(systemName: "questionmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Help Center")
                                .foregroundColor(.primary)
                        }
                    }

                    Button(action: {}) {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.blue)
                            Text("Contact Support")
                                .foregroundColor(.primary)
                        }
                    }

                    Button(action: {}) {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text("Rate App")
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .sheet(isPresented: $showLanguageSelection) {
                LanguageSelectionView(selectedLanguage: $selectedLanguage)
            }
            .task {
                await profileViewModel.loadProfile()
                if let user = profileViewModel.user, let language = user.language {
                    selectedLanguage = language
                }

                // Check HealthKit authorization status
                healthKitEnabled = healthKit.checkAuthorizationStatus()

                // Check notification authorization status
                notificationsEnabled = await notificationManager.checkAuthorizationStatus()
            }
            .onChange(of: selectedLanguage) { newLanguage in
                Task {
                    _ = await profileViewModel.updateLanguage(newLanguage)
                }
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
