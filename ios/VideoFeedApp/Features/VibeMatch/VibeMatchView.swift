import SwiftUI

/// Vibe Match — discover users who share your music/video taste.
/// Uses pgvector cosine similarity on preference embeddings.
struct VibeMatchView: View {
    @State private var matches:    [VibeMatch] = []
    @State private var isLoading   = false
    @State private var hasEmbed    = true
    @State private var selectedMatch: VibeMatch?
    @State private var campus: String = ""
    @State private var showCampusInput = false

    private let profileID = "demo"

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                        Text("Finding your vibe twins...")
                            .foregroundStyle(.secondary)
                    }
                } else if !hasEmbed {
                    NoPreferenceEmptyState()
                } else if matches.isEmpty {
                    ContentUnavailableView(
                        "No Matches Yet",
                        systemImage: "person.2.slash",
                        description: Text("Be the first to set your preferences!")
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // ── Header ─────────────────────────────────────────
                            VibeMatchHeader()

                            // ── Campus filter ─────────────────────────────────
                            CampusFilterBar(campus: $campus, showInput: $showCampusInput) {
                                Task { await load() }
                            }

                            // ── Top match highlight ───────────────────────────
                            if let top = matches.first {
                                TopVibeMatchCard(match: top) {
                                    selectedMatch = top
                                }
                            }

                            // ── All matches grid ──────────────────────────────
                            if matches.count > 1 {
                                LazyVGrid(
                                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                                    spacing: 12
                                ) {
                                    ForEach(matches.dropFirst()) { match in
                                        VibeMatchCard(match: match) {
                                            selectedMatch = match
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Vibe Match 💫")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { Task { await load() } } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(.cyan)
                    }
                }
            }
            .sheet(item: $selectedMatch) { match in
                VibeMatchDetailSheet(match: match, myProfileID: profileID)
            }
        }
        .preferredColorScheme(.dark)
        .task { await load() }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            struct Resp: Decodable {
                let matches: [VibeMatch]
                let hasEmbedding: Bool
                enum CodingKeys: String, CodingKey {
                    case matches
                    case hasEmbedding = "has_embedding"
                }
            }
            var path = "/api/v1/vibe-match/\(profileID)"
            if !campus.isEmpty { path += "?campus=\(campus)" }
            let resp: Resp = try await APIClient.shared.get(path, base: APIClient.shared.goBase)
            matches = resp.matches
            hasEmbed = resp.hasEmbedding
        } catch {
            print("Vibe match error: \(error)")
        }
    }
}

// MARK: - Header

struct VibeMatchHeader: View {
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: -10) {
                ForEach(["😌","🔥","💃","🎮","📚"], id: \.self) { emoji in
                    Text(emoji)
                        .font(.system(size: 28))
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.08), in: Circle())
                        .overlay(Circle().stroke(.white.opacity(0.1), lineWidth: 1))
                }
            }
            Text("Find your vibe twin")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.white)
            Text("Matched by music taste, video preferences, and more")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            LinearGradient(colors: [.purple.opacity(0.15), .cyan.opacity(0.05)],
                          startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .background(.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Campus filter

struct CampusFilterBar: View {
    @Binding var campus: String
    @Binding var showInput: Bool
    let onFilter: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "building.columns")
                .foregroundStyle(.secondary)
            if showInput {
                TextField("Enter campus (e.g. UCLA)", text: $campus)
                    .foregroundStyle(.white)
                    .submitLabel(.search)
                    .onSubmit { onFilter(); showInput = false }
                Button { campus = ""; showInput = false; onFilter() } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                }
            } else {
                Button {
                    showInput = true
                } label: {
                    Text(campus.isEmpty ? "Filter by campus" : campus)
                        .font(.system(size: 14))
                        .foregroundStyle(campus.isEmpty ? .secondary : .cyan)
                }
                Spacer()
            }
        }
        .padding(12)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Top Match Card

