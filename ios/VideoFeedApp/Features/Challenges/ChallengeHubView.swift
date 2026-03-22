import SwiftUI

struct ChallengeHubView: View {
    @State private var challenges: [Challenge] = []
    @State private var isLoading  = false
    @State private var selectedCategory: String? = nil
    @State private var showCreate = false
    @State private var selectedChallenge: Challenge?

    private let categories = ["All", "Dance", "Comedy", "Study", "Music", "Sports", "Fashion", "Gaming"]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Category strip
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(categories, id: \.self) { cat in
                                CategoryChip(
                                    label: cat,
                                    isSelected: (selectedCategory ?? "All") == cat
                                ) {
                                    let new = cat == "All" ? nil : cat.lowercased()
                                    selectedCategory = new
                                    Task { await load() }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 10)

                    Divider().overlay(.white.opacity(0.1))

                    if isLoading {
                        Spacer()
                        ProgressView("Loading challenges...").foregroundStyle(.secondary)
                        Spacer()
                    } else if challenges.isEmpty {
                        Spacer()
                        ContentUnavailableView(
                            "No Active Challenges",
                            systemImage: "trophy",
                            description: Text("Be the first to create one!")
                        )
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                // Featured banner
                                let featured = challenges.filter(\.isFeatured)
                                if !featured.isEmpty {
                                    FeaturedChallengesBanner(challenges: featured) { c in
                                        selectedChallenge = c
                                    }
                                    .padding(.vertical, 12)
                                }

                                // Full list
                                ForEach(challenges) { challenge in
                                    ChallengeRow(challenge: challenge) {
                                        selectedChallenge = challenge
                                    }
                                    Divider().overlay(.white.opacity(0.08))
                                }
                            }
                            .padding(.bottom, 20)
                        }
                    }
                }
            }
            .navigationTitle("Challenges 🏆")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showCreate = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.cyan)
                    }
                }
            }
            .sheet(item: $selectedChallenge) { challenge in
                ChallengeDetailView(challenge: challenge)
            }
            .sheet(isPresented: $showCreate) {
                CreateChallengeView { Task { await load() } }
            }
        }
        .preferredColorScheme(.dark)
        .task { await load() }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            struct Resp: Decodable { let challenges: [Challenge] }
            var path = "/api/v1/challenges"
            if let cat = selectedCategory { path += "?category=\(cat)" }
            let resp: Resp = try await APIClient.shared.get(path, base: APIClient.shared.goBase)
            challenges = resp.challenges
        } catch {
            print("Challenges load error: \(error)")
        }
    }
}

// MARK: - Featured Banner

struct FeaturedChallengesBanner: View {
    let challenges: [Challenge]
    let onTap: (Challenge) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "star.fill").foregroundStyle(.yellow)
                Text("Featured").font(.system(size: 15, weight: .bold)).foregroundStyle(.white)
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(challenges) { c in
                        FeaturedChallengeCard(challenge: c) { onTap(c) }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct FeaturedChallengeCard: View {
    let challenge: Challenge
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottomLeading) {
                AsyncImage(url: challenge.thumbnailURL) { img in
                    img.resizable().scaledToFill()
                } placeholder: {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing))
                }
                .frame(width: 200, height: 130)
                .clipShape(RoundedRectangle(cornerRadius: 18))

                LinearGradient(colors: [.clear, .black.opacity(0.85)], startPoint: .top, endPoint: .bottom)
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                VStack(alignment: .leading, spacing: 3) {
                    Text(challenge.hashtag)
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundStyle(.white)
                    Text("\(challenge.participantCount.abbreviated) participants")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .padding(12)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Challenge Row

struct ChallengeRow: View {
    let challenge: Challenge
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                AsyncImage(url: challenge.thumbnailURL) { img in
                    img.resizable().scaledToFill()
                } placeholder: {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(LinearGradient(colors: [.purple.opacity(0.5), .pink.opacity(0.5)],
                                            startPoint: .topLeading, endPoint: .bottomTrailing))
                }
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 6) {
                        Text(challenge.hashtag)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                        if challenge.isFeatured {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundStyle(.yellow)
                        }
                    }
                    Text(challenge.title)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    HStack(spacing: 10) {
                        Label(challenge.participantCount.abbreviated, systemImage: "person.2.fill")
                        Label(challenge.viewCount.abbreviated, systemImage: "eye.fill")
                        if let ends = challenge.endsAt {
                            Label(ends.relativeShort, systemImage: "clock")
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Challenge Detail Sheet

struct ChallengeDetailView: View {
    let challenge: Challenge
    @State private var leaderboard: [LeaderboardEntry] = []
    @State private var hasJoined = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        VStack(spacing: 8) {
                            Text(challenge.hashtag)
                                .font(.system(size: 28, weight: .heavy))
                                .foregroundStyle(.white)
                            if let desc = challenge.description {
                                Text(desc)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            HStack(spacing: 16) {
                                Label(challenge.participantCount.abbreviated, systemImage: "person.2.fill")
                                Label(challenge.viewCount.abbreviated, systemImage: "eye.fill")
                            }
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        }

                        // Join button
                        PrimaryButton(
                            label: hasJoined ? "Joined ✓" : "Join Challenge",
                            icon: hasJoined ? "checkmark" : "trophy.fill",
                            color: hasJoined ? .gray : .cyan
                        ) {
                            Task { await joinChallenge() }
                        }
                        .disabled(hasJoined)

                        // Leaderboard
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Leaderboard", systemImage: "list.number")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.yellow)
                            ForEach(leaderboard) { entry in
                                LeaderboardRow(entry: entry)
                            }
                        }
                        .padding(16)
                        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 18))
                    }
                    .padding()
                }
            }
            .navigationTitle("Challenge")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }.foregroundStyle(.cyan)
                }
            }
        }
        .preferredColorScheme(.dark)
        .task { await loadLeaderboard() }
    }

    private func loadLeaderboard() async {
        do {
            struct Resp: Decodable { let leaderboard: [LeaderboardEntry] }
            let resp: Resp = try await APIClient.shared.get(
                "/api/v1/challenges/\(challenge.id)/leaderboard", base: APIClient.shared.goBase
            )
            leaderboard = resp.leaderboard
        } catch {}
    }

    private func joinChallenge() async {
        struct JoinReq: Encodable { let profile_id: String }
        struct JoinResp: Decodable { let ok: Bool }
        let resp: JoinResp? = try? await APIClient.shared.post(
            "/api/v1/challenges/\(challenge.id)/join",
            body: JoinReq(profile_id: "demo"),
            base: APIClient.shared.goBase
        )
        if resp?.ok == true { hasJoined = true }
    }
}

