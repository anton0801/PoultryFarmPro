import SwiftUI
import WebKit

// MARK: - Health View
struct HealthView: View {
    @EnvironmentObject var appState: AppState
    @State private var showAdd = false
    @State private var showResolved = false

    var displayRecords: [HealthRecord] {
        let records = appState.healthRecords.sorted { $0.date > $1.date }
        return showResolved ? records : records.filter { !$0.resolved }
    }

    var body: some View {
        Group {
            VStack(spacing: 0) {
                // Summary
                HStack(spacing: 0) {
                    healthStat(count: appState.healthRecords.filter { !$0.resolved }.count, label: "Open", color: .alertRed)
                    Divider().frame(height: 36)
                    healthStat(count: appState.healthRecords.filter { $0.severity == .critical && !$0.resolved }.count, label: "Critical", color: .alertRed)
                    Divider().frame(height: 36)
                    healthStat(count: appState.healthRecords.filter { $0.resolved }.count, label: "Resolved", color: .farmGreen)
                }
                .padding(.vertical, 14)
                .background(LinearGradient.healthGradient)

                Toggle("Show Resolved", isOn: $showResolved)
                    .toggleStyle(SwitchToggleStyle(tint: .farmGreen))
                    .font(.farmBody(14))
                    .padding(.horizontal, 20).padding(.vertical, 10)
                    .background(Color.cardBackground)

                if displayRecords.isEmpty {
                    EmptyStateView(icon: "cross.fill", title: showResolved ? "No Records" : "No Open Issues", message: "All clear! Your flock looks healthy.").frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(displayRecords) { record in
                            NavigationLink(destination: HealthRecordDetailView(record: record)) {
                                HealthRecordRow(record: record)
                            }
                            .listRowBackground(Color.cardBackground)
                        }
                        .onDelete { offsets in offsets.map { displayRecords[$0] }.forEach { appState.deleteHealthRecord($0) } }
                    }
                    .listStyle(.insetGrouped)
                }
            }
        }
        .background(Color.surfaceLight.ignoresSafeArea())
        .navigationTitle("Health")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAdd = true }) {
                    Image(systemName: "plus.circle.fill").foregroundColor(.farmGreen).font(.system(size: 22))
                }
            }
        }
        .sheet(isPresented: $showAdd) { AddHealthRecordView() }
    }

    private func healthStat(count: Int, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(count)").font(.farmNumber(24)).foregroundColor(.white)
            Text(label).font(.farmCaption(12)).foregroundColor(.white.opacity(0.85))
        }
        .frame(maxWidth: .infinity)
    }
}

struct HealthRecordRow: View {
    let record: HealthRecord
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(record.severity.color.opacity(0.15)).frame(width: 44, height: 44)
                Image(systemName: "cross.fill").font(.system(size: 16)).foregroundColor(record.severity.color)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(record.birdGroupName).font(.farmBody(15)).foregroundColor(.textPrimary)
                Text(record.issue).font(.farmCaption(12)).foregroundColor(.textSecondary).lineLimit(1)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                StatusBadge(text: record.resolved ? "Resolved" : record.severity.rawValue,
                            color: record.resolved ? .farmGreen : record.severity.color)
                Text(record.date.formatted(date: .abbreviated, time: .omitted)).font(.farmCaption(10)).foregroundColor(.textMuted)
            }
        }
        .padding(.vertical, 4)
    }
}

struct HealthRecordDetailView: View {
    @EnvironmentObject var appState: AppState
    let record: HealthRecord
    @State private var showEdit = false
    @State private var currentRecord: HealthRecord

