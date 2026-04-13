import SwiftUI

struct SplashView: View {
    @State private var logoScale: CGFloat = 0.4
    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var textOffset: CGFloat = 20
    @State private var ring1Scale: CGFloat = 0.5
    @State private var ring1Opacity: Double = 0
    @State private var ring2Scale: CGFloat = 0.5
    @State private var ring2Opacity: Double = 0
    @State private var particleOpacity: Double = 0

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(hex: "#1B4332"), Color(hex: "#2D6A4F"), Color(hex: "#40916C")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Decorative circles
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: 1.5)
                .frame(width: 280, height: 280)
                .scaleEffect(ring1Scale)
                .opacity(ring1Opacity)

            Circle()
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
                .frame(width: 380, height: 380)
                .scaleEffect(ring2Scale)
                .opacity(ring2Opacity)

            // Particles
            SplashParticlesView()
                .opacity(particleOpacity)

            VStack(spacing: 28) {
                // Logo
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 120, height: 120)

                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 140, height: 140)

                    VStack(spacing: -4) {
                        Text("🐔")
                            .font(.system(size: 52))
                        Text("🥚")
                            .font(.system(size: 28))
                            .offset(x: 16, y: -12)
                    }
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)

                VStack(spacing: 8) {
                    Text("Poultry Farm Pro")
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)

                    Text("Manage your poultry farm.")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.75))
                }
                .opacity(textOpacity)
                .offset(y: textOffset)
            }
        }
        .onAppear { runAnimations() }
    }

    private func runAnimations() {
        withAnimation(.spring(response: 0.7, dampingFraction: 0.6).delay(0.2)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
        withAnimation(.easeOut(duration: 0.8).delay(0.4)) {
            ring1Scale = 1.0
            ring1Opacity = 1.0
        }
        withAnimation(.easeOut(duration: 0.8).delay(0.6)) {
            ring2Scale = 1.0
            ring2Opacity = 1.0
        }
        withAnimation(.easeOut(duration: 0.6).delay(0.8)) {
            textOpacity = 1.0
            textOffset = 0
        }
        withAnimation(.easeIn(duration: 0.4).delay(1.0)) {
            particleOpacity = 1.0
        }
    }
}

struct SplashParticlesView: View {
    let particles: [(CGFloat, CGFloat, CGFloat, Double)] = (0..<20).map { _ in
        (CGFloat.random(in: -180...180),
         CGFloat.random(in: -350...350),
         CGFloat.random(in: 3...8),
         Double.random(in: 0.3...0.8))
    }

    @State private var animate = false

    var body: some View {
        ZStack {
            ForEach(0..<particles.count, id: \.self) { i in
                Circle()
                    .fill(Color.white.opacity(particles[i].3 * 0.4))
                    .frame(width: particles[i].2, height: particles[i].2)
                    .offset(x: particles[i].0, y: particles[i].1)
                    .scaleEffect(animate ? 1.2 : 0.8)
                    .animation(
                        Animation.easeInOut(duration: Double.random(in: 1.5...2.5))
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.1),
                        value: animate
                    )
            }
        }
        .onAppear { animate = true }
    }
}
