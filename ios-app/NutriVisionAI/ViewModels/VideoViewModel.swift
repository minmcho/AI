//
//  VideoViewModel.swift
//  NutriVision AI
//
//  ViewModel for video browsing and search
//

import Foundation
import Combine

@MainActor
class VideoViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var videos: [Video] = []
    @Published var trendingVideos: [Video] = []
    @Published var searchResults: [Video] = []
    @Published var selectedVideo: Video?

    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var isSearching = false

    @Published var errorMessage: String?
    @Published var searchQuery: String = ""
    @Published var selectedCuisine: String?
    @Published var selectedPlatform: VideoPlatform?

    // MARK: - Pagination

    private var currentPage = 0
    private var hasMorePages = true
    private let pageSize = 20

    // MARK: - Services

    private let videoService = VideoService()

    // MARK: - Public Methods

    func loadTrendingVideos(cuisine: String? = nil) async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await videoService.getTrendingVideos(cuisine: cuisine)
            trendingVideos = response.videos
        } catch {
            errorMessage = "Failed to load trending videos: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func searchVideos(query: String, cuisine: String? = nil, platform: VideoPlatform? = nil) async {
        guard !query.isEmpty else {
            searchResults = []
            return
        }

        isSearching = true
        errorMessage = nil
        currentPage = 0

        do {
            let response = try await videoService.searchVideos(
                query: query,
                cuisine: cuisine,
                platform: platform?.rawValue
            )
            searchResults = response.videos
            hasMorePages = response.hasMore ?? false
        } catch {
            errorMessage = "Failed to search videos: \(error.localizedDescription)"
        }

        isSearching = false
    }

    func loadMoreVideos() async {
        guard !isLoadingMore && hasMorePages && !searchQuery.isEmpty else { return }

        isLoadingMore = true
        currentPage += 1

        do {
            let response = try await videoService.searchVideos(
                query: searchQuery,
                cuisine: selectedCuisine,
                platform: selectedPlatform?.rawValue,
                limit: pageSize,
                offset: currentPage * pageSize
            )

            searchResults.append(contentsOf: response.videos)
            hasMorePages = response.hasMore ?? false
        } catch {
            errorMessage = "Failed to load more videos: \(error.localizedDescription)"
            currentPage -= 1
        }

        isLoadingMore = false
    }

    func refreshVideos() async {
        if searchQuery.isEmpty {
            await loadTrendingVideos(cuisine: selectedCuisine)
        } else {
            await searchVideos(
                query: searchQuery,
                cuisine: selectedCuisine,
                platform: selectedPlatform
            )
        }
    }

    func clearSearch() {
        searchQuery = ""
        searchResults = []
        selectedCuisine = nil
        selectedPlatform = nil
        currentPage = 0
        hasMorePages = true
    }

    func filterByCuisine(_ cuisine: String?) async {
        selectedCuisine = cuisine

        if searchQuery.isEmpty {
            await loadTrendingVideos(cuisine: cuisine)
        } else {
            await searchVideos(
                query: searchQuery,
                cuisine: cuisine,
                platform: selectedPlatform
            )
        }
    }

    func filterByPlatform(_ platform: VideoPlatform?) async {
        selectedPlatform = platform

        if !searchQuery.isEmpty {
            await searchVideos(
                query: searchQuery,
                cuisine: selectedCuisine,
                platform: platform
            )
        }
    }

    func selectVideo(_ video: Video) {
        selectedVideo = video
    }

    // MARK: - Computed Properties

    var displayedVideos: [Video] {
        if searchQuery.isEmpty {
            return trendingVideos
        } else {
            return searchResults
        }
    }

    var isShowingSearchResults: Bool {
        !searchQuery.isEmpty
    }

    var canLoadMore: Bool {
        hasMorePages && !isLoadingMore && isShowingSearchResults
    }

    // MARK: - Helper Methods

    func formatViewCount(_ count: Int) -> String {
        if count >= 1_000_000 {
            return String(format: "%.1fM", Double(count) / 1_000_000)
        } else if count >= 1_000 {
            return String(format: "%.1fK", Double(count) / 1_000)
        }
        return "\(count)"
    }

    func formatDuration(_ duration: String) -> String {
        // Duration is already formatted from API (e.g., "10:30")
        return duration
    }
}

// MARK: - Video Search Filters

extension VideoViewModel {
    var availableCuisines: [String] {
        [
            "Italian",
            "Chinese",
            "Japanese",
            "Korean",
            "Thai",
            "Mexican",
            "French",
            "Indian",
            "Mediterranean",
            "American"
        ]
    }

    var availablePlatforms: [VideoPlatform] {
        [.youtube, .tiktok, .instagram]
    }
}

// MARK: - Debounced Search

extension VideoViewModel {
    private var searchDebouncer: AnyCancellable? {
        Just(searchQuery)
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] query in
                Task {
                    await self?.searchVideos(
                        query: query,
                        cuisine: self?.selectedCuisine,
                        platform: self?.selectedPlatform
                    )
                }
            }
    }

    func setupSearchDebouncing() -> AnyCancellable {
        $searchQuery
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] query in
                guard let self = self else { return }
                Task {
                    if query.isEmpty {
                        await self.loadTrendingVideos(cuisine: self.selectedCuisine)
                    } else {
                        await self.searchVideos(
                            query: query,
                            cuisine: self.selectedCuisine,
                            platform: self.selectedPlatform
                        )
                    }
                }
            }
    }
}
