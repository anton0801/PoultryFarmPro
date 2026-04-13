import SwiftUI

// MARK: - Coops View
struct CoopsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showAdd = false

    var body: some View {
        Group {
            if appState.coops.isEmpty {
                EmptyStateView(icon: "house.fill", title: "No Coops Yet", message: "Add housing units to organize your bird groups.")
            } else {
                List {
                    ForEach(appState.coops) { coop in
                        NavigationLink(destination: CoopDetailView(coop: coop)) {
                            CoopRow(coop: coop)
                        }
                        .listRowBackground(Color.cardBackground)
                    }
                    .onDelete { offsets in
                        offsets.map { appState.coops[$0] }.forEach { appState.deleteCoop($0) }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .background(Color.surfaceLight.ignoresSafeArea())
        .navigationTitle("Coops")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAdd = true }) {
                    Image(systemName: "plus.circle.fill").foregroundColor(.farmGreen).font(.system(size: 22))
                }
            }
        }
        .sheet(isPresented: $showAdd) { AddCoopView() }
    }
}

struct CoopRow: View {
    let coop: Coop
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(Color.soilBrown.opacity(0.12)).frame(width: 48, height: 48)
                Image(systemName: "house.fill").font(.system(size: 20)).foregroundColor(.soilBrown)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(coop.name).font(.farmBody(15)).foregroundColor(.textPrimary)
                Text("Capacity: \(coop.capacity)").font(.farmCaption(12)).foregroundColor(.textSecondary)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct CoopDetailView: View {
    @EnvironmentObject var appState: AppState
    let coop: Coop
    @State private var showEdit = false

    var assignedGroups: [BirdGroup] {
        appState.birdGroups.filter { $0.coopId == coop.id }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Image(systemName: "house.fill").font(.system(size: 56)).foregroundColor(.soilBrown)
                    Text(coop.name).font(.farmTitle(22)).foregroundColor(.textPrimary)
                    Text("Capacity: \(coop.capacity) birds").font(.farmBody(15)).foregroundColor(.textSecondary)
                    if !coop.notes.isEmpty {
                        Text(coop.notes).font(.farmBody(14)).foregroundColor(.textMuted).multilineTextAlignment(.center)
                    }
                }
                .padding(.top, 8)

                if !assignedGroups.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Assigned Groups").font(.farmHeadline(15)).foregroundColor(.textPrimary)
                        ForEach(assignedGroups) { group in
                            HStack {
                                Text(group.birdType.icon).font(.system(size: 24))
                                VStack(alignment: .leading) {
                                    Text(group.name).font(.farmBody(14)).foregroundColor(.textPrimary)
                                    Text("\(group.count) birds").font(.farmCaption(12)).foregroundColor(.textSecondary)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 4)
                            if group.id != assignedGroups.last?.id { Divider() }
                        }
                    }
                    .farmCard()
                    .padding(.horizontal, 20)
                } else {
                    EmptyStateView(icon: "bird", title: "No Groups Assigned", message: "Assign bird groups to this coop when adding groups.")
                }
            }
            .padding(.bottom, 24)
        }
        .background(Color.surfaceLight.ignoresSafeArea())
        .navigationTitle(coop.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") { showEdit = true }.foregroundColor(.farmGreen)
            }
        }
        .sheet(isPresented: $showEdit) { AddCoopView(existing: coop) }
    }
}

struct AddCoopView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    var existing: Coop? = nil
    @State private var name = ""
    @State private var capacityText = ""
    @State private var notes = ""
    @State private var errorMsg = ""

    init(existing: Coop? = nil) {
        self.existing = existing
        _name = State(initialValue: existing?.name ?? "")
        _capacityText = State(initialValue: existing != nil ? "\(existing!.capacity)" : "")
        _notes = State(initialValue: existing?.notes ?? "")
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Coop Info") {
                    FarmTextField(placeholder: "Coop Name", text: $name, icon: "house.fill")
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    FarmTextField(placeholder: "Capacity (number of birds)", text: $capacityText, icon: "number.circle.fill", keyboardType: .numberPad)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
                Section("Notes") { TextEditor(text: $notes).frame(height: 80).font(.farmBody(15)) }
                if !errorMsg.isEmpty { Text(errorMsg).foregroundColor(.alertRed).font(.farmCaption(13)) }
            }
            .navigationTitle(existing == nil ? "Add Coop" : "Edit Coop")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { errorMsg = "Name required"; return }
                        guard let cap = Int(capacityText), cap > 0 else { errorMsg = "Valid capacity required"; return }
                        if var e = existing { e.name = name; e.capacity = cap; e.notes = notes; appState.updateCoop(e) }
                        else { appState.addCoop(Coop(name: name, capacity: cap, notes: notes)) }
                        dismiss()
                    }
                    .foregroundColor(.farmGreen).font(.farmHeadline(15))
                }
            }
        }
    }
}

// MARK: - Egg Tracker
struct EggTrackerView: View {
    @EnvironmentObject var appState: AppState
    @State private var showAdd = false
    @State private var selectedFilter: EggFilter = .all

    enum EggFilter: String, CaseIterable { case all = "All", today = "Today", week = "This Week" }

