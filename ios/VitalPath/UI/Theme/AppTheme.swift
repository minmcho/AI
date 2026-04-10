// AppTheme.swift — VitalPath AI
// Apple Glass UI design system: colours, gradients, typography, spacing.

import SwiftUI

// MARK: - Brand Palette

extension Color {
    // Primary gradient spectrum
    static let vitaPurple       = Color(red: 0.45, green: 0.27, blue: 0.95)
    static let vitaIndigo       = Color(red: 0.35, green: 0.45, blue: 0.98)
    static let vitaTeal         = Color(red: 0.20, green: 0.82, blue: 0.80)
    static let vitaMint         = Color(red: 0.35, green: 0.95, blue: 0.78)

    // Accent
    static let vitaCoral        = Color(red: 1.00, green: 0.42, blue: 0.55)
    static let vitaGold         = Color(red: 1.00, green: 0.80, blue: 0.30)
    static let vitaLavender     = Color(red: 0.72, green: 0.62, blue: 1.00)

    // Glass surface
    static let glassWhite       = Color.white.opacity(0.15)
    static let glassBorder      = Color.white.opacity(0.35)
    static let glassShadow      = Color.black.opacity(0.18)

    // Semantic
    static let wellnessSafe     = Color(red: 0.20, green: 0.88, blue: 0.65)
    static let wellnessCaution  = Color(red: 1.00, green: 0.75, blue: 0.20)
    static let wellnessCrisis   = Color(red: 1.00, green: 0.28, blue: 0.38)
    static let wellnessText     = Color.white
    static let wellnessSubtext  = Color.white.opacity(0.72)
}

// MARK: - Gradient Catalogue

struct AppGradient {

    // Background mesh — 3-stop diagonal
    static let background = LinearGradient(
        stops: [
            .init(color: Color(red: 0.08, green: 0.05, blue: 0.22), location: 0.00),
            .init(color: Color(red: 0.12, green: 0.08, blue: 0.38), location: 0.50),
            .init(color: Color(red: 0.05, green: 0.18, blue: 0.32), location: 1.00),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Card glass shimmer
    static let glassCard = LinearGradient(
        colors: [Color.white.opacity(0.22), Color.white.opacity(0.06)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Button primary
    static let primaryButton = LinearGradient(
        colors: [.vitaPurple, .vitaIndigo],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Streak fire
    static let streak = LinearGradient(
        colors: [.vitaGold, .vitaCoral],
        startPoint: .top,
        endPoint: .bottom
    )

    // Wellness score
    static let wellnessScore = LinearGradient(
        colors: [.vitaTeal, .vitaMint],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Crisis / alert
    static let crisis = LinearGradient(
        colors: [.wellnessCrisis, Color(red: 0.80, green: 0.10, blue: 0.20)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Orb glow (home decorative)
    static let purpleOrb = RadialGradient(
        colors: [Color.vitaPurple.opacity(0.7), .clear],
        center: .center,
        startRadius: 5,
        endRadius: 180
    )

    static let tealOrb = RadialGradient(
        colors: [Color.vitaTeal.opacity(0.5), .clear],
        center: .center,
        startRadius: 5,
        endRadius: 140
    )
}

// MARK: - Typography

struct AppFont {
    // Display
    static func display(_ size: CGFloat = 34) -> Font { .system(size: size, weight: .bold, design: .rounded) }
    // Title
    static func title(_ size: CGFloat = 22) -> Font   { .system(size: size, weight: .semibold, design: .rounded) }
    // Body
    static func body(_ size: CGFloat = 17) -> Font    { .system(size: size, weight: .regular, design: .rounded) }
    // Caption
    static func caption(_ size: CGFloat = 13) -> Font { .system(size: size, weight: .medium, design: .rounded) }
    // Mono (numbers)
    static func mono(_ size: CGFloat = 17) -> Font    { .system(size: size, weight: .semibold, design: .monospaced) }
}

// MARK: - Spacing

struct AppSpacing {
    static let xs:  CGFloat = 4
    static let sm:  CGFloat = 8
    static let md:  CGFloat = 16
    static let lg:  CGFloat = 24
    static let xl:  CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Corner Radius

struct AppRadius {
    static let sm:  CGFloat = 12
    static let md:  CGFloat = 20
    static let lg:  CGFloat = 28
    static let xl:  CGFloat = 36
    static let pill: CGFloat = 999
}

// MARK: - Shadow

struct AppShadow {
    static let card   = ShadowStyle(color: .black.opacity(0.22), radius: 24, x: 0, y: 12)
    static let button = ShadowStyle(color: Color.vitaPurple.opacity(0.45), radius: 16, x: 0, y: 8)
    static let glow   = ShadowStyle(color: Color.vitaTeal.opacity(0.55), radius: 20, x: 0, y: 0)
}

struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

extension View {
    func appShadow(_ style: ShadowStyle) -> some View {
        self.shadow(color: style.color, radius: style.radius, x: style.x, y: style.y)
    }
}

// MARK: - Animation Presets

struct AppAnimation {
    static let spring    = Animation.spring(response: 0.52, dampingFraction: 0.78, blendDuration: 0)
    static let bouncy    = Animation.spring(response: 0.45, dampingFraction: 0.65, blendDuration: 0)
    static let smooth    = Animation.easeInOut(duration: 0.35)
    static let quick     = Animation.easeOut(duration: 0.22)
    static let entrance  = Animation.spring(response: 0.60, dampingFraction: 0.80, blendDuration: 0)
}
