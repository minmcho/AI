//
//  ProfileView.swift
//  NutriVision AI
//
//  User profile main view
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @StateObject private var viewModel = ProfileViewModel()

    @State private var showEditProfile = false
    @State private var showSettings = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    if viewModel.isLoading && viewModel.user == nil {
                        LoadingView(message: "Loading profile...")
                    } else if let user = viewModel.user {
                        // Profile header
                        VStack(spacing: 16) {
                            // Avatar
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(
                                        colors: [.green.opacity(0.7), .blue.opacity(0.5)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    .frame(width: 100, height: 100)

                                Text(user.email?.prefix(1).uppercased() ?? "U")
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(.white)
                            }

                            // Name and email
                            VStack(spacing: 4) {
                                Text(user.email ?? "User")
                                    .font(.title2)
                                    .fontWeight(.bold)

                                if let language = user.language {
                                    HStack {
                                        Text(language.flag)
                                        Text(language.displayName)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }

                            // Edit button
                            Button(action: { showEditProfile = true }) {
                                Text("Edit Profile")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.green)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 8)
                                    .background(Color.green.opacity(0.1))
                                    .cornerRadius(20)
                            }
                        }
                        .padding()

                        // Health Metrics
                        if let bmi = viewModel.bmi {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Health Metrics")
                                    .font(.headline)
                                    .padding(.horizontal)

                                HStack(spacing: 12) {
                                    HealthMetricCard(
                                        title: "BMI",
                                        value: String(format: "%.1f", bmi),
                                        subtitle: viewModel.getBMICategory(),
                                        color: viewModel.getBMIColor()
                                    )

                                    if let bmr = viewModel.bmr {
                                        HealthMetricCard(
                                            title: "BMR",
                                            value: String(format: "%.0f", bmr),
                                            subtitle: "cal/day",
                                            color: .orange
                                        )
                                    }
                                }
                                .padding(.horizontal)

                                if let dailyGoal = viewModel.dailyCalorieGoal {
                                    HealthMetricCard(
                                        title: "Daily Calorie Goal",
                                        value: String(format: "%.0f", dailyGoal),
                                        subtitle: "calories",
                                        color: .green
                                    )
                                    .padding(.horizontal)
                                }
                            }
                        }

                        // Health Goals
                        if let goals = user.healthGoals, !goals.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Health Goals")
                                    .font(.headline)
                                    .padding(.horizontal)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(goals, id: \.self) { goal in
                                            GoalBadge(goal: goal)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }

                        // Dietary Restrictions
                        if let restrictions = user.dietaryRestrictions, !restrictions.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Dietary Restrictions")
                                    .font(.headline)
                                    .padding(.horizontal)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(restrictions, id: \.self) { restriction in
                                            DietaryBadge(restriction: restriction)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }

                        // Statistics
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Activity")
                                .font(.headline)
                                .padding(.horizontal)

                            HStack(spacing: 12) {
                                StatCard(
                                    icon: "book.fill",
                                    value: "\(viewModel.totalRecipes)",
                                    label: "Recipes",
                                    color: .blue
                                )

                                StatCard(
                                    icon: "calendar",
                                    value: "\(viewModel.totalMealPlans)",
                                    label: "Meal Plans",
                                    color: .green
                                )

                                StatCard(
                                    icon: "flame.fill",
                                    value: "\(viewModel.journalStreak)",
                                    label: "Day Streak",
                                    color: .orange
                                )
                            }
                            .padding(.horizontal)
                        }

                        // Menu options
                        VStack(spacing: 0) {
                            MenuButton(
                                icon: "gearshape.fill",
                                title: "Settings",
                                color: .gray
                            ) {
                                showSettings = true
                            }

                            Divider().padding(.leading, 60)

                            MenuButton(
                                icon: "arrow.right.square.fill",
                                title: "Logout",
                                color: .red
                            ) {
                                authViewModel.logout()
                            }
                        }
                        .padding(.horizontal)
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $showEditProfile) {
                EditProfileView(viewModel: viewModel)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .task {
                await viewModel.loadProfile()
                await viewModel.loadStatistics()
            }
        }
    }
}

// MARK: - Health Metric Card

struct HealthMetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(color)

            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Goal Badge

struct GoalBadge: View {
    let goal: HealthGoal

    var body: some View {
        HStack {
            Image(systemName: goalIcon)
            Text(goal.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                .font(.subheadline)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.blue.opacity(0.1))
        .foregroundColor(.blue)
        .cornerRadius(20)
    }

    var goalIcon: String {
        switch goal {
        case .weightLoss:
            return "arrow.down.circle.fill"
        case .muscleGain:
            return "arrow.up.circle.fill"
        case .generalHealth:
            return "heart.fill"
        case .athleticPerformance:
            return "figure.run"
        case .diseaseManagement:
            return "cross.fill"
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Menu Button

struct MenuButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                    .frame(width: 30)

                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
            .padding()
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(AuthenticationViewModel())
    }
}
