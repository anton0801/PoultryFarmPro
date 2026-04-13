import SwiftUI

// MARK: - Reports View
struct ReportsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settings: SettingsViewModel
    @State private var selectedPeriod: ReportPeriod = .month

    enum ReportPeriod: String, CaseIterable { case week = "Week", month = "Month", year = "Year" }

    var periodStart: Date {
        let cal = Calendar.current
        switch selectedPeriod {
        case .week: return cal.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        case .month: return cal.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        case .year: return cal.date(byAdding: .year, value: -1, to: Date()) ?? Date()
        }
    }

    var periodEggs: Int {
        appState.eggRecords.filter { $0.date >= periodStart }.reduce(0) { $0 + $1.count }
    }

    var periodFeedKg: Double {
        appState.feedRecords.filter { $0.date >= periodStart }.reduce(0) { $0 + $1.amountKg }
    }

    var periodCosts: Double {
        appState.costRecords.filter { $0.date >= periodStart }.reduce(0) { $0 + $1.amount }
    }

    var topProducingGroup: String? {
        let counts = Dictionary(grouping: appState.eggRecords.filter { $0.date >= periodStart }, by: { $0.birdGroupName })
        return counts.max(by: { $0.value.reduce(0) { $0 + $1.count } < $1.value.reduce(0) { $0 + $1.count } })?.key
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Picker("Period", selection: $selectedPeriod) {
                    ForEach(ReportPeriod.allCases, id: \.self) { p in Text(p.rawValue).tag(p) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)

                // Key Metrics
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    reportCard(title: "Eggs Collected", value: "\(periodEggs)", icon: "oval.fill", color: .eggYolk)
                    reportCard(title: "Feed Used", value: "\(String(format: "%.0f", periodFeedKg))kg", icon: "bag.fill", color: .hayAmber)
                    reportCard(title: "Total Costs", value: "\(settings.currencySymbol)\(String(format: "%.2f", periodCosts))", icon: "dollarsign.circle.fill", color: .soilBrown)
                    reportCard(title: "Health Issues", value: "\(appState.healthRecords.filter { $0.date >= periodStart }.count)", icon: "cross.fill", color: .alertRed)
                }
                .padding(.horizontal, 20)

                // Best Producer
                if let topGroup = topProducingGroup {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Top Egg Producer").font(.farmHeadline(15)).foregroundColor(.textPrimary)
                        HStack {
                            Image(systemName: "star.fill").foregroundColor(.eggYolk)
                            Text(topGroup).font(.farmBody(15)).foregroundColor(.textPrimary)
                            Spacer()
                            let eggs = appState.eggRecords.filter { $0.birdGroupName == topGroup && $0.date >= periodStart }.reduce(0) { $0 + $1.count }
                            Text("\(eggs) eggs").font(.farmHeadline(14)).foregroundColor(.hayAmberDeep)
                        }
                    }
                    .farmCard().padding(.horizontal, 20)
                }

                // Feed breakdown
                if !appState.feedRecords.isEmpty {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Feed Breakdown").font(.farmHeadline(15)).foregroundColor(.textPrimary)

                        ForEach(FeedType.allCases, id: \.self) { feedType in
                            let amount = appState.feedRecords.filter { $0.feedType == feedType && $0.date >= periodStart }.reduce(0) { $0 + $1.amountKg }
                            if amount > 0 {
                                HStack {
                                    Circle().fill(feedType.color).frame(width: 12, height: 12)
                                    Text(feedType.rawValue).font(.farmBody(14)).foregroundColor(.textPrimary)
                                    Spacer()
                                    Text("\(String(format: "%.1f", amount))kg").font(.farmBody(14)).foregroundColor(.textSecondary)
                                }
                            }
                        }
                    }
                    .farmCard().padding(.horizontal, 20)
                }

                // Egg production by group
                if !appState.eggRecords.isEmpty {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Egg Production by Group").font(.farmHeadline(15)).foregroundColor(.textPrimary)

                        let groups = Dictionary(grouping: appState.eggRecords.filter { $0.date >= periodStart }, by: { $0.birdGroupName })
                        ForEach(groups.sorted(by: { $0.value.reduce(0) { $0 + $1.count } > $1.value.reduce(0) { $0 + $1.count } }), id: \.key) { group, records in
                            let total = records.reduce(0) { $0 + $1.count }
                            HStack {
                                Text("🥚").font(.system(size: 16))
                                Text(group).font(.farmBody(14)).foregroundColor(.textPrimary)
                                Spacer()
                                Text("\(total) eggs").font(.farmBody(14)).foregroundColor(.textSecondary)
                            }
                        }
                    }
                    .farmCard().padding(.horizontal, 20)
                }
            }
            .padding(.vertical, 16).padding(.bottom, 24)
        }
        .background(Color.surfaceLight.ignoresSafeArea())
        .navigationTitle("Reports")
    }

    private func reportCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon).font(.system(size: 20, weight: .medium)).foregroundColor(color)
            Text(value).font(.farmNumber(24)).foregroundColor(.textPrimary)
            Text(title).font(.farmCaption(12)).foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color.cardBackground).shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3))
    }
}

