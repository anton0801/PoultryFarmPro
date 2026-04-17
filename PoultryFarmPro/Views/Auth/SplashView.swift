import SwiftUI
import Combine
import Network

struct RootView: View {

    @StateObject private var appState = AppState()
    @StateObject private var settings = SettingsViewModel()
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false

    var body: some View {
        ZStack {
            if !hasCompletedOnboarding {
                OnboardingContainerView()
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            } else if !appState.isLoggedIn {
                WelcomeView()
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                MainTabView()
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.4), value: hasCompletedOnboarding)
        .animation(.easeInOut(duration: 0.4), value: appState.isLoggedIn)
        .environmentObject(appState)
        .environmentObject(settings)
        .preferredColorScheme(settings.theme.colorScheme)
    }
}

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
    @StateObject private var app: PoultryFarmApplication
    @State private var networkMonitor = NWPathMonitor()
    @State private var cancellables = Set<AnyCancellable>()
    
    init() {
        let storage = UserDefaultsStorageService()
        let repository = AppDataRepository(storage: storage)
        let validation = SupabaseValidationService()
        let network = HTTPNetworkService()
        let notification = SystemNotificationService()
        
        _app = StateObject(wrappedValue: PoultryFarmApplication(
            repository: repository,
            validation: validation,
            network: network,
            notification: notification
        ))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    colors: [Color(hex: "#1B4332"), Color(hex: "#2D6A4F"), Color(hex: "#40916C")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                GeometryReader { geometry in
                    Image("splash_back_img")
                        .resizable().scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .ignoresSafeArea()
                        .blur(radius: 8)
                        .opacity(0.7)
                }
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
                
                NavigationLink(
                    destination: PoultryFarmWebView().navigationBarHidden(true),
                    isActive: $app.navigateToWeb
                ) { EmptyView() }
                
                NavigationLink(
                    destination: RootView().navigationBarBackButtonHidden(true),
                    isActive: $app.navigateToMain
                ) { EmptyView() }

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

                        Text("Loading...")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.75))
                    }
                    .opacity(textOpacity)
                    .offset(y: textOffset)
                }
            }
            .fullScreenCover(isPresented: $app.showPermissionPrompt) {
                PoultryFarmNotificationView(app: app)
            }
            .fullScreenCover(isPresented: $app.showOfflineView) {
                UnavailableView()
            }
            .onAppear {
                runAnimations()
                setupStreams()
                setupNetworkMonitoring()
                app.initialize()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func setupStreams() {
        NotificationCenter.default.publisher(for: Notification.Name("ConversionDataReceived"))
            .compactMap { $0.userInfo?["conversionData"] as? [String: Any] }
            .sink { data in
                app.handleTracking(data)
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: Notification.Name("deeplink_values"))
            .compactMap { $0.userInfo?["deeplinksData"] as? [String: Any] }
            .sink { data in
                app.handleNavigation(data)
            }
            .store(in: &cancellables)
    }
    
    // ✅ Network Monitoring ВКЛЮЧЁН!
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { path in
            Task { @MainActor in
                app.networkStatusChanged(path.status == .satisfied)
            }
        }
        networkMonitor.start(queue: .global(qos: .background))
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

struct UnavailableView: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                Image(geometry.size.width > geometry.size.height ? "farm_int_bg_img2" : "farm_int_bg_img")
                    .resizable().scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .ignoresSafeArea()
                    .blur(radius: 2)
                    .opacity(0.8)
                
                if geometry.size.width > geometry.size.height {
                    Image("farm_int_alert_img")
                        .resizable()
                        .frame(width: 250, height: 220)
                        .offset(x: 170)
                } else {
                    Image("farm_int_alert_img")
                        .resizable()
                        .frame(width: 250, height: 220)
                        .offset(y: -150)
                }
            }
        }
        .ignoresSafeArea()
    }
}
