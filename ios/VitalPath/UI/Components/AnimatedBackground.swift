// AnimatedBackground.swift — VitalPath AI
// Animated mesh gradient background with floating orbs and particle system.

import SwiftUI

// MARK: - Animated Mesh Background

struct AnimatedMeshBackground: View {
    @State private var animateOrb1 = false
    @State private var animateOrb2 = false
    @State private var animateOrb3 = false
    @State private var rotationAngle: Double = 0

    var body: some View {
        ZStack {
            // Base gradient
            AppGradient.background
                .ignoresSafeArea()

            // Floating orb 1 — Purple
            Ellipse()
                .fill(AppGradient.purpleOrb)
                .frame(width: 360, height: 360)
                .offset(
                    x: animateOrb1 ? -60 : -100,
                    y: animateOrb1 ? -180 : -220
                )
                .blur(radius: 30)
                .animation(
                    Animation.easeInOut(duration: 7).repeatForever(autoreverses: true),
                    value: animateOrb1
                )

            // Floating orb 2 — Teal
            Ellipse()
                .fill(AppGradient.tealOrb)
                .frame(width: 280, height: 280)
                .offset(
                    x: animateOrb2 ? 140 : 100,
                    y: animateOrb2 ? 200 : 260
                )
                .blur(radius: 25)
                .animation(
                    Animation.easeInOut(duration: 9).repeatForever(autoreverses: true),
                    value: animateOrb2
                )

            // Floating orb 3 — Indigo (subtle)
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [Color.vitaIndigo.opacity(0.45), .clear],
                        center: .center, startRadius: 5, endRadius: 120
                    )
                )
                .frame(width: 240, height: 240)
                .offset(
                    x: animateOrb3 ? 60 : 80,
                    y: animateOrb3 ? -60 : -20
                )
                .blur(radius: 20)
                .animation(
                    Animation.easeInOut(duration: 11).repeatForever(autoreverses: true),
                    value: animateOrb3
                )

            // Rotating star-burst highlight (top-right corner)
            Image(systemName: "sparkle")
                .font(.system(size: 200, weight: .ultraLight))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.white.opacity(0.04), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .rotationEffect(.degrees(rotationAngle))
                .offset(x: 120, y: -260)
                .animation(
                    Animation.linear(duration: 30).repeatForever(autoreverses: false),
                    value: rotationAngle
                )
        }
        .onAppear {
            animateOrb1 = true
            animateOrb2 = true
            animateOrb3 = true
            rotationAngle = 360
        }
    }
}

// MARK: - Particle emitter

struct ParticleSystem: View {
    let count: Int
    @State private var particles: [Particle] = []
    @State private var timer: Timer?

    struct Particle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var scale: CGFloat
        var opacity: Double
        var speed: Double
        var color: Color
    }

    init(count: Int = 20) {
        self.count = count
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { p in
                    Circle()
                        .fill(p.color)
                        .frame(width: 4 * p.scale, height: 4 * p.scale)
                        .opacity(p.opacity)
                        .position(x: p.x, y: p.y)
                }
            }
            .onAppear {
                spawnParticles(in: geo.size)
            }
        }
        .allowsHitTesting(false)
    }

    private func spawnParticles(in size: CGSize) {
        particles = (0..<count).map { _ in
            Particle(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height),
                scale: CGFloat.random(in: 0.5...2.0),
                opacity: Double.random(in: 0.1...0.4),
                speed: Double.random(in: 4...10),
                color: [Color.vitaTeal, .vitaMint, .vitaLavender, .white].randomElement()!
            )
        }
        animateParticles(in: size)
    }

    private func animateParticles(in size: CGSize) {
        for i in particles.indices {
            let delay = Double.random(in: 0...3)
            withAnimation(
                Animation.easeInOut(duration: particles[i].speed)
                    .repeatForever(autoreverses: true)
                    .delay(delay)
            ) {
                particles[i].y -= CGFloat.random(in: 40...120)
                particles[i].opacity = Double.random(in: 0.05...0.35)
            }
        }
    }
}

// MARK: - Achievement burst animation

struct AchievementBurst: View {
    @State private var showBurst = false
    var color: Color = .vitaGold
    var onComplete: (() -> Void)?

    var body: some View {
        ZStack {
            ForEach(0..<12, id: \.self) { i in
                let angle = Double(i) * 30.0
                Image(systemName: "star.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(color)
                    .offset(
                        x: showBurst ? cos(angle * .pi / 180) * 80 : 0,
                        y: showBurst ? sin(angle * .pi / 180) * 80 : 0
                    )
                    .scaleEffect(showBurst ? 1 : 0.1)
                    .opacity(showBurst ? 0 : 1)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
                showBurst = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                onComplete?()
            }
        }
    }
}

// MARK: - Breathing pulse ring

struct PulseRing: View {
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 0.6
    var color: Color = .vitaTeal
    var size: CGFloat = 60

    var body: some View {
        ZStack {
            // Outer pulse
            Circle()
                .stroke(color.opacity(opacity * 0.3), lineWidth: 2)
                .frame(width: size * scale * 1.6, height: size * scale * 1.6)
            // Inner pulse
            Circle()
                .stroke(color.opacity(opacity * 0.5), lineWidth: 2)
                .frame(width: size * scale * 1.25, height: size * scale * 1.25)
            // Core
            Circle()
                .fill(color.opacity(0.25))
                .frame(width: size, height: size)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                scale = 1.2
                opacity = 0.2
            }
        }
    }
}

// MARK: - Waveform animation (voice/chat)

struct WaveformView: View {
    @State private var levels: [CGFloat] = Array(repeating: 0.3, count: 5)
    var isActive: Bool = true
    var color: Color = .vitaTeal

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<5, id: \.self) { i in
                RoundedRectangle(cornerRadius: 4)
                    .fill(color)
                    .frame(width: 4, height: 28 * levels[i])
                    .animation(
                        isActive
                            ? Animation.easeInOut(duration: Double.random(in: 0.4...0.7))
                                .repeatForever(autoreverses: true)
                                .delay(Double(i) * 0.1)
                            : .easeOut(duration: 0.3),
                        value: levels[i]
                    )
            }
        }
        .frame(height: 28)
        .onAppear { if isActive { animateLevels() } }
        .onChange(of: isActive) { _, active in
            if active { animateLevels() } else { resetLevels() }
        }
    }

    private func animateLevels() {
        for i in 0..<5 {
            levels[i] = CGFloat.random(in: 0.25...1.0)
        }
    }

    private func resetLevels() {
        for i in 0..<5 { levels[i] = 0.3 }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        AnimatedMeshBackground()
        VStack(spacing: 40) {
            WaveformView(isActive: true, color: .vitaTeal)
            PulseRing(color: .vitaMint, size: 50)
            ParticleSystem(count: 15)
                .frame(height: 120)
        }
    }
}