// MARK: - Costs View
struct CostsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settings: SettingsViewModel
    @State private var showAdd = false

    var totalCosts: Double { appState.costRecords.reduce(0) { $0 + $1.amount } }

    var body: some View {
        Group {
            VStack(spacing: 0) {
                // Total header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total Expenses").font(.farmBody(14)).foregroundColor(.white.opacity(0.8))
                        Text("\(settings.currencySymbol)\(String(format: "%.2f", totalCosts))").font(.farmNumber(32)).foregroundColor(.white)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20).padding(.vertical, 20)
                .background(LinearGradient.soilGradient)

                if appState.costRecords.isEmpty {
                    EmptyStateView(icon: "dollarsign.circle.fill", title: "No Cost Records", message: "Track your farm expenses to understand profitability.").frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(appState.costRecords.sorted { $0.date > $1.date }) { record in
                            CostRow(record: record, currencySymbol: settings.currencySymbol)
                                .listRowBackground(Color.cardBackground)
                        }
                        .onDelete { offsets in offsets.map { appState.costRecords[$0] }.forEach { appState.deleteCostRecord($0) } }
                    }
                    .listStyle(.insetGrouped)
                }
            }
        }
        .background(Color.surfaceLight.ignoresSafeArea())
        .navigationTitle("Costs")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAdd = true }) {
                    Image(systemName: "plus.circle.fill").foregroundColor(.farmGreen).font(.system(size: 22))
                }
            }
        }
        .sheet(isPresented: $showAdd) { AddCostView() }
    }
}

struct CostRow: View {
    let record: CostRecord
    let currencySymbol: String
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(record.category.color.opacity(0.12)).frame(width: 44, height: 44)
                Image(systemName: record.category.icon).font(.system(size: 16)).foregroundColor(record.category.color)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(record.description).font(.farmBody(15)).foregroundColor(.textPrimary)
                Text(record.category.rawValue).font(.farmCaption(12)).foregroundColor(.textSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text("\(currencySymbol)\(String(format: "%.2f", record.amount))").font(.farmHeadline(15)).foregroundColor(.soilBrown)
                Text(record.date.formatted(date: .abbreviated, time: .omitted)).font(.farmCaption(11)).foregroundColor(.textMuted)
            }
        }
        .padding(.vertical, 4)
    }
}

struct AddCostView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settings: SettingsViewModel
    @Environment(\.dismiss) var dismiss
    @State private var category: CostCategory = .feed
    @State private var amountText = ""
    @State private var description = ""
    @State private var date = Date()
    @State private var errorMsg = ""

    var body: some View {
        NavigationView {
            Form {
                Section("Cost Details") {
                    Picker("Category", selection: $category) {
                        ForEach(CostCategory.allCases, id: \.self) { c in
                            HStack { Image(systemName: c.icon); Text(c.rawValue) }.tag(c)
                        }
                    }
                    FarmTextField(placeholder: "Amount (\(settings.currencySymbol))", text: $amountText, icon: "dollarsign.circle.fill", keyboardType: .decimalPad)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    FarmTextField(placeholder: "Description", text: $description, icon: "text.alignleft")
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    DatePicker("Date", selection: $date, displayedComponents: .date).font(.farmBody(15))
                }
                if !errorMsg.isEmpty { Text(errorMsg).foregroundColor(.alertRed).font(.farmCaption(13)) }
            }
            .navigationTitle("Add Cost")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        guard let amount = Double(amountText), amount > 0 else { errorMsg = "Valid amount required"; return }
                        guard !description.trimmingCharacters(in: .whitespaces).isEmpty else { errorMsg = "Description required"; return }
                        appState.addCostRecord(CostRecord(category: category, amount: amount, description: description, date: date))
                        dismiss()
                    }
                    .foregroundColor(.farmGreen).font(.farmHeadline(15))
                }
            }
        }
    }
}

