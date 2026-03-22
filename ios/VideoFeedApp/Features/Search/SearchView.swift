import SwiftUI

struct SearchView: View {
    @State private var store    = SearchStore()
    @State private var query    = ""
    @State private var showFilters = false
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    // ── Search bar ────────────────────────────────────────────
                    HStack(spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(.secondary)
                            TextField("Search videos, music, creators...", text: $query)
                                .foregroundStyle(.white)
                                .submitLabel(.search)
                                .focused($isSearchFocused)
                                .onSubmit { Task { await store.search(query: query) } }
                            if !query.isEmpty {
                                Button { query = ""; store.clear() } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(10)
                        .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))

                        Button { showFilters.toggle() } label: {
                            Image(systemName: "slider.horizontal.3")
                                .font(.title3)
                                .foregroundStyle(showFilters ? .cyan : .white)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)

                    // ── Platform chips ────────────────────────────────────────
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(SocialPlatform.allCases) { platform in
                                PlatformChip(
                                    platform: platform,
                                    isSelected: store.selectedPlatforms.contains(platform)
                                ) {
                                    if store.selectedPlatforms.contains(platform) {
                                        store.selectedPlatforms.remove(platform)
                                    } else {
                                        store.selectedPlatforms.insert(platform)
                                    }
                                }
                            }

                            Divider().frame(height: 20).overlay(.white.opacity(0.2))

                            TypeChip(label: "Videos", icon: "video.fill", isSelected: store.selectedItemTypes.contains("video")) {
                                store.selectedItemTypes.formSymmetricDifference(["video"])
                            }
                            TypeChip(label: "Music", icon: "music.note", isSelected: store.selectedItemTypes.contains("music")) {
                                store.selectedItemTypes.formSymmetricDifference(["music"])
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 4)

                    Divider().overlay(.white.opacity(0.1))

                    // ── Results / empty states ────────────────────────────────
                    if store.isSearching {
                        Spacer()
                        ProgressView("Searching across platforms...")
                            .foregroundStyle(.secondary)
                        Spacer()
                    } else if let error = store.searchError {
                        Spacer()
                        Label(error, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.red)
                            .padding()
                        Spacer()
                    } else if store.results.isEmpty && !query.isEmpty {
                        Spacer()
                        ContentUnavailableView.search(text: query)
                        Spacer()
                    } else if store.results.isEmpty {
                        SearchSuggestionsView(history: store.history) { suggestion in
                            query = suggestion
                            Task { await store.search(query: suggestion) }
                        }
                    } else {
                        SearchResultsList(results: store.results)
                    }
                }
            }
            .navigationTitle("Discover")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showFilters) {
                SearchFiltersSheet(store: store)
                    .presentationDetents([.medium])
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Results List

struct SearchResultsList: View {
    let results: [SearchResultItem]

    var body: some View {
        List(results) { item in
            SearchResultRow(item: item)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}

struct SearchResultRow: View {
    let item: SearchResultItem
    @State private var isFavorited = false

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            AsyncImage(url: item.thumbnailURL) { img in
                img.resizable().scaledToFill()
            } placeholder: {
                RoundedRectangle(cornerRadius: 8).fill(.white.opacity(0.1))
            }
            .frame(width: 80, height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(alignment: .bottomLeading) {
                PlatformBadge(platform: item.platform)
                    .padding(4)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                Text(item.authorName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    if item.viewCount > 0 {
                        Label(item.viewCount.abbreviated, systemImage: "eye.fill")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    if !item.country.isEmpty {
                        Text(item.country)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            // Favorite button
            Button {
                isFavorited.toggle()
                // TODO: call favorites API
            } label: {
                Image(systemName: isFavorited ? "heart.fill" : "heart")
                    .foregroundStyle(isFavorited ? .pink : .secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Suggestions

struct SearchSuggestionsView: View {
    let history: [String]
    let onTap: (String) -> Void

    private let trending = ["lo-fi beats", "kpop dance", "travel vlog", "edm festival", "food asmr"]

    var body: some View {
        List {
            if !history.isEmpty {
                Section("Recent") {
                    ForEach(history, id: \.self) { q in
                        Button { onTap(q) } label: {
                            Label(q, systemImage: "clock")
                                .foregroundStyle(.white)
                        }
                        .listRowBackground(Color.clear)
                    }
                }
            }

            Section("Trending") {
                ForEach(trending, id: \.self) { q in
                    Button { onTap(q) } label: {
                        Label(q, systemImage: "chart.line.uptrend.xyaxis")
                            .foregroundStyle(.white)
                    }
                    .listRowBackground(Color.clear)
                }
            }
        }
        .listStyle(.grouped)
        .scrollContentBackground(.hidden)
    }
}

// MARK: - Filter Sheet

struct SearchFiltersSheet: View {
    @Bindable var store: SearchStore

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                List {
                    Section("Countries") {
                        let countries = ["US","JP","KR","BR","IN","GB","DE","FR","MX","ID","TH","PH","NG","AU","CA","AR","ZA","TR","ES"]
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(countries, id: \.self) { c in
                                    Toggle(c, isOn: Binding(
                                        get: { store.selectedCountries.contains(c) },
                                        set: { on in
                                            if on { store.selectedCountries.append(c) }
                                            else { store.selectedCountries.removeAll { $0 == c } }
                                        }
                                    ))
                                    .toggleStyle(.button)
                                    .buttonStyle(.borderedProminent)
                                    .tint(store.selectedCountries.contains(c) ? .cyan : .white.opacity(0.15))
                                    .font(.caption)
                                }
                            }
                        }
                        .listRowBackground(Color.clear)
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Chips

struct PlatformChip: View {
    let platform: SocialPlatform
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: platform.icon)
                    .font(.caption)
                Text(platform.label)
                    .font(.system(size: 12, weight: .semibold))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.white.opacity(0.2) : Color.white.opacity(0.07))
            .foregroundStyle(isSelected ? .white : .secondary)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(isSelected ? Color.white.opacity(0.5) : .clear, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

struct TypeChip: View {
    let label: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(label, systemImage: icon)
                .font(.system(size: 12, weight: .semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.cyan.opacity(0.25) : Color.white.opacity(0.07))
                .foregroundStyle(isSelected ? .cyan : .secondary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct PlatformBadge: View {
    let platform: String
    var body: some View {
        Text(platform.prefix(2).uppercased())
            .font(.system(size: 9, weight: .bold))
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(.black.opacity(0.8))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

// Int.abbreviated defined in Core/Extensions.swift
