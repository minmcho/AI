import Foundation
import Observation

@Observable
final class PreferencesStore {
    var preferences = UserPreference()
    var options     = PreferenceOptions(musicGenres: [], musicMoods: [], videoTypes: [], platforms: [], countries: [])
    var isSaving    = false
    var isLoading   = false
    var errorMessage: String?

    private let client = APIClient.shared
    private let profileID: String

    init(profileID: String = "demo") {
        self.profileID = profileID
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            async let prefs: UserPreference = client.get("/api/v1/preferences/\(profileID)", base: client.goBase)
            async let opts: PreferenceOptions = client.get("/api/v1/preferences/options", base: client.goBase)
            (preferences, options) = try await (prefs, opts)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func save() async {
        isSaving = true
        defer { isSaving = false }
        do {
            let _: EmptyResponse = try await client.post(
                "/api/v1/preferences/\(profileID)",
                body: preferences,
                base: client.goBase
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggle(genre: String) {
        if preferences.musicGenres.contains(genre) {
            preferences.musicGenres.removeAll { $0 == genre }
        } else {
            preferences.musicGenres.append(genre)
        }
    }

    func toggle(mood: String) {
        if preferences.musicMoods.contains(mood) {
            preferences.musicMoods.removeAll { $0 == mood }
        } else {
            preferences.musicMoods.append(mood)
        }
    }

    func toggle(videoType: String) {
        if preferences.videoTypes.contains(videoType) {
            preferences.videoTypes.removeAll { $0 == videoType }
        } else {
            preferences.videoTypes.append(videoType)
        }
    }

    func toggle(country: String) {
        if preferences.countries.contains(country) {
            preferences.countries.removeAll { $0 == country }
        } else {
            preferences.countries.append(country)
        }
    }

    func toggle(platform: SocialPlatform) {
        if preferences.platforms.contains(platform) {
            preferences.platforms.removeAll { $0 == platform }
        } else {
            preferences.platforms.append(platform)
        }
    }
}

private struct EmptyResponse: Decodable {}
