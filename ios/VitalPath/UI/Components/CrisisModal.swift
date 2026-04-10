// CrisisModal.swift — VitalPath AI
// Full-screen crisis escalation overlay with localized resources.
// Zero PHI stored — only displays and provides immediate help.

import SwiftUI

// MARK: - Crisis Resource Model

struct CrisisResource: Equatable {
    let country: String
    let hotline: String
    let name: String
    let url: String?
}

// MARK: - Crisis Modal

struct CrisisModal: View {
    @Binding var isPresented: Bool
    let resource: CrisisResource

    @State private var animate = false
    @State private var pulseHeart = false
    @State private var showContent = false

    var body: some View {
        ZStack {
            // Blurred backdrop
            Rectangle()
                .fill(.black.opacity(0.75))
                .ignoresSafeArea()
                .onTapGesture {} // Prevent dismissal by tapping outside

            VStack(spacing: 0) {
                Spacer()

                // Card
                VStack(spacing: AppSpacing.lg) {
                    // Header icon
                    ZStack {
                        Circle()
                            .fill(AppGradient.crisis)
                            .frame(width: 80, height: 80)
                            .shadow(color: Color.wellnessCrisis.opacity(0.5), radius: 20, x: 0, y: 0)
                            .scaleEffect(pulseHeart ? 1.08 : 1.0)

                        Image(systemName: "heart.fill")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulseHeart)

                    // Message
                    VStack(spacing: AppSpacing.sm) {
                        Text("You are not alone")
                            .font(AppFont.display(26))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)

                        Text("It sounds like you might be going through a really difficult time. Please reach out — help is available right now.")
                            .font(AppFont.body())
                            .foregroundStyle(.white.opacity(0.85))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }

                    // Hotline card
                    GlowingGlassCard(glowColor: .wellnessCrisis) {
                        VStack(spacing: AppSpacing.sm) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(resource.name)
                                        .font(AppFont.caption(13))
                                        .foregroundStyle(.white.opacity(0.7))
                                    Text(resource.country)
                                        .font(AppFont.caption(12))
                                        .foregroundStyle(.white.opacity(0.5))
                                }
                                Spacer()
                                Image(systemName: "phone.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundStyle(Color.wellnessCrisis)
                            }

                            // Call button
                            Button(action: callHotline) {
                                HStack(spacing: 10) {
                                    Image(systemName: "phone.fill")
                                        .font(.system(size: 18, weight: .semibold))
                                    Text(resource.hotline)
                                        .font(AppFont.title(22))
                                        .fontWeight(.bold)
                                    Spacer()
                                    Text("Call Now")
                                        .font(AppFont.caption(13))
                                        .fontWeight(.semibold)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 7)
                                        .background(Capsule().fill(Color.wellnessCrisis))
                                }
                                .foregroundStyle(.white)
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // Additional options
                    VStack(spacing: 12) {
                        // Text / Chat option
                        HStack(spacing: 12) {
                            Image(systemName: "message.fill")
                                .foregroundStyle(.vitaTeal)
                            Text("You can also text or chat online for support")
                                .font(AppFont.body(15))
                                .foregroundStyle(.white.opacity(0.75))
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background {
                            RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                                .fill(Color.vitaTeal.opacity(0.12))
                                .overlay {
                                    RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                                        .stroke(Color.vitaTeal.opacity(0.25), lineWidth: 1)
                                }
                        }
                    }

                    // Dismiss (only after showing for 3s)
                    if showContent {
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation(AppAnimation.smooth) { isPresented = false }
                        }) {
                            Text("I'm safe — go back")
                                .font(AppFont.body(15))
                                .foregroundStyle(.white.opacity(0.55))
                                .underline()
                        }
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
                .padding(AppSpacing.lg)
                .background {
                    RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.10, green: 0.04, blue: 0.22),
                                    Color(red: 0.18, green: 0.04, blue: 0.16),
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                                .stroke(Color.wellnessCrisis.opacity(0.4), lineWidth: 1.5)
                        }
                        .shadow(color: Color.wellnessCrisis.opacity(0.3), radius: 40, x: 0, y: -10)
                }
                .padding(.horizontal, AppSpacing.md)
                .offset(y: animate ? 0 : 80)
                .opacity(animate ? 1 : 0)

                Spacer().frame(height: AppSpacing.xl)
            }
        }
        .onAppear {
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            withAnimation(AppAnimation.entrance) { animate = true }
            pulseHeart = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                withAnimation(AppAnimation.smooth) { showContent = true }
            }
        }
    }

    private func callHotline() {
        let cleaned = resource.hotline.replacingOccurrences(of: "-", with: "")
        if let url = URL(string: "tel://\(cleaned)") {
            UIApplication.shared.open(url)
        }
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }
}

// MARK: - Crisis Banner (inline, less intrusive)

struct CrisisBanner: View {
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "heart.fill")
                    .foregroundStyle(Color.wellnessCrisis)
                    .font(.system(size: 20))
                VStack(alignment: .leading, spacing: 2) {
                    Text("You're not alone")
                        .font(AppFont.body(15)).fontWeight(.semibold)
                        .foregroundStyle(.white)
                    Text("Tap to see crisis support resources")
                        .font(AppFont.caption(12))
                        .foregroundStyle(.white.opacity(0.65))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.white.opacity(0.4))
                    .font(.system(size: 14, weight: .semibold))
            }
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .fill(Color.wellnessCrisis.opacity(0.18))
                    .overlay {
                        RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                            .stroke(Color.wellnessCrisis.opacity(0.45), lineWidth: 1.5)
                    }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    CrisisModal(
        isPresented: .constant(true),
        resource: CrisisResource(
            country: "US",
            hotline: "988",
            name: "Suicide & Crisis Lifeline",
            url: "https://988lifeline.org"
        )
    )
}
