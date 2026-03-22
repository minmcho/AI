import SwiftUI

struct ProfileView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 24) {
                    // Avatar
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [.purple, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 90, height: 90)
                        Image(systemName: "person.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(.white)
                    }

                    VStack(spacing: 6) {
                        Text("@you")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white)
                        Text("OpenClaw Video Feed Member")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    // Stats
                    HStack(spacing: 36) {
                        StatItem(value: "128", label: "Videos")
                        StatItem(value: "4.2K", label: "Likes")
                        StatItem(value: "890", label: "Following")
                    }

                    Spacer()
                }
                .padding(.top, 40)
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }
}

struct StatItem: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