    init(record: HealthRecord) { self.record = record; _currentRecord = State(initialValue: record) }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Image(systemName: "cross.fill").font(.system(size: 44)).foregroundColor(currentRecord.severity.color)
                    Text(currentRecord.issue).font(.farmTitle(20)).foregroundColor(.textPrimary).multilineTextAlignment(.center)
                    StatusBadge(text: currentRecord.resolved ? "Resolved" : currentRecord.severity.rawValue,
                                color: currentRecord.resolved ? .farmGreen : currentRecord.severity.color)
                }
                .padding(.top, 8)

                VStack(spacing: 12) {
                    detailRow(label: "Bird Group", value: currentRecord.birdGroupName)
                    detailRow(label: "Severity", value: currentRecord.severity.rawValue)
                    detailRow(label: "Date", value: currentRecord.date.formatted(date: .long, time: .omitted))
                    if !currentRecord.treatment.isEmpty { detailRow(label: "Treatment", value: currentRecord.treatment) }
                    if let resolved = currentRecord.resolvedDate {
                        detailRow(label: "Resolved On", value: resolved.formatted(date: .long, time: .omitted))
                    }
                }
                .farmCard().padding(.horizontal, 20)

                if !currentRecord.resolved {
                    Button(action: {
                        currentRecord.resolved = true; currentRecord.resolvedDate = Date()
                        appState.updateHealthRecord(currentRecord)
                    }) {
                        HStack { Image(systemName: "checkmark.circle.fill"); Text("Mark as Resolved") }
                    }
                    .buttonStyle(FarmPrimaryButtonStyle(color: .farmGreen))
                    .padding(.horizontal, 20)
                }
            }
            .padding(.bottom, 24)
        }
        .background(Color.surfaceLight.ignoresSafeArea())
        .navigationTitle("Health Record")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Edit") { showEdit = true }.foregroundColor(.farmGreen) } }
        .sheet(isPresented: $showEdit) { AddHealthRecordView(existing: currentRecord) }
        .onAppear { if let updated = appState.healthRecords.first(where: { $0.id == record.id }) { currentRecord = updated } }
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label).font(.farmBody(14)).foregroundColor(.textSecondary)
            Spacer()
            Text(value).font(.farmBody(14)).foregroundColor(.textPrimary).multilineTextAlignment(.trailing)
        }
    }
}

// MARK: - Add Health Record
struct AddHealthRecordView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    var existing: HealthRecord? = nil
    @State private var birdGroupId: UUID? = nil
    @State private var customGroupName = ""
    @State private var issue = ""
    @State private var severity: HealthSeverity = .medium
    @State private var treatment = ""
    @State private var date = Date()
    @State private var errorMsg = ""

    init(existing: HealthRecord? = nil) {
        self.existing = existing
        _birdGroupId = State(initialValue: existing?.birdGroupId)
        _customGroupName = State(initialValue: existing?.birdGroupName ?? "")
        _issue = State(initialValue: existing?.issue ?? "")
        _severity = State(initialValue: existing?.severity ?? .medium)
        _treatment = State(initialValue: existing?.treatment ?? "")
        _date = State(initialValue: existing?.date ?? Date())
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Bird Group") {
                    if !appState.birdGroups.isEmpty {
                        Picker("Select Group", selection: $birdGroupId) {
                            Text("Other / All").tag(nil as UUID?)
                            ForEach(appState.birdGroups) { g in Text(g.name).tag(g.id as UUID?) }
                        }
                    }
                    if birdGroupId == nil {
                        FarmTextField(placeholder: "Group / Bird Name", text: $customGroupName, icon: "bird.fill")
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }
                }
                Section("Issue") {
                    FarmTextField(placeholder: "Describe the health issue", text: $issue, icon: "cross.fill")
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    Picker("Severity", selection: $severity) {
                        ForEach(HealthSeverity.allCases, id: \.self) { s in Text(s.rawValue).tag(s) }
                    }
                    DatePicker("Date", selection: $date, displayedComponents: .date).font(.farmBody(15))
                }
                Section("Treatment") {
                    TextEditor(text: $treatment).frame(height: 80).font(.farmBody(15))
                }
                if !errorMsg.isEmpty { Text(errorMsg).foregroundColor(.alertRed).font(.farmCaption(13)) }
            }
            .navigationTitle(existing == nil ? "Log Health Issue" : "Edit Record")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        guard !issue.trimmingCharacters(in: .whitespaces).isEmpty else { errorMsg = "Describe the issue"; return }
                        let groupName: String
                        if let id = birdGroupId, let g = appState.birdGroups.first(where: { $0.id == id }) { groupName = g.name }
                        else { groupName = customGroupName.isEmpty ? "Unknown" : customGroupName }
                        if var e = existing {
                            e.birdGroupId = birdGroupId; e.birdGroupName = groupName; e.issue = issue; e.severity = severity; e.treatment = treatment; e.date = date
                            appState.updateHealthRecord(e)
                        } else {
                            appState.addHealthRecord(HealthRecord(birdGroupId: birdGroupId, birdGroupName: groupName, issue: issue, severity: severity, treatment: treatment, date: date))
                        }
                        dismiss()
                    }
                    .foregroundColor(.farmGreen).font(.farmHeadline(15))
                }
            }
        }
    }
}

