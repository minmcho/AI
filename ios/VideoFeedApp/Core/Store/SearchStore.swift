import Foundation
import Observation

@Observable
final class SearchStore {
    var results: [SearchResultItem] = []
    var isSearching = false
    var searchError: String?
    var history: [String] = []

    var selectedPlatforms: Set<SocialPlatform> = Set(SocialPlatform.allCases)
    var selectedItemTypes: Set<String> = ["video", "music"]
    var selectedCountries: [String] = ["US"]

    private let client = APIClient.shared

    func search(query: String, profileID: String? = nil) async {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isSearching = true
        searchError = nil
        defer { isSearching = false }

        let platforms = selectedPlatforms.map(\.rawValue).joined(separator: ",")
        let types     = selectedItemTypes.joined(separator: ",")
        let countries = selectedCountries.joined(separator: ",")
        var path = "/api/v1/search?q=\(query.urlEncoded)&platforms=\(platforms)&types=\(types)&countries=\(countries)"
        if let pid = profileID { path += "&profile_id=\(pid)" }

        do {
            let response: SearchResponse = try await client.get(path, base: client.goBase)
            results = response.results
            if !history.contains(query) {
                history.insert(query, at: 0)
                if history.count > 20 { history.removeLast() }
            }
        } catch {
            searchError = error.localizedDescription
        }
    }

    func clear() {
        results = []
        searchError = nil
    }
}

private struct SearchResponse: Decodable {
    let results: [SearchResultItem]
    let total: Int
}

private extension String {
    var urlEncoded: String {
        addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? self
    }
}
