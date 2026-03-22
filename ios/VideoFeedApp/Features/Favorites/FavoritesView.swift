import SwiftUI
import AVKit

/// Grid of saved videos and music tracks, filterable by type and platform.
struct FavoritesView: View {
    @State private var favorites: [FavoriteItem] = []
    @State private var isLoading  = false
    @State private var filterType: FilterType = .all
    @State private var filterPlatform: SocialPlatform? = nil
    @State private var searchText = ""

    private let profileID = "demo"   // Replace with auth profile ID

    var filtered: [FavoriteItem] {
        favorites.filter { fav in
            let typeMatch: Bool = switch filterType {
            case .all:   true
            case .video: !fav.isMusicItem
            case .music: fav.isMusicItem
            }
            let platformMatch = filterPlatform == nil || fav.platform == filterPlatform?.rawValue
            let textMatch = searchText.isEmpty || (fav.title?.localizedCaseInsensitiveContains(searchText) ?? false)
            return typeMatch && platformMatch && textMatch
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Filter bar
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterChip(label: "All", isSelected: filterType == .all) { filterType = .all }
                            FilterChip(label: "Videos", icon: "video.fill", isSelected: filterType == .video) { filterType = .video }
                            FilterChip(label: "Music",  icon: "music.note", isSelected: filterType == .music) { filterType = .music }
                            Divider().frame(height: 20).overlay(.white.opacity(0.2))
                            ForEach(SocialPlatform.allCases) { p in
                                FilterChip(
                                    label: p.label,
                                    icon: p.icon,
                                    isSelected: filterPlatform == p
                                ) { filterPlatform = filterPlatform == p ? nil : p }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 8)

                    Divider().overlay(.white.opacity(0.1))

                    if isLoading {
                        Spacer()
                        ProgressView("Loading favorites...")
                            .foregroundStyle(.secondary)
                        Spacer()
                    } else if filtered.isEmpty {
                        Spacer()
                        ContentUnavailableView(
                            "No Favorites Yet",
                            systemImage: "heart.slash",
                            description: Text("Save videos and music from the feed or search results.")
                        )
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVGrid(
                                columns: [GridItem(.flexible()), GridItem(.flexible())],
                                spacing: 12
                            ) {
                                ForEach(filtered) { fav in
                                    FavoriteCard(item: fav) {
                                        Task { await removeFavorite(fav) }
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("Favorites")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .searchable(text: $searchText, prompt: "Search favorites")
        }
        .preferredColorScheme(.dark)
        .task { await loadFavorites() }
    }

    private func loadFavorites() async {
        isLoading = true
        defer { isLoading = false }
        do {
            struct Response: Decodable { let favorites: [FavoriteItem] }
            let resp: Response = try await APIClient.shared.get(
                "/api/v1/favorites/\(profileID)",
                base: APIClient.shared.goBase
            )
            favorites = resp.favorites
        } catch {
            print("Favorites load error: \(error)")
        }
    }

    private func removeFavorite(_ fav: FavoriteItem) async {
        favorites.removeAll { $0.id == fav.id }
        do {
            struct Empty: Decodable {}
            let _: Empty = try await APIClient.shared.post(
                "/api/v1/favorites/\(profileID)/\(fav.id)",
                body: EmptyBody(),
                base: APIClient.shared.goBase
            )
        } catch {
            favorites.append(fav) // Rollback
        }
    }

    enum FilterType: String { case all, video, music }
}

// MARK: - Favorite Card

struct FavoriteCard: View {
    let item: FavoriteItem
    let onRemove: () -> Void
    @State private var showRemoveConfirm = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 8) {
                // Thumbnail
                AsyncImage(url: item.thumbnailURL) { img in
                    img.resizable().scaledToFill()
                } placeholder: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10).fill(.white.opacity(0.08))
                        Image(systemName: item.isMusicItem ? "music.note" : "video.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(height: 110)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(alignment: .bottomLeading) {
                    if let platform = item.platform {
                        PlatformBadge(platform: platform).padding(6)
                    }
                }
                .overlay(alignment: .bottomTrailing) {
                    if let duration = item.duration, duration > 0 {
                        Text(duration.mmss)
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(.black.opacity(0.75))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .padding(6)
                    }
                }

                // Title
                Text(item.title ?? "Untitled")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let author = item.authorName {
                    Text(author)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Remove button
            Button { showRemoveConfirm = true } label: {
                Image(systemName: "heart.fill")
                    .foregroundStyle(.pink)
                    .font(.system(size: 16))
                    .padding(8)
                    .background(.black.opacity(0.6), in: Circle())
            }
            .padding(6)
            .buttonStyle(.plain)
        }
        .padding(10)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14))
        .confirmationDialog("Remove from favorites?", isPresented: $showRemoveConfirm, titleVisibility: .visible) {
            Button("Remove", role: .destructive) { onRemove() }
            Button("Cancel", role: .cancel) {}
        }
    }
}

struct FilterChip: View {
    let label: String
    var icon: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if let icon {
                    Label(label, systemImage: icon)
                } else {
                    Text(label)
                }
            }
            .font(.system(size: 13, weight: .semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(isSelected ? Color.white.opacity(0.2) : Color.white.opacity(0.08))
            .foregroundStyle(isSelected ? .white : .secondary)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(isSelected ? Color.white.opacity(0.4) : .clear, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

private struct EmptyBody: Encodable {}

// TimeInterval.mmss defined in Core/Extensions.swift