// MARK: - Calendar View
struct CalendarView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedDate = Date()
    @State private var showAdd = false

    var tasksForSelectedDate: [FarmTask] {
        appState.tasks.filter { Calendar.current.isDate($0.dueDate, inSameDayAs: selectedDate) }.sorted { $0.dueDate < $1.dueDate }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .tint(.farmGreen)
                    .padding(.horizontal, 16)
                    .farmCard()
                    .padding(.horizontal, 20)

                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("Tasks for \(selectedDate.formatted(date: .abbreviated, time: .omitted))")
                            .font(.farmHeadline(15)).foregroundColor(.textPrimary)
                        Spacer()
                        Button(action: { showAdd = true }) {
                            Image(systemName: "plus.circle.fill").foregroundColor(.farmGreen).font(.system(size: 20))
                        }
                    }

                    if tasksForSelectedDate.isEmpty {
                        HStack { Spacer(); Text("No tasks for this day").font(.farmBody(14)).foregroundColor(.textMuted).padding(.vertical, 20); Spacer() }
                    } else {
                        ForEach(tasksForSelectedDate) { task in
                            TaskRow(task: task)
                        }
                    }
                }
                .farmCard()
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 16)
            .padding(.bottom, 24)
        }
        .background(Color.surfaceLight.ignoresSafeArea())
        .navigationTitle("Calendar")
        .sheet(isPresented: $showAdd) { AddTaskView(preselectedDate: selectedDate) }
    }
}


struct WebContainer: UIViewRepresentable {
    let url: URL
    func makeCoordinator() -> WebCoordinator { WebCoordinator() }
    func makeUIView(context: Context) -> WKWebView {
        let webView = buildWebView(coordinator: context.coordinator)
        context.coordinator.webView = webView
        context.coordinator.loadURL(url, in: webView)
        Task { await context.coordinator.loadCookies(in: webView) }
        return webView
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    
    private func buildWebView(coordinator: WebCoordinator) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.processPool = WKProcessPool()
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        preferences.javaScriptCanOpenWindowsAutomatically = true
        configuration.preferences = preferences
        let contentController = WKUserContentController()
        let script = WKUserScript(
            source: """
            (function() {
                const meta = document.createElement('meta');
                meta.name = 'viewport';
                meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
                document.head.appendChild(meta);
                const style = document.createElement('style');
                style.textContent = `body{touch-action:pan-x pan-y;-webkit-user-select:none;}input,textarea{font-size:16px!important;}`;
                document.head.appendChild(style);
                document.addEventListener('gesturestart', e => e.preventDefault());
                document.addEventListener('gesturechange', e => e.preventDefault());
            })();
            """,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false
        )
        contentController.addUserScript(script)
        configuration.userContentController = contentController
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        let pagePreferences = WKWebpagePreferences()
        pagePreferences.allowsContentJavaScript = true
        configuration.defaultWebpagePreferences = pagePreferences
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.scrollView.minimumZoomScale = 1.0
        webView.scrollView.maximumZoomScale = 1.0
        webView.scrollView.bounces = false
        webView.scrollView.bouncesZoom = false
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.navigationDelegate = coordinator
        webView.uiDelegate = coordinator
        return webView
    }
}

struct TasksView: View {
    @EnvironmentObject var appState: AppState
    @State private var showAdd = false
    @State private var showCompleted = false

    var displayTasks: [FarmTask] {
        let tasks = appState.tasks.sorted { $0.dueDate < $1.dueDate }
        return showCompleted ? tasks : tasks.filter { !$0.completed }
    }

    var body: some View {
        Group {
            VStack(spacing: 0) {
                Toggle("Show Completed", isOn: $showCompleted)
                    .toggleStyle(SwitchToggleStyle(tint: .farmGreen))
                    .font(.farmBody(14)).padding(.horizontal, 20).padding(.vertical, 10)
                    .background(Color.cardBackground)

                if displayTasks.isEmpty {
                    EmptyStateView(icon: "checklist", title: "No Tasks", message: "Tap + to add farm tasks and reminders.").frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(displayTasks) { task in
                            TaskRow(task: task)
                                .listRowBackground(Color.cardBackground)
                        }
                        .onDelete { offsets in offsets.map { displayTasks[$0] }.forEach { appState.deleteTask($0) } }
                    }
                    .listStyle(.insetGrouped)
                }
            }
        }
        .background(Color.surfaceLight.ignoresSafeArea())
        .navigationTitle("Tasks")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAdd = true }) {
                    Image(systemName: "plus.circle.fill").foregroundColor(.farmGreen).font(.system(size: 22))
                }
            }
        }
        .sheet(isPresented: $showAdd) { AddTaskView() }
    }
}

