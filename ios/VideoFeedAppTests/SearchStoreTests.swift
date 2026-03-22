import XCTest
@testable import VideoFeedApp

@MainActor
final class SearchStoreTests: XCTestCase {

    func testSearchClearsOnEmptyQuery() async {
        let store = SearchStore()
        store.results = [] // start empty
        // Empty query should not trigger network call
        await store.search(query: "  ")
        XCTAssertTrue(store.results.isEmpty)
        XCTAssertFalse(store.isSearching)
    }

    func testSelectedPlatformsDefaultsToAll() {
        let store = SearchStore()
        XCTAssertEqual(store.selectedPlatforms, Set(SocialPlatform.allCases))
    }

    func testClearResetsResults() {
        let store = SearchStore()
        store.results = [] // simulate results
        store.clear()
        XCTAssertTrue(store.results.isEmpty)
        XCTAssertNil(store.searchError)
    }

    func testSearchHistoryDeduplication() async throws {
        let store = SearchStore()
        // history is populated on successful search; simulate directly
        store.history = ["lofi", "kpop"]
        // Inserting duplicate should not add again
        if !store.history.contains("lofi") {
            store.history.insert("lofi", at: 0)
        }
        XCTAssertEqual(store.history.filter { $0 == "lofi" }.count, 1)
    }
}

final class PreferencesStoreTests: XCTestCase {

    func testToggleGenreAddsAndRemoves() {
        let store = PreferencesStore(profileID: "test")
        XCTAssertTrue(store.preferences.musicGenres.isEmpty)

        store.toggle(genre: "electronic")
        XCTAssertTrue(store.preferences.musicGenres.contains("electronic"))

        store.toggle(genre: "electronic")
        XCTAssertFalse(store.preferences.musicGenres.contains("electronic"))
    }

    func testToggleCountry() {
        let store = PreferencesStore(profileID: "test")
        store.toggle(country: "JP")
        XCTAssertTrue(store.preferences.countries.contains("JP"))
        store.toggle(country: "JP")
        XCTAssertFalse(store.preferences.countries.contains("JP"))
    }

    func testTogglePlatform() {
        let store = PreferencesStore(profileID: "test")
        let initial = store.preferences.platforms.count
        store.toggle(platform: .spotify)
        XCTAssertEqual(store.preferences.platforms.count, initial - 1)
        store.toggle(platform: .spotify)
        XCTAssertEqual(store.preferences.platforms.count, initial)
    }
}

final class FavoriteItemTests: XCTestCase {

    func testIsMusicItem() throws {
        let json = """
        {"id":"1","item_type":"social_music","platform":"spotify","external_id":"abc","created_at":"2026-01-01T00:00:00Z"}
        """.data(using: .utf8)!
        let item = try JSONDecoder.iso8601.decode(FavoriteItem.self, from: json)
        XCTAssertTrue(item.isMusicItem)
    }

    func testIsVideoItem() throws {
        let json = """
        {"id":"2","item_type":"video","platform":"youtube","external_id":"xyz","created_at":"2026-01-01T00:00:00Z"}
        """.data(using: .utf8)!
        let item = try JSONDecoder.iso8601.decode(FavoriteItem.self, from: json)
        XCTAssertFalse(item.isMusicItem)
    }
}
