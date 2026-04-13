import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @EnvironmentObject var appState: AppState

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "square.grid.2x2.fill")
                }
                .tag(0)

            BirdGroupsView()
                .tabItem {
                    Label("Birds", systemImage: "bird.fill")
                }
                .tag(1)

            EggTrackerView()
                .tabItem {
                    Label("Eggs", systemImage: "oval.fill")
                }
                .tag(2)

            FeedingView()
                .tabItem {
                    Label("Feeding", systemImage: "bag.fill")
                }
                .tag(3)

            MoreView()
                .tabItem {
                    Label("More", systemImage: "ellipsis.circle.fill")
                }
                .tag(4)
        }
        .accentColor(.farmGreen)
    }
}

// MARK: - More Menu (holds less frequent tabs)
struct MoreView: View {
    @EnvironmentObject var appState: AppState
    @State private var navPath: [MoreDestination] = []

    enum MoreDestination: Hashable {
        case coops, breeding, incubator, crops, health, calendar, reports, settings, profile, storage, tasks, activityHistory, costs
    }

    var body: some View {
        NavigationView {
            List {
                Section {
                    moreRow(destination: .coops, icon: "house.fill", color: .soilBrown, title: "Coops", subtitle: "Manage housing")
                    moreRow(destination: .breeding, icon: "heart.fill", color: Color(hex: "#FF6B9D"), title: "Breeding", subtitle: "\(appState.activeBreedingCount) active pairs")
                    moreRow(destination: .incubator, icon: "thermometer.medium", color: .infoBlue, title: "Incubator", subtitle: "\(appState.incubatorBatches.count) batches")
                    moreRow(destination: .crops, icon: "leaf.fill", color: .farmGreenLight, title: "Feed Crops", subtitle: "\(appState.feedCrops.count) crops")
                    moreRow(destination: .storage, icon: "shippingbox.fill", color: .hayAmber, title: "Storage", subtitle: "\(String(format: "%.0f", appState.totalFeedStorageKg))kg feed")
                } header: {
                    Text("Management")
                        .font(.farmCaption(12))
                        .foregroundColor(.textMuted)
                }

                Section {
                    moreRow(destination: .health, icon: "cross.fill", color: .alertRed, title: "Health", subtitle: "\(appState.openHealthIssues) open issues")
                    moreRow(destination: .calendar, icon: "calendar", color: .farmGreen, title: "Calendar", subtitle: "Farm schedule")
                    moreRow(destination: .tasks, icon: "checklist", color: .hayAmberDeep, title: "Tasks", subtitle: "\(appState.pendingTasks) pending")
                    moreRow(destination: .costs, icon: "dollarsign.circle.fill", color: .soilBrown, title: "Costs", subtitle: "Track expenses")
                    moreRow(destination: .reports, icon: "chart.bar.fill", color: .farmGreen, title: "Reports", subtitle: "Analytics & insights")
                    moreRow(destination: .activityHistory, icon: "clock.fill", color: .textSecondary, title: "Activity History", subtitle: "Recent actions")
                } header: {
                    Text("Tracking")
                        .font(.farmCaption(12))
                        .foregroundColor(.textMuted)
                }

                Section {
                    moreRow(destination: .profile, icon: "person.fill", color: .infoBlue, title: "Profile", subtitle: appState.currentUser?.farmName ?? "My Farm")
                    moreRow(destination: .settings, icon: "gearshape.fill", color: .textSecondary, title: "Settings", subtitle: "App preferences")
                } header: {
                    Text("Account")
                        .font(.farmCaption(12))
                        .foregroundColor(.textMuted)
                }
            }
            .navigationTitle("More")
            .navigationBarTitleDisplayMode(.large)
            .background(Color.surfaceLight.ignoresSafeArea())
            .background(
                NavigationLink(destination: destinationView(for: navPath.last), isActive: Binding(
                    get: { !navPath.isEmpty },
                    set: { if !$0 { do { navPath.removeLast() } catch { } } }
                )) { EmptyView() }
            )
        }
    }

    @ViewBuilder
    private func moreRow(destination: MoreDestination, icon: String, color: Color, title: String, subtitle: String) -> some View {
        Button(action: { navPath.append(destination) }) {
            FarmRowItem(icon: icon, iconColor: color, title: title, subtitle: subtitle)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func destinationView(for dest: MoreDestination?) -> some View {
        switch dest {
        case .coops: CoopsView()
        case .breeding: BreedingView()
        case .incubator: IncubatorView()
        case .crops: FeedCropsView()
        case .storage: StorageView()
        case .health: HealthView()
        case .calendar: CalendarView()
        case .tasks: TasksView()
        case .costs: CostsView()
        case .reports: ReportsView()
        case .activityHistory: ActivityHistoryView()
        case .profile: ProfileView()
        case .settings: SettingsView()
        case .none: EmptyView()
        }
    }
}