    var filtered: [EggRecord] {
        let sorted = appState.eggRecords.sorted { $0.date > $1.date }
        switch selectedFilter {
        case .all: return sorted
        case .today:
            let today = Calendar.current.startOfDay(for: Date())
            return sorted.filter { Calendar.current.startOfDay(for: $0.date) == today }
        case .week:
            let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            return sorted.filter { $0.date >= weekAgo }
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Summary banner
                HStack(spacing: 0) {
                    eggStat(value: "\(appState.todayEggCount)", label: "Today")
                    Divider().frame(height: 36)
                    eggStat(value: "\(appState.weekEggCount)", label: "This Week")
                    Divider().frame(height: 36)
                    eggStat(value: "\(appState.eggRecords.reduce(0) { $0 + $1.count })", label: "All Time")
                }
                .padding(.vertical, 16)
                .background(LinearGradient.eggGradient)

                // Filter
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(EggFilter.allCases, id: \.self) { f in Text(f.rawValue).tag(f) }
                }
                .pickerStyle(.segmented)
                .padding(16)

                if filtered.isEmpty {
                    EmptyStateView(icon: "oval.fill", title: "No Egg Records", message: "Tap + to log your first egg collection.")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(filtered) { record in
                            EggRecordRow(record: record)
                                .listRowBackground(Color.cardBackground)
                        }
                        .onDelete { offsets in offsets.map { filtered[$0] }.forEach { appState.deleteEggRecord($0) } }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .background(Color.surfaceLight.ignoresSafeArea())
            .navigationTitle("Egg Tracker")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAdd = true }) {
                        Image(systemName: "plus.circle.fill").foregroundColor(.farmGreen).font(.system(size: 22))
                    }
                }
            }
            .sheet(isPresented: $showAdd) { AddEggRecordView() }
        }
    }

    private func eggStat(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.farmNumber(24)).foregroundColor(.white)
            Text(label).font(.farmCaption(12)).foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
    }
}

struct EggRecordRow: View {
    let record: EggRecord
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(Color.eggYolk.opacity(0.15)).frame(width: 44, height: 44)
                Text("🥚").font(.system(size: 24))
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(record.birdGroupName).font(.farmBody(15)).foregroundColor(.textPrimary)
                Text(record.date.formatted(date: .abbreviated, time: .omitted)).font(.farmCaption(12)).foregroundColor(.textMuted)
            }
            Spacer()
            Text("\(record.count) eggs").font(.farmHeadline(16)).foregroundColor(.hayAmberDeep)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add Egg Record
struct AddEggRecordView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @State private var selectedGroupId: UUID? = nil
    @State private var customGroupName = ""
    @State private var countText = ""
    @State private var date = Date()
    @State private var notes = ""
    @State private var errorMsg = ""

    var selectedName: String {
        if let id = selectedGroupId, let group = appState.birdGroups.first(where: { $0.id == id }) { return group.name }
        return customGroupName
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Bird Group") {
                    if !appState.birdGroups.isEmpty {
                        Picker("Select Group", selection: $selectedGroupId) {
                            Text("None / Other").tag(nil as UUID?)
                            ForEach(appState.birdGroups) { g in Text(g.name).tag(g.id as UUID?) }
                        }
                    }
                    if selectedGroupId == nil {
                        FarmTextField(placeholder: "Group Name (manual)", text: $customGroupName, icon: "bird.fill")
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }
                }
                Section("Record") {
                    FarmTextField(placeholder: "Number of Eggs", text: $countText, icon: "oval.fill", keyboardType: .numberPad)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                        .font(.farmBody(15))
                }
                Section("Notes") { TextEditor(text: $notes).frame(height: 60).font(.farmBody(15)) }
                if !errorMsg.isEmpty { Text(errorMsg).foregroundColor(.alertRed).font(.farmCaption(13)) }
            }
            .navigationTitle("Add Egg Record")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        guard let count = Int(countText), count > 0 else { errorMsg = "Valid egg count required"; return }
                        let name = selectedName.trimmingCharacters(in: .whitespaces)
                        guard !name.isEmpty else { errorMsg = "Please select or enter a group name"; return }
                        let record = EggRecord(birdGroupId: selectedGroupId, birdGroupName: name, count: count, date: date, notes: notes)
                        appState.addEggRecord(record)
                        dismiss()
                    }
                    .foregroundColor(.farmGreen).font(.farmHeadline(15))
                }
            }
        }
    }
}

// MARK: - Feeding View
struct FeedingView: View {
    @EnvironmentObject var appState: AppState
    @State private var showAdd = false
    @State private var showStorage = false

    var recentFeedRecords: [FeedRecord] {
        appState.feedRecords.sorted { $0.date > $1.date }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Storage Overview
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("Feed Storage")
                                .font(.farmHeadline(16))
                                .foregroundColor(.textPrimary)
                            Spacer()
                            NavigationLink(destination: StorageView()) {
                                Text("Manage →")
                                    .font(.farmCaption(13))
                                    .foregroundColor(.farmGreen)
                            }
                        }

