// AnimatedButton.swift — VitalPath AI
// Reusable button styles with haptic feedback and glass aesthetics.

import SwiftUI

// MARK: - Primary Glass Button

struct PrimaryGlassButton: View {
    let title: String
    var icon: String?
    var isLoading: Bool = false
    var gradient: LinearGradient = AppGradient.primaryButton
    var action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            haptic(.medium)
            action()
        }) {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                        .scaleEffect(0.85)
                } else {
                    if let icon {
                        Image(systemName: icon)
                            .font(.system(size: 17, weight: .semibold))
                    }
                    Text(title)
                        .font(AppFont.body(17))
                        .fontWeight(.semibold)
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background {
                RoundedRectangle(cornerRadius: AppRadius.pill, style: .continuous)
                    .fill(gradient)
                    .overlay {
                        RoundedRectangle(cornerRadius: AppRadius.pill, style: .continuous)
                            .stroke(Color.white.opacity(0.25), lineWidth: 1)
                    }
                    .shadow(color: Color.vitaPurple.opacity(0.45), radius: 16, x: 0, y: 8)
            }
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .opacity(isLoading ? 0.75 : 1.0)
        }
        .buttonStyle(.plain)
        ._onButtonGesture(pressing: { pressing in
            withAnimation(AppAnimation.quick) { isPressed = pressing }
        }, perform: {})
        .disabled(isLoading)
    }
}

// MARK: - Glass Icon Button

struct GlassIconButton: View {
    let icon: String
    var size: CGFloat = 48
    var iconSize: CGFloat = 22
    var color: Color = .white
    var badgeCount: Int = 0
    var action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            haptic(.light)
            action()
        }) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: icon)
                    .font(.system(size: iconSize, weight: .medium))
                    .foregroundStyle(color)
                    .frame(width: size, height: size)
                    .background {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .overlay {
                                Circle().stroke(Color.white.opacity(0.25), lineWidth: 1)
                            }
                            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                    }
                    .scaleEffect(isPressed ? 0.92 : 1.0)

                if badgeCount > 0 {
                    Text("\(min(badgeCount, 99))")
                        .font(AppFont.caption(11))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5)
                        .background(Capsule().fill(Color.wellnessCrisis))
                        .offset(x: 4, y: -4)
                }
            }
        }
        .buttonStyle(.plain)
        ._onButtonGesture(pressing: { pressing in
            withAnimation(AppAnimation.quick) { isPressed = pressing }
        }, perform: {})
    }
}

// MARK: - Quick Action Pill

struct QuickActionPill: View {
    let title: String
    let icon: String
    var gradient: LinearGradient = AppGradient.primaryButton
    var action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            haptic(.light)
            action()
        }) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(gradient)
                        .frame(width: 56, height: 56)
                        .shadow(color: Color.vitaPurple.opacity(0.35), radius: 10, x: 0, y: 5)
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(.white)
                }
                Text(title)
                    .font(AppFont.caption(12))
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(width: 80)
            .scaleEffect(isPressed ? 0.94 : 1.0)
        }
        .buttonStyle(.plain)
        ._onButtonGesture(pressing: { pressing in
            withAnimation(AppAnimation.bouncy) { isPressed = pressing }
        }, perform: {})
    }
}

// MARK: - Mood rating button

struct MoodButton: View {
    let emoji: String
    let label: String
    let value: Int
    @Binding var selected: Int?

    var isSelected: Bool { selected == value }

    var body: some View {
        Button(action: {
            haptic(.selection)
            withAnimation(AppAnimation.bouncy) { selected = value }
        }) {
            VStack(spacing: 6) {
                Text(emoji)
                    .font(.system(size: isSelected ? 36 : 28))
                    .scaleEffect(isSelected ? 1.15 : 1.0)
                Text(label)
                    .font(AppFont.caption(11))
                    .foregroundStyle(isSelected ? .white : .white.opacity(0.55))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background {
                RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                    .fill(isSelected ? Color.white.opacity(0.20) : .clear)
                    .overlay {
                        RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                            .stroke(
                                isSelected ? Color.vitaTeal.opacity(0.6) : Color.white.opacity(0.1),
                                lineWidth: isSelected ? 1.5 : 1
                            )
                    }
            }
            .animation(AppAnimation.spring, value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Haptic helper

private func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
    UIImpactFeedbackGenerator(style: style).impactOccurred()
}

private extension UISelectionFeedbackGenerator {
    static func fire() { UISelectionFeedbackGenerator().selectionChanged() }
}

private func haptic(_ type: HapticType) {
    switch type {
    case .light:     UIImpactFeedbackGenerator(style: .light).impactOccurred()
    case .medium:    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    case .heavy:     UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    case .selection: UISelectionFeedbackGenerator().selectionChanged()
    case .success:   UINotificationFeedbackGenerator().notificationOccurred(.success)
    case .warning:   UINotificationFeedbackGenerator().notificationOccurred(.warning)
    case .error:     UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
}

enum HapticType { case light, medium, heavy, selection, success, warning, error }

// MARK: - Previews

#Preview {
    ZStack {
        AppGradient.background.ignoresSafeArea()
        VStack(spacing: 24) {
            PrimaryGlassButton(title: "Start Coaching", icon: "sparkles") {}
            PrimaryGlassButton(title: "Loading…", isLoading: true) {}
            HStack(spacing: 16) {
                GlassIconButton(icon: "bell.fill", badgeCount: 3) {}
                GlassIconButton(icon: "person.crop.circle", color: .vitaTeal) {}
            }
            HStack(spacing: 8) {
                QuickActionPill(title: "Chat", icon: "bubble.left.fill") {}
                QuickActionPill(title: "Analyze", icon: "camera.fill",
                                gradient: AppGradient.wellnessScore) {}
                QuickActionPill(title: "Meditate", icon: "leaf.fill",
                                gradient: AppGradient.streak) {}
            }
        }
        .padding()
    }
}
