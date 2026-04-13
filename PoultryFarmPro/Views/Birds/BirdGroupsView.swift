import SwiftUI

// MARK: - Bird Groups List
struct BirdGroupsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showAdd = false
    @State private var searchText = ""

    var filtered: [BirdGroup] {
        if searchText.isEmpty { return appState.birdGroups }
        return appState.birdGroups.filter { $0.name.localizedCaseInsensitiveContains(searchText) || $0.birdType.rawValue.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationView {
            Group {
                if appState.birdGroups.isEmpty {
                    EmptyStateView(icon: "bird.fill", title: "No Bird Groups Yet", message: "Add your first flock to start tracking your birds.")
                } else {
                    List {
                        ForEach(filtered) { group in
                            NavigationLink(destination: BirdDetailView(group: group)) {
                                BirdGroupRow(group: group)
                            }
                            .listRowBackground(Color.cardBackground)
                        }
                        .onDelete { offsets in
                            offsets.map { filtered[$0] }.forEach { appState.deleteBirdGroup($0) }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .searchable(text: $searchText, prompt: "Search groups...")
                }
            }
            .background(Color.surfaceLight.ignoresSafeArea())
            .navigationTitle("Bird Groups")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAdd = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.farmGreen)
                            .font(.system(size: 22))
                    }
                }
            }
            .sheet(isPresented: $showAdd) { AddBirdGroupView() }
        }
    }
}

struct BirdGroupRow: View {
    let group: BirdGroup
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.farmGreen.opacity(0.12))
                    .frame(width: 48, height: 48)
                Text(group.birdType.icon)
                    .font(.system(size: 26))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(group.name)
                    .font(.farmBody(15))
                    .foregroundColor(.textPrimary)
                HStack(spacing: 8) {
                    Label("\(group.count)", systemImage: "number")
                        .font(.farmCaption(12))
                        .foregroundColor(.textSecondary)
                    Text("•")
                        .foregroundColor(.textMuted)
                    Text("\(group.ageWeeks)w — \(group.ageDescription)")
                        .font(.farmCaption(12))
                        .foregroundColor(.textSecondary)
                }
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add Bird Group
struct AddBirdGroupView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var birdType: BirdType = .chicken
    @State private var countText = ""
    @State private var ageText = ""
    @State private var selectedCoop: Coop? = nil
    @State private var notes = ""
    @State private var errorMsg = ""

    var body: some View {
        NavigationView {
            Form {
                Section("Group Info") {
                    FarmTextField(placeholder: "Group Name (e.g. Layer Hens A)", text: $name, icon: "tag.fill")
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))

                    Picker("Bird Type", selection: $birdType) {
                        ForEach(BirdType.allCases, id: \.self) { type in
                            HStack {
                                Text(type.icon)
                                Text(type.rawValue)
                            }.tag(type)
                        }
                    }
                }

                Section("Numbers") {
                    FarmTextField(placeholder: "Number of Birds", text: $countText, icon: "number.circle.fill", keyboardType: .numberPad)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    FarmTextField(placeholder: "Age (in weeks)", text: $ageText, icon: "clock.fill", keyboardType: .numberPad)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }

                if !appState.coops.isEmpty {
                    Section("Coop Assignment") {
                        Picker("Assign to Coop", selection: $selectedCoop) {
                            Text("None").tag(nil as Coop?)
                            ForEach(appState.coops) { coop in
                                Text(coop.name).tag(coop as Coop?)
                            }
                        }
                    }
                }

                Section("Notes (Optional)") {
                    TextEditor(text: $notes)
                        .frame(height: 80)
                        .font(.farmBody(15))
                }

                if !errorMsg.isEmpty {
                    Section {
                        Text(errorMsg).foregroundColor(.alertRed).font(.farmCaption(13))
                    }
                }
            }
            .navigationTitle("Add Bird Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { save() }
                        .font(.farmHeadline(15))
                        .foregroundColor(.farmGreen)
                }
            }
        }
    }

    private func save() {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { errorMsg = "Group name is required"; return }
        guard let count = Int(countText), count > 0 else { errorMsg = "Enter a valid bird count"; return }
        guard let age = Int(ageText), age >= 0 else { errorMsg = "Enter a valid age in weeks"; return }

        let group = BirdGroup(
            name: name,
            birdType: birdType,
            count: count,
            ageWeeks: age,
            coopId: selectedCoop?.id,
            notes: notes
        )
        appState.addBirdGroup(group)
        dismiss()
    }
}

// MARK: - Bird Detail
struct BirdDetailView: View {
    @EnvironmentObject var appState: AppState
    let group: BirdGroup

    @State private var showEdit = false

    var recentEggs: [EggRecord] {
        appState.eggRecords
            .filter { $0.birdGroupId == group.id }
            .sorted { $0.date > $1.date }
            .prefix(7)
            .map { $0 }
    }