// MARK: - Activity History
struct ActivityHistoryView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            if appState.activities.isEmpty {
                EmptyStateView(icon: "clock.fill", title: "No Activity", message: "Your farm activity will appear here.")
            } else {
                List {
                    ForEach(appState.activities) { activity in
                        HStack(spacing: 14) {
                            ZStack {
                                Circle().fill(activity.type.color.opacity(0.15)).frame(width: 40, height: 40)
                                Image(systemName: activity.type.icon).font(.system(size: 16, weight: .semibold)).foregroundColor(activity.type.color)
                            }
                            VStack(alignment: .leading, spacing: 3) {
                                Text(activity.description).font(.farmBody(14)).foregroundColor(.textPrimary)
                                Text(activity.date.relativeString).font(.farmCaption(12)).foregroundColor(.textMuted)
                            }
                        }
                        .listRowBackground(Color.cardBackground)
                        .padding(.vertical, 3)
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .background(Color.surfaceLight.ignoresSafeArea())
        .navigationTitle("Activity History")
    }
}

// MARK: - Profile View
struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @State private var name = ""
    @State private var farmName = ""
    @State private var isEditing = false
    @State private var saved = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Avatar
                VStack(spacing: 12) {
                    ZStack {
                        Circle().fill(LinearGradient.farmHero).frame(width: 100, height: 100)
                        Text(appState.currentUser?.name.prefix(1).uppercased() ?? "F")
                            .font(.system(size: 44, weight: .bold, design: .rounded)).foregroundColor(.white)
                    }
                    Text(appState.currentUser?.name ?? "Farmer").font(.farmTitle(22)).foregroundColor(.textPrimary)
                    Text(appState.currentUser?.email ?? "").font(.farmBody(14)).foregroundColor(.textSecondary)
                }
                .padding(.top, 20)

                if isEditing {
                    VStack(spacing: 16) {
                        FarmTextField(placeholder: "Your Name", text: $name, icon: "person.fill")
                        FarmTextField(placeholder: "Farm Name", text: $farmName, icon: "house.fill")

                        HStack(spacing: 12) {
                            Button("Cancel") {
                                isEditing = false
                                name = appState.currentUser?.name ?? ""
                                farmName = appState.currentUser?.farmName ?? ""
                            }
                            .buttonStyle(FarmSecondaryButtonStyle())

                            Button("Save") {
                                appState.updateProfile(name: name, farmName: farmName)
                                isEditing = false
                                saved = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { saved = false }
                            }
                            .buttonStyle(FarmPrimaryButtonStyle())
                        }
                    }
                    .padding(.horizontal, 24)
                } else {
                    VStack(spacing: 12) {
                        profileRow(label: "Name", value: appState.currentUser?.name ?? "")
                        Divider()
                        profileRow(label: "Farm", value: appState.currentUser?.farmName ?? "")
                        Divider()
                        profileRow(label: "Email", value: appState.currentUser?.email ?? "")
                    }
                    .farmCard()
                    .padding(.horizontal, 20)

                    Button("Edit Profile") { isEditing = true; name = appState.currentUser?.name ?? ""; farmName = appState.currentUser?.farmName ?? "" }
                        .buttonStyle(FarmSecondaryButtonStyle())
                        .padding(.horizontal, 24)
                }

                if saved {
                    Text("✓ Profile updated!").font(.farmBody(14)).foregroundColor(.farmGreen).transition(.opacity)
                }

                // Stats summary
                VStack(alignment: .leading, spacing: 12) {
                    Text("Your Farm Stats").font(.farmHeadline(15)).foregroundColor(.textPrimary)
                    profileStat(label: "Bird Groups", value: "\(appState.birdGroups.count)")
                    profileStat(label: "Total Birds", value: "\(appState.totalBirdCount)")
                    profileStat(label: "Eggs Recorded", value: "\(appState.eggRecords.reduce(0) { $0 + $1.count })")
                    profileStat(label: "Activities", value: "\(appState.activities.count)")
                }
                .farmCard()
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 40)
        }
        .background(Color.surfaceLight.ignoresSafeArea())
        .navigationTitle("Profile")
    }

    private func profileRow(label: String, value: String) -> some View {
        HStack {
            Text(label).font(.farmBody(14)).foregroundColor(.textSecondary)
            Spacer()
            Text(value).font(.farmBody(14)).foregroundColor(.textPrimary)
        }
    }

    private func profileStat(label: String, value: String) -> some View {
        HStack {
            Text(label).font(.farmBody(14)).foregroundColor(.textSecondary)
            Spacer()
            Text(value).font(.farmHeadline(14)).foregroundColor(.farmGreen)
        }
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settings: SettingsViewModel
    @State private var showDeleteConfirm = false
    @State private var showLogoutConfirm = false
    @State private var reminderHour: Double

    init() { _reminderHour = State(initialValue: Double(UserDefaults.standard.integer(forKey: "daily_reminder_hour").clamped(to: 0...23))) }

    var body: some View {
        Form {
            // APPEARANCE
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Text("App Theme").font(.farmBody(15)).foregroundColor(.textPrimary)
                    HStack(spacing: 10) {
                        ForEach(AppTheme.allCases, id: \.self) { theme in
                            Button(action: { settings.applyTheme(theme) }) {
                                VStack(spacing: 6) {
                                    Image(systemName: theme.icon)
                                        .font(.system(size: 20))
                                        .foregroundColor(settings.theme == theme ? .white : .farmGreen)
                                    Text(theme.rawValue).font(.farmCaption(11))
                                        .foregroundColor(settings.theme == theme ? .white : .textPrimary)
                                }
                                .frame(maxWidth: .infinity).padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(settings.theme == theme ? Color.farmGreen : Color.surfaceLight)
                                )
                            }
                            .buttonStyle(FarmIconButtonStyle())
                        }
                    }
                }
                .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
            } header: { Text("Appearance") }

            // UNITS
            Section {
                Toggle("Use Metric (kg, m²)", isOn: $settings.useMetric)
                    .toggleStyle(SwitchToggleStyle(tint: .farmGreen))
                    .font(.farmBody(15))

                Picker("Currency Symbol", selection: $settings.currencySymbol) {
                    Text("$ USD").tag("$")
                    Text("€ EUR").tag("€")
                    Text("£ GBP").tag("£")
                    Text("₴ UAH").tag("₴")
                    Text("₽ RUB").tag("₽")
                }
                .font(.farmBody(15))
            } header: { Text("Units & Currency") }

            // NOTIFICATIONS
            Section {
                Toggle("Enable Notifications", isOn: Binding(
                    get: { settings.notificationsEnabled },
                    set: { settings.toggleNotifications($0) }
                ))
                .toggleStyle(SwitchToggleStyle(tint: .farmGreen))
                .font(.farmBody(15))

                if settings.notificationsEnabled {
                    Toggle("Daily Farm Reminder", isOn: Binding(
                        get: { settings.dailyReminderEnabled },
                        set: { settings.setDailyReminder(enabled: $0, hour: settings.dailyReminderHour) }
                    ))
                    .toggleStyle(SwitchToggleStyle(tint: .farmGreen))
                    .font(.farmBody(15))

                    if settings.dailyReminderEnabled {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Reminder Time: \(settings.dailyReminderHour):00")
                                .font(.farmBody(14)).foregroundColor(.textPrimary)
                            Slider(value: $reminderHour, in: 5...22, step: 1) { _ in
                                settings.setDailyReminder(enabled: true, hour: Int(reminderHour))
                            }
                            .tint(.farmGreen)
                        }
                        .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                    }
                }
            } header: { Text("Notifications") }

            // ACCOUNT
            Section {
                Button(action: { showLogoutConfirm = true }) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right").foregroundColor(.hayAmberDeep)
                        Text("Log Out").font(.farmBody(15)).foregroundColor(.hayAmberDeep)
                    }
                }

                Button(action: { showDeleteConfirm = true }) {
                    HStack {
                        Image(systemName: "trash.fill").foregroundColor(.alertRed)
                        Text("Delete Account").font(.farmBody(15)).foregroundColor(.alertRed)
                    }
                }
            } header: { Text("Account") }

            Section {
                HStack {
                    Text("Version").font(.farmBody(14)).foregroundColor(.textSecondary)
                    Spacer()
                    Text("1.0.0").font(.farmBody(14)).foregroundColor(.textMuted)
                }
            } header: { Text("About") }
        }
        .navigationTitle("Settings")
        .background(Color.surfaceLight.ignoresSafeArea())
        .alert("Log Out", isPresented: $showLogoutConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Log Out", role: .destructive) { appState.logout() }
        } message: {
            Text("Are you sure you want to log out?")
        }
        .alert("Delete Account", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                settings.cancelAllNotifications()
                appState.deleteAccount()
            }
        } message: {
            Text("This will permanently delete your account and all farm data. This action cannot be undone.")
        }
    }
}

extension SettingsViewModel {
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        return min(max(self, range.lowerBound), range.upperBound)
    }
}