struct LeaderboardRow: View {
    let entry: LeaderboardEntry
    var rankColor: Color {
        switch entry.rank {
        case 1: return .yellow
        case 2: return Color(hex: "#C0C0C0") ?? .white
        case 3: return Color(hex: "#CD7F32") ?? .orange
        default: return .secondary
        }
    }
    var body: some View {
        HStack(spacing: 12) {
            Text("#\(entry.rank)")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(rankColor)
                .frame(width: 32)

            AsyncImage(url: entry.avatarURL) { img in img.resizable().scaledToFill() }
            placeholder: { Circle().fill(.white.opacity(0.1)) }
                .frame(width: 36, height: 36)
                .clipShape(Circle())

            Text(entry.username)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
            Spacer()
            Label(entry.likes.abbreviated, systemImage: "heart.fill")
                .font(.caption)
                .foregroundStyle(.pink)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Create Challenge Sheet

struct CreateChallengeView: View {
    let onCreated: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var hashtag = ""
    @State private var description = ""
    @State private var category = "general"
    @State private var isCreating = false
    @State private var errorMsg: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                Form {
                    Section("Challenge Name") {
                        TextField("e.g. Dorm Room DJ Battle", text: $title)
                            .foregroundStyle(.white)
                    }
                    .listRowBackground(Color.white.opacity(0.05))

                    Section("Hashtag") {
                        HStack {
                            Text("#").foregroundStyle(.secondary)
                            TextField("DormRoomDJ", text: $hashtag)
                                .foregroundStyle(.white)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                        }
                    }
                    .listRowBackground(Color.white.opacity(0.05))

                    Section("Description (optional)") {
                        TextField("What should participants do?", text: $description, axis: .vertical)
                            .foregroundStyle(.white)
                            .lineLimit(3, reservesSpace: true)
                    }
                    .listRowBackground(Color.white.opacity(0.05))

                    Section("Category") {
                        Picker("Category", selection: $category) {
                            ForEach(["dance","comedy","study","music","sports","fashion","gaming","food","travel","general"], id: \.self) {
                                Text($0.capitalized).tag($0)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(.cyan)
                    }
                    .listRowBackground(Color.white.opacity(0.05))

                    if let err = errorMsg {
                        Section { Text(err).foregroundStyle(.red) }
                            .listRowBackground(Color.clear)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("New Challenge")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isCreating ? "Creating..." : "Create") {
                        Task { await create() }
                    }
                    .foregroundStyle(title.isEmpty || hashtag.isEmpty ? .secondary : .cyan)
                    .disabled(title.isEmpty || hashtag.isEmpty || isCreating)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func create() async {
        isCreating = true
        defer { isCreating = false }
        struct CreateReq: Encodable {
            let creator_id, title, hashtag, description, category: String
        }
        struct CreateResp: Decodable { let ok: Bool }
        do {
            let resp: CreateResp = try await APIClient.shared.post(
                "/api/v1/challenges",
                body: CreateReq(creator_id: "demo", title: title,
                                hashtag: hashtag, description: description, category: category),
                base: APIClient.shared.goBase
            )
            if resp.ok { onCreated(); dismiss() }
        } catch {
            errorMsg = error.localizedDescription
        }
    }
}

// PrimaryButton defined in DubPanelView.swift

// MARK: - Category Chip

struct CategoryChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? Color.cyan.opacity(0.25) : Color.white.opacity(0.07))
                .foregroundStyle(isSelected ? .cyan : .secondary)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(isSelected ? Color.cyan : .clear, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

// Date.relativeShort defined in Core/Extensions.swift
