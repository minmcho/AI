// GlassCard.swift — VitalPath AI
// Frosted-glass card component with gradient border shimmer.

import SwiftUI

// MARK: - Glass Card

struct GlassCard<Content: View>: View {
    let content: Content
    var cornerRadius: CGFloat
    var material: Material
    var borderOpacity: Double
    var hasShadow: Bool
    var padding: EdgeInsets

    init(
        cornerRadius: CGFloat = AppRadius.md,
        material: Material = .ultraThinMaterial,
        borderOpacity: Double = 0.35,
        hasShadow: Bool = true,
        padding: EdgeInsets = EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20),
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.cornerRadius = cornerRadius
        self.material = material
        self.borderOpacity = borderOpacity
        self.hasShadow = hasShadow
        self.padding = padding
    }

    var body: some View {
        content
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(material)
                    .overlay {
                        // Gradient border shimmer
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(borderOpacity),
                                        Color.white.opacity(borderOpacity * 0.2),
                                        Color.vitaTeal.opacity(borderOpacity * 0.4),
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.2
                            )
                    }
                    .if(hasShadow) { view in
                        view.shadow(color: .black.opacity(0.22), radius: 24, x: 0, y: 12)
                    }
            }
    }
}

// MARK: - Highlighted Glass Card (glowing border)

struct GlowingGlassCard<Content: View>: View {
    let content: Content
    var glowColor: Color
    var cornerRadius: CGFloat

    init(
        glowColor: Color = .vitaTeal,
        cornerRadius: CGFloat = AppRadius.md,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.glowColor = glowColor
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        content
            .padding(20)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(glowColor.opacity(0.6), lineWidth: 1.5)
                    }
                    .shadow(color: glowColor.opacity(0.40), radius: 20, x: 0, y: 0)
                    .shadow(color: .black.opacity(0.18), radius: 12, x: 0, y: 6)
            }
    }
}

// MARK: - Shimmer effect modifier

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { geo in
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.18), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 2)
                    .offset(x: -geo.size.width + (geo.size.width * 2) * phase)
                }
                .clipped()
            }
            .onAppear {
                withAnimation(Animation.linear(duration: 1.8).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmer() -> some View { modifier(ShimmerModifier()) }

    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition { transform(self) } else { self }
    }
}

// MARK: - Previews

#Preview {
    ZStack {
        AppGradient.background.ignoresSafeArea()
        VStack(spacing: 20) {
            GlassCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Glass Card").font(AppFont.title()).foregroundStyle(.white)
                    Text("Frosted material with gradient border shimmer")
                        .font(AppFont.body()).foregroundStyle(.white.opacity(0.7))
                }
            }
            GlowingGlassCard(glowColor: .vitaTeal) {
                Text("Glowing Card").font(AppFont.title()).foregroundStyle(.white)
            }
        }
        .padding()
    }
}
