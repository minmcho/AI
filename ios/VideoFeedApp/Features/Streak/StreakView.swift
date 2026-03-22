import SwiftUI

/// Full streak & XP profile screen — teen engagement hub.
struct StreakView: View {
    @State private var streakData:  StreakData?
    @State private var leaderboard: [LeaderboardEntry] = []
    @State private var badges:      [String: BadgeDef] = [:]
    @State private var isLoading    = false

    private let profileID = "demo"

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {

                        if isLoading || streakData == nil {
                            ProgressView().frame(maxWidth: .infinity, minHeight: 200)
                        } else if let data = streakData {
                            // ── Flame card ────────────────────────────────────
                            StreakFlameCard(data: data)

                            // ── XP Progress bar ───────────────────────────────
                            XPProgressCard(data: data)

                            // ── Badge shelf ───────────────────────────────────
                            BadgeShelfView(earnedBadges: data.badges, allBadges: badges)

                            // ── Leaderboard ───────────────────────────────────
                            GlobalLeaderboardView(entries: leaderboard, myProfileID: profileID)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("My Streak 🔥")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
        .task {
            await loadAll()
        }
    }

    private func loadAll() async {
        isLoading = true
        defer { isLoading = false }
        async let streakFetch: StreakData = (try? APIClient.shared.get("/api/v1/streak/\(profileID)", base: APIClient.shared.goBase)) ?? StreakData.empty
        async let lbFetch: [LeaderboardEntry] = {
            struct Resp: Decodable { let leaderboard: [LeaderboardEntry] }
            let r: Resp? = try? await APIClient.shared.get("/api/v1/streak/\(profileID)/leaderboard", base: APIClient.shared.goBase)
            return r?.leaderboard ?? []
        }()
        async let badgeFetch: [String: BadgeDef] = {
            struct Resp: Decodable { let badges: [String: BadgeDef] }
            let r: Resp? = try? await APIClient.shared.get("/api/v1/badges", base: APIClient.shared.goBase)
            return r?.badges ?? [:]
        }()
        (streakData, leaderboard, badges) = await (streakFetch, lbFetch, badgeFetch)
    }
}

// MARK: - Flame Card

struct StreakFlameCard: View {
    let data: StreakData

    var body: some View {
        VStack(spacing: 14) {
            // Animated flame stack
            ZStack {
                Text("🔥")
                    .font(.system(size: 72))
                    .shadow(color: .orange.opacity(0.8), radius: 20)

                Text("\(data.streakDays)")
                    .font(.system(size: 36, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .offset(y: 20)
            }
            .frame(height: 100)

            Text("\(data.streakDays) Day Streak")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)

            Text("Best: \(data.longestStreak) days")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // Level badge
            HStack(spacing: 8) {
                Text("Level \(data.level)")
                    .font(.system(size: 14, weight: .heavy))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(LinearGradient(colors: [.purple, .cyan], startPoint: .leading, endPoint: .trailing))
                    .foregroundStyle(.white)
                    .clipShape(Capsule())

                Text(data.levelTitle)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            LinearGradient(colors: [.orange.opacity(0.15), .red.opacity(0.05)],
                          startPoint: .top, endPoint: .bottom)
        )
        .background(.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(.orange.opacity(0.25), lineWidth: 1))
    }
}

// MARK: - XP Progress

struct XPProgressCard: View {
    let data: StreakData

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("XP Progress", systemImage: "bolt.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.yellow)
                Spacer()
                Text("\(data.totalXP) XP")
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundStyle(.yellow)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8).fill(.white.opacity(0.1))
                    RoundedRectangle(cornerRadius: 8)
                        .fill(LinearGradient(colors: [.yellow, .orange], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * data.xpProgress)
                        .animation(.easeOut(duration: 0.8), value: data.xpProgress)
                }
            }
            .frame(height: 12)

            HStack {
                Text("Level \(data.level)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(data.nextLevelXP) XP → Level \(data.level + 1)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // XP actions hint
            HStack(spacing: 6) {
                XPHint(label: "Watch", xp: 10, icon: "play.fill")
                XPHint(label: "Share", xp: 15, icon: "square.and.arrow.up")
                XPHint(label: "Study", xp: 50, icon: "book.fill")
                XPHint(label: "Challenge", xp: 50, icon: "trophy.fill")
            }
        }
        .padding(16)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(.yellow.opacity(0.15), lineWidth: 1))
    }
}

struct XPHint: View {
    let label: String
    let xp: Int
    let icon: String
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.caption).foregroundStyle(.yellow)
            Text("+\(xp)").font(.system(size: 11, weight: .bold)).foregroundStyle(.yellow)
            Text(label).font(.system(size: 9)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(.yellow.opacity(0.07), in: RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Badge Shelf

struct BadgeShelfView: View {
    let earnedBadges: [String]
    let allBadges:    [String: BadgeDef]

    private let allKnown = ["first_watch", "week_warrior", "monthly_legend",
                            "challenge_champ", "study_grind", "vibe_master", "lofi_lord"]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Badges", systemImage: "rosette")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.cyan)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 14) {
                ForEach(allKnown, id: \.self) { badgeID in
                    let def = allBadges[badgeID]
                    let earned = earnedBadges.contains(badgeID)
                    BadgeCell(
                        emoji: def?.emoji ?? "🏅",
                        label: def?.label ?? badgeID,
                        earned: earned
                    )
                }
            }
        }
        .padding(16)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(.cyan.opacity(0.15), lineWidth: 1))
    }
}

struct BadgeCell: View {
    let emoji: String
    let label: String
    let earned: Bool

    var body: some View {
        VStack(spacing: 6) {
            Text(emoji)
                .font(.system(size: 28))
                .opacity(earned ? 1 : 0.2)
                .grayscale(earned ? 0 : 1)
                .shadow(color: earned ? .yellow.opacity(0.5) : .clear, radius: 8)
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(earned ? .white : .secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Global Leaderboard

struct GlobalLeaderboardView: View {
    let entries: [LeaderboardEntry]
    let myProfileID: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Global Leaderboard", systemImage: "list.number")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.yellow)

            if entries.isEmpty {
                Text("No data yet — watch videos to earn XP!")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(entries.prefix(10)) { entry in
                    LeaderboardRow(entry: entry)
                }
            }
        }
        .padding(16)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(.yellow.opacity(0.15), lineWidth: 1))
    }
}

// MARK: - Empty / fallback

extension StreakData {
    static let empty = StreakData(
        streakDays: 0, longestStreak: 0, totalXP: 0,
        level: 1, levelTitle: "Newbie", badges: [],
        nextLevelXP: 50, xpProgress: 0, lastActive: ""
    )
}

// MARK: - Compact widget for feed overlay

struct StreakWidgetBadge: View {
    let streakDays: Int
    let level: Int

    var body: some View {
        HStack(spacing: 5) {
            Text("🔥")
            Text("\(streakDays)")
                .font(.system(size: 13, weight: .heavy))
                .foregroundStyle(.orange)
            Text("·")
                .foregroundStyle(.secondary)
            Text("Lv\(level)")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.yellow)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(.black.opacity(0.6), in: Capsule())
    }
}