struct TopVibeMatchCard: View {
    let match: VibeMatch
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                AsyncImage(url: match.avatarURL) { img in img.resizable().scaledToFill() }
                placeholder: { Circle().fill(.purple.opacity(0.3)) }
                    .frame(width: 72, height: 72)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(
                        LinearGradient(colors: [.purple, .cyan], startPoint: .top, endPoint: .bottom),
                        lineWidth: 3
                    ))

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Text("💫 Best Match")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.purple)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(.purple.opacity(0.2), in: Capsule())
                        Spacer()
                        Text("\(match.similarityPct)% vibe")
                            .font(.system(size: 13, weight: .heavy))
                            .foregroundStyle(.cyan)
                    }

                    Text("@\(match.username)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)

                    if !match.sharedGenres.isEmpty {
                        Text("Both into: \(match.sharedGenres.joined(separator: " · "))")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 8) {
                        Text("⚡ \(match.totalXP.abbreviated) XP")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                        ForEach(match.badges.prefix(3), id: \.self) { badge in
                            Text(badgeEmoji(badge)).font(.caption)
                        }
                    }
                }
            }
            .padding(16)
            .background(
                LinearGradient(colors: [.purple.opacity(0.15), .cyan.opacity(0.08)],
                              startPoint: .leading, endPoint: .trailing)
            )
            .background(.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(LinearGradient(colors: [.purple.opacity(0.5), .cyan.opacity(0.5)],
                                          startPoint: .leading, endPoint: .trailing), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Match Grid Card

struct VibeMatchCard: View {
    let match: VibeMatch
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                AsyncImage(url: match.avatarURL) { img in img.resizable().scaledToFill() }
                placeholder: { Circle().fill(.white.opacity(0.1)) }
                    .frame(width: 56, height: 56)
                    .clipShape(Circle())

                Text("@\(match.username)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                // Similarity ring
                ZStack {
                    Circle().stroke(.white.opacity(0.1), lineWidth: 4).frame(width: 44, height: 44)
                    Circle()
                        .trim(from: 0, to: match.similarity)
                        .stroke(Color.cyan, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 44, height: 44)
                        .rotationEffect(.degrees(-90))
                    Text("\(match.similarityPct)%")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.cyan)
                }

                if !match.sharedGenres.isEmpty {
                    Text(match.sharedGenres.prefix(2).joined(separator: " · "))
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.1), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Detail Sheet

struct VibeMatchDetailSheet: View {
    let match: VibeMatch
    let myProfileID: String
    @State private var shared: [FavoriteItem] = []
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        // Profile header
                        VStack(spacing: 10) {
                            AsyncImage(url: match.avatarURL) { img in img.resizable().scaledToFill() }
                            placeholder: { Circle().fill(.purple.opacity(0.3)) }
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.cyan, lineWidth: 2))

                            Text("@\(match.username)")
                                .font(.title2.bold())
                                .foregroundStyle(.white)

                            Text("\(match.similarityPct)% vibe match")
                                .font(.subheadline)
                                .foregroundStyle(.cyan)
                        }

                        // Shared genres
                        if !match.sharedGenres.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Label("You both vibe with", systemImage: "music.note")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.purple)
                                HStack(spacing: 8) {
                                    ForEach(match.sharedGenres, id: \.self) { genre in
                                        Text(genre.capitalized)
                                            .font(.system(size: 12, weight: .bold))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(.purple.opacity(0.2), in: Capsule())
                                            .foregroundStyle(.purple)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(14)
                            .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14))
                        }

                        // Shared favorites
                        if !shared.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Label("Both saved these", systemImage: "heart.fill")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.pink)
                                ForEach(shared) { fav in
                                    HStack(spacing: 10) {
                                        AsyncImage(url: fav.thumbnailURL) { img in img.resizable().scaledToFill() }
                                        placeholder: { RoundedRectangle(cornerRadius: 6).fill(.white.opacity(0.1)) }
                                            .frame(width: 44, height: 32)
                                            .clipShape(RoundedRectangle(cornerRadius: 6))
                                        Text(fav.title ?? "Track")
                                            .font(.system(size: 13))
                                            .foregroundStyle(.white)
                                            .lineLimit(1)
                                        Spacer()
                                        if let p = fav.platform { PlatformBadge(platform: p) }
                                    }
                                }
                            }
                            .padding(14)
                            .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14))
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Vibe Match")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }.foregroundStyle(.cyan)
                }
            }
        }
        .preferredColorScheme(.dark)
        .task {
            do {
                struct Resp: Decodable { let shared: [FavoriteItem] }
                let resp: Resp = try await APIClient.shared.get(
                    "/api/v1/vibe-match/\(myProfileID)/shared-favorites?other_profile_id=\(match.profileID)",
                    base: APIClient.shared.goBase
                )
                shared = resp.shared
            } catch {}
        }
    }
}

// MARK: - No embedding empty state

struct NoPreferenceEmptyState: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("💫").font(.system(size: 64))
            Text("Set your preferences first")
                .font(.title3.bold())
                .foregroundStyle(.white)
            Text("Tell us what genres, moods, and video types you love — then we'll find your vibe twins!")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

// MARK: - Helpers

func badgeEmoji(_ badgeID: String) -> String {
    let map = ["week_warrior": "🔥", "monthly_legend": "👑",
               "challenge_champ": "🏆", "study_grind": "📚",
               "vibe_master": "💫", "lofi_lord": "🎧", "first_watch": "👀"]
    return map[badgeID] ?? "🏅"
}

extension Int {
    var abbreviated: String {
        switch self {
        case 1_000_000...: return "\(self / 1_000_000)M"
        case 1_000...:     return "\(self / 1_000)K"
        default:           return "\(self)"
        }
    }
}
