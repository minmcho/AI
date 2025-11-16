//
//  MainTabView.swift
//  NutriVision AI
//
//  Main navigation with tab bar
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            // Recipes Tab
            RecipeListView()
                .tabItem {
                    Label("Recipes", systemImage: "book.fill")
                }
                .tag(1)

            // Food Scanner Tab
            FoodScannerView()
                .tabItem {
                    Label("Scan", systemImage: "camera.fill")
                }
                .tag(2)

            // Meal Plans Tab
            MealPlanView()
                .tabItem {
                    Label("Meals", systemImage: "calendar")
                }
                .tag(3)

            // Profile Tab
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(4)
        }
        .accentColor(.green)
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .environmentObject(AuthenticationViewModel())
    }
}