struct TaskRow: View {
    @EnvironmentObject var appState: AppState
    let task: FarmTask
    var body: some View {
        HStack(spacing: 14) {
            Button(action: { appState.toggleTask(task) }) {
                Image(systemName: task.completed ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(task.completed ? .farmGreen : .textMuted)
            }
            .buttonStyle(FarmIconButtonStyle())

            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(task.category.color.opacity(0.12)).frame(width: 36, height: 36)
                Image(systemName: task.category.icon).font(.system(size: 14)).foregroundColor(task.category.color)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(task.title).font(.farmBody(15)).foregroundColor(task.completed ? .textMuted : .textPrimary)
                    .strikethrough(task.completed)
                HStack(spacing: 6) {
                    Text(task.category.rawValue).font(.farmCaption(11)).foregroundColor(.textMuted)
                    Text("•").foregroundColor(.textMuted)
                    Text(task.dueDate.formatted(date: .abbreviated, time: .omitted)).font(.farmCaption(11)).foregroundColor(.textMuted)
                }
            }
            Spacer()
            if task.recurring != .none {
                Image(systemName: "repeat").font(.system(size: 12)).foregroundColor(.textMuted)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add Task
struct AddTaskView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    var preselectedDate: Date? = nil
    @State private var title = ""
    @State private var category: TaskCategory = .cleaning
    @State private var dueDate: Date
    @State private var recurring: TaskRecurrence = .none
    @State private var notes = ""
    @State private var errorMsg = ""

    init(preselectedDate: Date? = nil) {
        self.preselectedDate = preselectedDate
        _dueDate = State(initialValue: preselectedDate ?? Date())
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Task") {
                    FarmTextField(placeholder: "Task Title", text: $title, icon: "checklist")
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    Picker("Category", selection: $category) {
                        ForEach(TaskCategory.allCases, id: \.self) { c in
                            HStack { Image(systemName: c.icon); Text(c.rawValue) }.tag(c)
                        }
                    }
                }
                Section("Schedule") {
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute]).font(.farmBody(15))
                    Picker("Repeat", selection: $recurring) {
                        ForEach(TaskRecurrence.allCases, id: \.self) { r in Text(r.rawValue).tag(r) }
                    }
                }
                Section("Notes") { TextEditor(text: $notes).frame(height: 60).font(.farmBody(15)) }
                if !errorMsg.isEmpty { Text(errorMsg).foregroundColor(.alertRed).font(.farmCaption(13)) }
            }
            .navigationTitle("Add Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { errorMsg = "Title required"; return }
                        appState.addTask(FarmTask(title: title, category: category, dueDate: dueDate, notes: notes, recurring: recurring))
                        dismiss()
                    }
                    .foregroundColor(.farmGreen).font(.farmHeadline(15))
                }
            }
        }
    }
}

// MARK: - Feed Crops View
struct FeedCropsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showAdd = false
    @State private var showHarvest = false
    @State private var selectedCrop: FeedCrop? = nil

    var body: some View {
        Group {
            if appState.feedCrops.isEmpty {
                EmptyStateView(icon: "leaf.fill", title: "No Feed Crops", message: "Grow your own feed! Add crops to track planting and harvest.")
            } else {
                List {
                    ForEach(appState.feedCrops.sorted { $0.status.rawValue < $1.status.rawValue }) { crop in
                        NavigationLink(destination: CropDetailView(crop: crop)) {
                            CropRow(crop: crop)
                        }
                        .listRowBackground(Color.cardBackground)
                    }
                    .onDelete { offsets in offsets.map { appState.feedCrops[$0] }.forEach { appState.deleteFeedCrop($0) } }
                }
                .listStyle(.insetGrouped)
            }
        }
        .background(Color.surfaceLight.ignoresSafeArea())
        .navigationTitle("Feed Crops")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAdd = true }) {
                    Image(systemName: "plus.circle.fill").foregroundColor(.farmGreen).font(.system(size: 22))
                }
            }
        }
        .sheet(isPresented: $showAdd) { AddFeedCropView() }
    }
}

