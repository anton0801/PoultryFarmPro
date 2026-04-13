import SwiftUI

struct OnboardingContainerView: View {
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @State private var currentPage = 0
    @State private var dragOffset: CGFloat = 0

    let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Track Your Poultry",
            subtitle: "Monitor every bird group across your farm — chickens, ducks, geese, and more.",
            emoji: "🐔",
            accentColor: Color(hex: "#2D6A4F"),
            backgroundColors: [Color(hex: "#1B4332"), Color(hex: "#2D6A4F")]
        ),
        OnboardingPage(
            title: "Record Egg Production",
            subtitle: "Log daily egg counts, track weekly trends, and see which groups are most productive.",
            emoji: "🥚",
            accentColor: Color(hex: "#F9C74F"),
            backgroundColors: [Color(hex: "#E07B39"), Color(hex: "#F4A261")]
        ),
        OnboardingPage(
            title: "Plan Feeding & Breeding",
            subtitle: "Schedule feeding, manage incubators, grow your own feed crops, and keep your flock healthy.",
            emoji: "🌾",
            accentColor: Color(hex: "#52B788"),
            backgroundColors: [Color(hex: "#40916C"), Color(hex: "#52B788")]
        )
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: pages[currentPage].backgroundColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.5), value: currentPage)

            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    Button("Skip") {
                        withAnimation { hasCompletedOnboarding = true }
                    }
                    .font(.farmBody(15))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.trailing, 24)
                    .padding(.top, 60)
                }

                Spacer()

                // Page content
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .frame(height: 480)

                Spacer()

                // Dots indicator
                HStack(spacing: 10) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Capsule()
                            .fill(Color.white.opacity(index == currentPage ? 1 : 0.4))
                            .frame(width: index == currentPage ? 28 : 8, height: 8)
                            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentPage)
                    }
                }
                .padding(.bottom, 32)

                // Action button
                Button(action: {
                    if currentPage < pages.count - 1 {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            currentPage += 1
                        }
                    } else {
                        withAnimation { hasCompletedOnboarding = true }
                    }
                }) {
                    HStack {
                        Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                            .font(.farmHeadline(17))
                        Image(systemName: currentPage < pages.count - 1 ? "arrow.right" : "checkmark")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundColor(pages[currentPage].backgroundColors[0])
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 6)
                    )
                    .padding(.horizontal, 32)
                    .padding(.bottom, 48)
                }
                .buttonStyle(FarmIconButtonStyle())
            }
        }
    }
}

struct OnboardingPage {
    let title: String
    let subtitle: String
    let emoji: String
    let accentColor: Color
    let backgroundColors: [Color]
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    @State private var emojiScale: CGFloat = 0.7
    @State private var emojiRotation: Double = -10
    @State private var textOpacity: Double = 0
    @State private var bounce: Bool = false

    var body: some View {
        VStack(spacing: 32) {
            // Illustration
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 200, height: 200)

                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 240, height: 240)
                    .scaleEffect(bounce ? 1.05 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 1.8).repeatForever(autoreverses: true),
                        value: bounce
                    )

                Text(page.emoji)
                    .font(.system(size: 96))
                    .scaleEffect(emojiScale)
                    .rotationEffect(.degrees(emojiRotation))
            }
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
                    emojiScale = 1.0
                    emojiRotation = 0
                }
                bounce = true
            }

            VStack(spacing: 16) {
                Text(page.title)
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text(page.subtitle)
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .opacity(textOpacity)
            .onAppear {
                withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                    textOpacity = 1.0
                }
            }
        }
        .padding(.horizontal, 20)
    }
}
