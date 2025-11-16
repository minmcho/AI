//
//  RecipeSearchView.swift
//  NutriVision AI
//
//  Recipe search interface
//

import SwiftUI

struct RecipeSearchView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = RecipeViewModel()
    @State private var isSearching = false
    @FocusState private var searchFieldFocused: Bool

    // Popular searches
    let popularSearches = [
        "Pasta", "Chicken", "Salad", "Soup",
        "Vegetarian", "Dessert", "Breakfast", "Asian"
    ]

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack(spacing: 12) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)

                        TextField("Search recipes...", text: $viewModel.searchQuery)
                            .focused($searchFieldFocused)
                            .submitLabel(.search)
                            .onSubmit(performSearch)
                            .onChange(of: viewModel.searchQuery) { newValue in
                                if newValue.isEmpty {
                                    viewModel.clearSearch()
                                }
                            }

                        if !viewModel.searchQuery.isEmpty {
                            Button(action: {
                                viewModel.searchQuery = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    if searchFieldFocused {
                        Button("Cancel") {
                            viewModel.searchQuery = ""
                            searchFieldFocused = false
                        }
                        .foregroundColor(.green)
                    }
                }
                .padding()

                // Content
                ScrollView {
                    if viewModel.isLoading {
                        VStack(spacing: 20) {
                            ProgressView()
                            Text("Searching...")
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 40)

                    } else if !viewModel.searchResults.isEmpty {
                        // Search results
                        LazyVStack(spacing: 16) {
                            Text("\(viewModel.searchResults.count) results")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)

                            ForEach(viewModel.searchResults) { recipe in
                                RecipeCard(recipe: recipe)
                                    .onTapGesture {
                                        // Navigate to detail
                                    }
                            }
                        }
                        .padding(.horizontal)

                    } else if !viewModel.searchQuery.isEmpty && !viewModel.isLoading {
                        // No results
                        VStack(spacing: 20) {
                            Image(systemName: "magnifyingglass")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                                .foregroundColor(.gray)
                                .padding(.top, 40)

                            Text("No Results")
                                .font(.title3)
                                .fontWeight(.semibold)

                            Text("Try searching for something else")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                    } else {
                        // Empty state with suggestions
                        VStack(spacing: 24) {
                            // Popular searches
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Popular Searches")
                                    .font(.headline)
                                    .padding(.horizontal)

                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                    ForEach(popularSearches, id: \.self) { search in
                                        SearchSuggestionButton(
                                            text: search,
                                            icon: "magnifyingglass"
                                        ) {
                                            viewModel.searchQuery = search
                                            performSearch()
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                            .padding(.top, 20)

                            Divider()
                                .padding(.vertical)

                            // Search tips
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Search Tips")
                                    .font(.headline)
                                    .padding(.horizontal)

                                SearchTip(
                                    icon: "fork.knife",
                                    title: "By Ingredient",
                                    example: "Try \"chicken\" or \"tofu\""
                                )

                                SearchTip(
                                    icon: "globe",
                                    title: "By Cuisine",
                                    example: "Try \"Italian\" or \"Thai\""
                                )

                                SearchTip(
                                    icon: "leaf.fill",
                                    title: "By Diet",
                                    example: "Try \"vegan\" or \"keto\""
                                )

                                SearchTip(
                                    icon: "clock.fill",
                                    title: "By Meal",
                                    example: "Try \"breakfast\" or \"dinner\""
                                )
                            }
                        }
                    }
                }
            }
            .navigationTitle("Search Recipes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .onAppear {
                searchFieldFocused = true
            }
        }
    }

    // MARK: - Methods

    private func performSearch() {
        searchFieldFocused = false

        Task {
            await viewModel.searchRecipes()
        }
    }
}

// MARK: - Search Suggestion Button

struct SearchSuggestionButton: View {
    let text: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.green)
                Text(text)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

// MARK: - Search Tip

struct SearchTip: View {
    let icon: String
    let title: String
    let example: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.green)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(example)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal)
    }
}

struct RecipeSearchView_Previews: PreviewProvider {
    static var previews: some View {
        RecipeSearchView()
    }
}