                        ForEach(appState.storageItems) { item in
                            VStack(spacing: 6) {
                                HStack {
                                    Circle()
                                        .fill(item.feedType.color)
                                        .frame(width: 10, height: 10)
                                    Text(item.feedType.rawValue)
                                        .font(.farmBody(14))
                                        .foregroundColor(.textPrimary)
                                    Spacer()
                                    Text("\(String(format: "%.1f", item.quantityKg))kg")
                                        .font(.farmBody(14))
                                        .foregroundColor(item.isLow ? .alertRed : .textPrimary)
                                    if item.isLow {
                                        Text("Low")
                                            .font(.farmCaption(10))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 6).padding(.vertical, 2)
                                            .background(Capsule().fill(Color.alertRed))
                                    }
                                }
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 4).fill(Color.divider).frame(height: 6)
                                        RoundedRectangle(cornerRadius: 4).fill(item.isLow ? Color.alertRed : item.feedType.color)
                                            .frame(width: max(6, geo.size.width * CGFloat(min(item.quantityKg / (item.reorderLevelKg * 5), 1))), height: 6)
                                    }
                                }
                                .frame(height: 6)
                            }
                        }
                    }
                    .farmCard()
                    .padding(.horizontal, 20)

                    // Feed Records
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Feed Records")
                            .font(.farmHeadline(16))
                            .foregroundColor(.textPrimary)
                            .padding(.horizontal, 20)

                        if recentFeedRecords.isEmpty {
                            EmptyStateView(icon: "bag.fill", title: "No Feed Records", message: "Tap + to log feeding.")
                        } else {
                            ForEach(recentFeedRecords.prefix(20)) { record in
                                HStack(spacing: 14) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12).fill(record.feedType.color.opacity(0.15)).frame(width: 44, height: 44)
                                        Image(systemName: "bag.fill").font(.system(size: 18)).foregroundColor(record.feedType.color)
                                    }
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(record.feedType.rawValue).font(.farmBody(15)).foregroundColor(.textPrimary)
                                        Text(record.birdGroupName).font(.farmCaption(12)).foregroundColor(.textSecondary)
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 3) {
                                        Text("\(String(format: "%.1f", record.amountKg))kg").font(.farmHeadline(14)).foregroundColor(.hayAmberDeep)
                                        Text(record.date.formatted(date: .abbreviated, time: .omitted)).font(.farmCaption(11)).foregroundColor(.textMuted)
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 4)
                                Divider().padding(.leading, 78).padding(.trailing, 20)
                            }
                        }
                    }
                }
                .padding(.vertical, 16)
            }
            .background(Color.surfaceLight.ignoresSafeArea())
            .navigationTitle("Feeding")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAdd = true }) {
                        Image(systemName: "plus.circle.fill").foregroundColor(.farmGreen).font(.system(size: 22))
                    }
                }
            }
            .sheet(isPresented: $showAdd) { AddFeedRecordView() }
        }
    }
}

// MARK: - Add Feed Record
struct AddFeedRecordView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @State private var feedType: FeedType = .corn
    @State private var amountText = ""
    @State private var selectedGroupId: UUID? = nil
    @State private var customGroupName = "All Birds"
    @State private var date = Date()
    @State private var notes = ""
    @State private var errorMsg = ""

    var body: some View {
        NavigationView {
            Form {
                Section("Feed") {
                    Picker("Feed Type", selection: $feedType) {
                        ForEach(FeedType.allCases, id: \.self) { t in Text(t.rawValue).tag(t) }
                    }
                    FarmTextField(placeholder: "Amount (kg)", text: $amountText, icon: "scalemass.fill", keyboardType: .decimalPad)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
                Section("Bird Group") {
                    if !appState.birdGroups.isEmpty {
                        Picker("Select Group", selection: $selectedGroupId) {
                            Text("All Birds").tag(nil as UUID?)
                            ForEach(appState.birdGroups) { g in Text(g.name).tag(g.id as UUID?) }
                        }
                    } else {
                        FarmTextField(placeholder: "Group Name", text: $customGroupName, icon: "bird.fill")
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }
                }
                Section("Date") { DatePicker("Date", selection: $date, displayedComponents: .date).font(.farmBody(15)) }
                Section("Notes") { TextEditor(text: $notes).frame(height: 60).font(.farmBody(15)) }
                if !errorMsg.isEmpty { Text(errorMsg).foregroundColor(.alertRed).font(.farmCaption(13)) }
            }
            .navigationTitle("Log Feeding")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        guard let amount = Double(amountText), amount > 0 else { errorMsg = "Valid amount required"; return }
                        let groupName: String
                        if let id = selectedGroupId, let g = appState.birdGroups.first(where: { $0.id == id }) { groupName = g.name }
                        else { groupName = customGroupName.isEmpty ? "All Birds" : customGroupName }
                        let rec = FeedRecord(feedType: feedType, amountKg: amount, birdGroupId: selectedGroupId, birdGroupName: groupName, date: date, notes: notes)
                        appState.addFeedRecord(rec)
                        dismiss()
                    }
                    .foregroundColor(.farmGreen).font(.farmHeadline(15))
                }
            }
        }
    }
}
