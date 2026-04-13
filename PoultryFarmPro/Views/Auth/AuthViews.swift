import SwiftUI

// MARK: - Welcome
struct WelcomeView: View {
    @State private var showLogin = false
    @State private var showSignUp = false
    @State private var logoScale: CGFloat = 0.8
    @State private var contentOpacity: Double = 0

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#1B4332"), Color(hex: "#2D6A4F"), Color(hex: "#52B788")],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            // Decorative leaves
            VStack {
                HStack {
                    Spacer()
                    Text("🌿")
                        .font(.system(size: 80))
                        .rotationEffect(.degrees(30))
                        .opacity(0.25)
                        .offset(x: 20, y: -10)
                }
                Spacer()
                HStack {
                    Text("🌱")
                        .font(.system(size: 60))
                        .rotationEffect(.degrees(-20))
                        .opacity(0.2)
                        .offset(x: -10, y: 10)
                    Spacer()
                }
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo Section
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.15))
                            .frame(width: 130, height: 130)

                        VStack(spacing: -6) {
                            Text("🐔")
                                .font(.system(size: 58))
                            Text("🥚")
                                .font(.system(size: 30))
                                .offset(x: 18, y: -14)
                        }
                    }
                    .scaleEffect(logoScale)

                    VStack(spacing: 8) {
                        Text("Poultry Farm Pro")
                            .font(.system(size: 32, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)

                        Text("Your complete farm companion")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.75))
                    }
                }

                Spacer()
                Spacer()

                // Action Buttons
                VStack(spacing: 16) {
                    Button("Create Account") { showSignUp = true }
                        .font(.farmHeadline(17))
                        .foregroundColor(Color(hex: "#2D6A4F"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 6)
                        )

                    Button("Log In") { showLogin = true }
                        .font(.farmHeadline(17))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.white.opacity(0.6), lineWidth: 2)
                        )
                }
                .padding(.horizontal, 32)
                .opacity(contentOpacity)

                Spacer()
                    .frame(height: 60)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                logoScale = 1.0
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.4)) {
                contentOpacity = 1.0
            }
        }
        .sheet(isPresented: $showSignUp) { SignUpView() }
        .sheet(isPresented: $showLogin) { LoginView() }
    }
}

// MARK: - Sign Up
struct SignUpView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var farmName = ""
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var isLoading = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 28) {
                    // Header
                    VStack(spacing: 10) {
                        Text("🌱")
                            .font(.system(size: 52))
                        Text("Create Account")
                            .font(.farmTitle(26))
                            .foregroundColor(.textPrimary)
                        Text("Set up your farm profile")
                            .font(.farmBody(15))
                            .foregroundColor(.textSecondary)
                    }
                    .padding(.top, 20)

                    // Form
                    VStack(spacing: 16) {
                        FarmTextField(placeholder: "Your Name", text: $name, icon: "person.fill")
                        FarmTextField(placeholder: "Farm Name", text: $farmName, icon: "house.fill")
                        FarmTextField(placeholder: "Email Address", text: $email, icon: "envelope.fill", keyboardType: .emailAddress)
                        FarmTextField(placeholder: "Password (min 6 chars)", text: $password, icon: "lock.fill", isSecure: true)
                    }
                    .padding(.horizontal, 24)

                    if showError {
                        Text(errorMessage)
                            .font(.farmCaption(13))
                            .foregroundColor(.alertRed)
                            .padding(.horizontal, 24)
                    }

                    Button(action: handleSignUp) {
                        HStack {
                            if isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Create Account")
                            }
                        }
                    }
                    .buttonStyle(FarmPrimaryButtonStyle())
                    .padding(.horizontal, 24)
                    .disabled(isLoading)
                }
                .padding(.bottom, 40)
            }
            .background(Color.cardBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.textMuted)
                            .font(.system(size: 22))
                    }
                }
            }
        }
    }

    private func handleSignUp() {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            showFieldError("Please enter your name"); return
        }
        guard !farmName.trimmingCharacters(in: .whitespaces).isEmpty else {
            showFieldError("Please enter your farm name"); return
        }
        guard email.contains("@") && email.contains(".") else {
            showFieldError("Please enter a valid email"); return
        }
        guard password.count >= 6 else {
            showFieldError("Password must be at least 6 characters"); return
        }

        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            appState.register(name: name, email: email, password: password, farmName: farmName)
            appState.requestNotificationPermission()
            isLoading = false
            dismiss()
        }
    }

    private func showFieldError(_ msg: String) {
        errorMessage = msg
        showError = true
        withAnimation(.spring()) { showError = true }
    }
}

// MARK: - Login
struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var isLoading = false
    @State private var shakeOffset: CGFloat = 0

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 28) {
                    VStack(spacing: 10) {
                        Text("👋")
                            .font(.system(size: 52))
                        Text("Welcome Back")
                            .font(.farmTitle(26))
                            .foregroundColor(.textPrimary)
                        Text("Sign in to your farm")
                            .font(.farmBody(15))
                            .foregroundColor(.textSecondary)
                    }
                    .padding(.top, 20)

                    VStack(spacing: 16) {
                        FarmTextField(placeholder: "Email Address", text: $email, icon: "envelope.fill", keyboardType: .emailAddress)
                        FarmTextField(placeholder: "Password", text: $password, icon: "lock.fill", isSecure: true)
                    }
                    .padding(.horizontal, 24)
                    .offset(x: shakeOffset)

                    if showError {
                        Text(errorMessage)
                            .font(.farmCaption(13))
                            .foregroundColor(.alertRed)
                            .padding(.horizontal, 24)
                    }

                    Button(action: handleLogin) {
                        HStack {
                            if isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Log In")
                            }
                        }
                    }
                    .buttonStyle(FarmPrimaryButtonStyle())
                    .padding(.horizontal, 24)
                    .disabled(isLoading)
                }
                .padding(.bottom, 40)
            }
            .background(Color.cardBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.textMuted)
                            .font(.system(size: 22))
                    }
                }
            }
        }
    }

    private func handleLogin() {
        guard !email.isEmpty && !password.isEmpty else {
            showFieldError("Please fill in all fields"); return
        }
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let success = appState.login(email: email, password: password)
            isLoading = false
            if success {
                dismiss()
            } else {
                showFieldError("Invalid email or password")
                triggerShake()
            }
        }
    }

    private func showFieldError(_ msg: String) {
        errorMessage = msg
        withAnimation { showError = true }
    }

    private func triggerShake() {
        let impactFeedback = UINotificationFeedbackGenerator()
        impactFeedback.notificationOccurred(.error)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.3)) { shakeOffset = -12 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.3)) { shakeOffset = 12 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { shakeOffset = 0 }
        }
    }
}