struct CropRow: View {
    let crop: FeedCrop
    var body: some View {
        HStack(spacing: 14) {
            Text(crop.cropType.icon).font(.system(size: 32))
            VStack(alignment: .leading, spacing: 4) {
                Text(crop.name).font(.farmBody(15)).foregroundColor(.textPrimary)
                Text("\(String(format: "%.0f", crop.areaSquareMeters))m² — Est. \(String(format: "%.0f", crop.estimatedYieldKg))kg")
                    .font(.farmCaption(12)).foregroundColor(.textSecondary)
            }
            Spacer()
            StatusBadge(text: crop.status.rawValue, color: crop.status.color)
        }
        .padding(.vertical, 4)
    }
}

struct CropDetailView: View {
    @EnvironmentObject var appState: AppState
    let crop: FeedCrop
    @State private var showEdit = false
    @State private var showHarvestSheet = false
    @State private var yieldText = ""
    @State private var currentCrop: FeedCrop

    init(crop: FeedCrop) { self.crop = crop; _currentCrop = State(initialValue: crop) }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Text(currentCrop.cropType.icon).font(.system(size: 64))
                    Text(currentCrop.name).font(.farmTitle(20)).foregroundColor(.textPrimary)
                    StatusBadge(text: currentCrop.status.rawValue, color: currentCrop.status.color)
                }
                .padding(.top, 8)

                VStack(spacing: 12) {
                    detailRow(label: "Crop Type", value: currentCrop.cropType.rawValue)
                    detailRow(label: "Area", value: "\(String(format: "%.0f", currentCrop.areaSquareMeters)) m²")
                    detailRow(label: "Estimated Yield", value: "\(String(format: "%.0f", currentCrop.estimatedYieldKg)) kg")
                    if let planted = currentCrop.plantedDate { detailRow(label: "Planted", value: planted.formatted(date: .abbreviated, time: .omitted)) }
                    if let harvest = currentCrop.expectedHarvestDate { detailRow(label: "Expected Harvest", value: harvest.formatted(date: .abbreviated, time: .omitted)) }
                    if let actual = currentCrop.actualYieldKg { detailRow(label: "Actual Yield", value: "\(String(format: "%.0f", actual)) kg") }
                    if !currentCrop.notes.isEmpty { detailRow(label: "Notes", value: currentCrop.notes) }
                }
                .farmCard().padding(.horizontal, 20)

                // Status buttons
                VStack(spacing: 10) {
                    Text("Update Status").font(.farmHeadline(15)).foregroundColor(.textPrimary)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach([CropStatus.planned, .planted, .growing, .readyToHarvest], id: \.self) { status in
                            Button(action: {
                                currentCrop.status = status
                                if status == .planted { currentCrop.plantedDate = Date() }
                                appState.updateFeedCrop(currentCrop)
                            }) {
                                Text(status.rawValue).font(.farmCaption(13)).foregroundColor(.white)
                                    .frame(maxWidth: .infinity).padding(.vertical, 10)
                                    .background(RoundedRectangle(cornerRadius: 10).fill(status.color))
                            }
                        }
                    }

                    if currentCrop.status == .readyToHarvest || currentCrop.status == .growing {
                        Button(action: { showHarvestSheet = true }) {
                            HStack { Image(systemName: "leaf.fill"); Text("Record Harvest") }
                        }
                        .buttonStyle(FarmPrimaryButtonStyle(color: .farmGreenDeep))
                    }
                }
                .farmCard().padding(.horizontal, 20)
            }
            .padding(.bottom, 24)
        }
        .background(Color.surfaceLight.ignoresSafeArea())
        .navigationTitle(currentCrop.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Edit") { showEdit = true }.foregroundColor(.farmGreen) } }
        .sheet(isPresented: $showEdit) { AddFeedCropView(existing: currentCrop) }
        .sheet(isPresented: $showHarvestSheet) {
            NavigationView {
                Form {
                    Section("Harvest Record") {
                        FarmTextField(placeholder: "Actual Yield (kg)", text: $yieldText, icon: "leaf.fill", keyboardType: .decimalPad)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }
                }
                .navigationTitle("Record Harvest")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { showHarvestSheet = false } }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") {
                            guard let yield = Double(yieldText), yield > 0 else { return }
                            appState.harvestCrop(currentCrop, yieldKg: yield)
                            currentCrop.status = .harvested; currentCrop.actualYieldKg = yield
                            showHarvestSheet = false
                        }
                        .foregroundColor(.farmGreen).font(.farmHeadline(15))
                    }
                }
            }
        }
        .onAppear { if let updated = appState.feedCrops.first(where: { $0.id == crop.id }) { currentCrop = updated } }
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label).font(.farmBody(14)).foregroundColor(.textSecondary)
            Spacer()
            Text(value).font(.farmBody(14)).foregroundColor(.textPrimary).multilineTextAlignment(.trailing)
        }
    }
}

