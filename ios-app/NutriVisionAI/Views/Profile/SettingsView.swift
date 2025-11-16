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