    var totalEggs: Int {
        appState.eggRecords
            .filter { $0.birdGroupId == group.id }
            .reduce(0) { $0 + $1.count }
    }

    var recentHealthRecords: [HealthRecord] {
        appState.healthRecords
            .filter { $0.birdGroupId == group.id }
            .sorted { $0.date > $1.date }
            .prefix(3)
            .map { $0 }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Hero Card
                VStack(spacing: 14) {
                    Text(group.birdType.icon)
                        .font(.system(size: 72))
                    Text(group.name)
                        .font(.farmTitle(22))
                        .foregroundColor(.textPrimary)
                    HStack(spacing: 16) {
                        StatusBadge(text: group.birdType.rawValue, color: .farmGreen)
                        StatusBadge(text: group.ageDescription, color: .hayAmberDeep)
                    }
                }
                .padding(.top, 8)

                // Stats
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    miniStat(value: "\(group.count)", label: "Birds")
                    miniStat(value: "\(group.ageWeeks)w", label: "Age")
                    miniStat(value: "\(totalEggs)", label: "Total Eggs")
                }
                .padding(.horizontal, 20)

                // Recent Egg Production
                if !recentEggs.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Egg Production (Last 7 Records)")
                            .font(.farmHeadline(15))
                            .foregroundColor(.textPrimary)

                        ForEach(recentEggs) { record in
                            HStack {
                                Image(systemName: "oval.fill")
                                    .foregroundColor(.eggYolk)
                                    .font(.system(size: 14))
                                Text("\(record.count) eggs")
                                    .font(.farmBody(14))
                                    .foregroundColor(.textPrimary)
                                Spacer()
                                Text(record.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.farmCaption(12))
                                    .foregroundColor(.textMuted)
                            }
                            .padding(.vertical, 6)
                            if record.id != recentEggs.last?.id {
                                Divider()
                            }
                        }
                    }
                    .farmCard()
                    .padding(.horizontal, 20)
                }

                // Health Records
                if !recentHealthRecords.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Health Records")
                            .font(.farmHeadline(15))
                            .foregroundColor(.textPrimary)

                        ForEach(recentHealthRecords) { record in
                            HStack {
                                Circle()
                                    .fill(record.severity.color)
                                    .frame(width: 10, height: 10)
                                Text(record.issue)
                                    .font(.farmBody(14))
                                    .foregroundColor(.textPrimary)
                                Spacer()
                                StatusBadge(text: record.resolved ? "Resolved" : record.severity.rawValue,
                                            color: record.resolved ? .farmGreen : record.severity.color)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .farmCard()
                    .padding(.horizontal, 20)
                }

                // Notes
                if !group.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.farmHeadline(15))
                            .foregroundColor(.textPrimary)
                        Text(group.notes)
                            .font(.farmBody(14))
                            .foregroundColor(.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .farmCard()
                    .padding(.horizontal, 20)
                }
            }
            .padding(.bottom, 24)
        }
        .background(Color.surfaceLight.ignoresSafeArea())
        .navigationTitle(group.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") { showEdit = true }
                    .foregroundColor(.farmGreen)
            }
        }
        .sheet(isPresented: $showEdit) { EditBirdGroupView(group: group) }
    }

    private func miniStat(value: String, label: String) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.farmNumber(22))
                .foregroundColor(.textPrimary)
            Text(label)
                .font(.farmCaption(12))
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.cardBackground))
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Edit Bird Group
struct EditBirdGroupView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @State var group: BirdGroup
    @State private var countText: String
    @State private var ageText: String
    @State private var errorMsg = ""

    init(group: BirdGroup) {
        self._group = State(initialValue: group)
        self._countText = State(initialValue: "\(group.count)")
        self._ageText = State(initialValue: "\(group.ageWeeks)")
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Group Info") {
                    FarmTextField(placeholder: "Group Name", text: $group.name, icon: "tag.fill")
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    Picker("Bird Type", selection: $group.birdType) {
                        ForEach(BirdType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                }
                Section("Numbers") {
                    FarmTextField(placeholder: "Number of Birds", text: $countText, icon: "number.circle.fill", keyboardType: .numberPad)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    FarmTextField(placeholder: "Age (weeks)", text: $ageText, icon: "clock.fill", keyboardType: .numberPad)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
                Section("Notes") {
                    TextEditor(text: $group.notes)
                        .frame(height: 80)
                        .font(.farmBody(15))
                }
                if !errorMsg.isEmpty {
                    Text(errorMsg).foregroundColor(.alertRed).font(.farmCaption(13))
                }
            }
            .navigationTitle("Edit Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        guard let count = Int(countText), count > 0 else { errorMsg = "Valid count required"; return }
                        guard let age = Int(ageText), age >= 0 else { errorMsg = "Valid age required"; return }
                        group.count = count; group.ageWeeks = age
                        appState.updateBirdGroup(group)
                        dismiss()
                    }
                    .foregroundColor(.farmGreen).font(.farmHeadline(15))
                }
            }
        }
    }
}