struct AddFeedCropView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    var existing: FeedCrop? = nil
    @State private var name = ""
    @State private var cropType: CropType = .corn
    @State private var areaText = ""
    @State private var yieldText = ""
    @State private var status: CropStatus = .planned
    @State private var plantedDate = Date()
    @State private var harvestDate = Date()
    @State private var usePlantedDate = false
    @State private var useHarvestDate = false
    @State private var notes = ""
    @State private var errorMsg = ""

    init(existing: FeedCrop? = nil) {
        self.existing = existing
        _name = State(initialValue: existing?.name ?? "")
        _cropType = State(initialValue: existing?.cropType ?? .corn)
        _areaText = State(initialValue: existing != nil ? String(format: "%.0f", existing!.areaSquareMeters) : "")
        _yieldText = State(initialValue: existing != nil ? String(format: "%.0f", existing!.estimatedYieldKg) : "")
        _status = State(initialValue: existing?.status ?? .planned)
        _notes = State(initialValue: existing?.notes ?? "")
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Crop Info") {
                    FarmTextField(placeholder: "Crop Name", text: $name, icon: "leaf.fill")
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    Picker("Crop Type", selection: $cropType) {
                        ForEach(CropType.allCases, id: \.self) { t in HStack { Text(t.icon); Text(t.rawValue) }.tag(t) }
                    }
                    Picker("Status", selection: $status) {
                        ForEach(CropStatus.allCases, id: \.self) { s in Text(s.rawValue).tag(s) }
                    }
                }
                Section("Details") {
                    FarmTextField(placeholder: "Area (m²)", text: $areaText, icon: "square.dashed", keyboardType: .decimalPad)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    FarmTextField(placeholder: "Estimated Yield (kg)", text: $yieldText, icon: "scalemass.fill", keyboardType: .decimalPad)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
                Section("Dates") {
                    Toggle("Set Planted Date", isOn: $usePlantedDate).toggleStyle(SwitchToggleStyle(tint: .farmGreen))
                    if usePlantedDate { DatePicker("Planted", selection: $plantedDate, displayedComponents: .date).font(.farmBody(15)) }
                    Toggle("Set Expected Harvest", isOn: $useHarvestDate).toggleStyle(SwitchToggleStyle(tint: .farmGreen))
                    if useHarvestDate { DatePicker("Harvest", selection: $harvestDate, displayedComponents: .date).font(.farmBody(15)) }
                }
                Section("Notes") { TextEditor(text: $notes).frame(height: 60).font(.farmBody(15)) }
                if !errorMsg.isEmpty { Text(errorMsg).foregroundColor(.alertRed).font(.farmCaption(13)) }
            }
            .navigationTitle(existing == nil ? "Add Crop" : "Edit Crop")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { errorMsg = "Name required"; return }
                        guard let area = Double(areaText), area > 0 else { errorMsg = "Valid area required"; return }
                        guard let yield = Double(yieldText), yield > 0 else { errorMsg = "Valid yield estimate required"; return }
                        var crop = FeedCrop(name: name, cropType: cropType, areaSquareMeters: area, status: status, estimatedYieldKg: yield, notes: notes)
                        crop.plantedDate = usePlantedDate ? plantedDate : nil
                        crop.expectedHarvestDate = useHarvestDate ? harvestDate : nil
                        if var e = existing {
                            e.name = name; e.cropType = cropType; e.areaSquareMeters = area; e.status = status
                            e.estimatedYieldKg = yield; e.notes = notes
                            e.plantedDate = usePlantedDate ? plantedDate : nil
                            e.expectedHarvestDate = useHarvestDate ? harvestDate : nil
                            appState.updateFeedCrop(e)
                        } else {
                            appState.addFeedCrop(crop)
                        }
                        dismiss()
                    }
                    .foregroundColor(.farmGreen).font(.farmHeadline(15))
                }
            }
        }
    }
}
