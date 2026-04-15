import SwiftUI
import WebKit

// MARK: - Storage View
struct StorageView: View {
    @EnvironmentObject var appState: AppState
    @State private var showAddStock = false
    @State private var selectedItem: StorageItem? = nil

    var body: some View {
        Group {
            List {
                ForEach(appState.storageItems) { item in
                    Button(action: { selectedItem = item }) {
                        StorageRow(item: item)
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(Color.cardBackground)
                }
            }
            .listStyle(.insetGrouped)
        }
        .background(Color.surfaceLight.ignoresSafeArea())
        .navigationTitle("Feed Storage")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAddStock = true }) {
                    Image(systemName: "plus.circle.fill").foregroundColor(.farmGreen).font(.system(size: 22))
                }
            }
        }
        .sheet(isPresented: $showAddStock) { AddStockView() }
        .sheet(item: $selectedItem) { item in EditStorageItemView(item: item) }
    }
}

extension WebCoordinator: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer, let view = pan.view else { return false }
        let velocity = pan.velocity(in: view)
        let translation = pan.translation(in: view)
        return translation.x > 0 && abs(velocity.x) > abs(velocity.y)
    }
}

struct StorageRow: View {
    let item: StorageItem
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(item.feedType.color.opacity(0.15)).frame(width: 44, height: 44)
                Image(systemName: "shippingbox.fill").font(.system(size: 18)).foregroundColor(item.feedType.color)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(item.feedType.rawValue).font(.farmBody(15)).foregroundColor(.textPrimary)
                Text("Reorder at \(String(format: "%.0f", item.reorderLevelKg))kg").font(.farmCaption(12)).foregroundColor(.textSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text("\(String(format: "%.1f", item.quantityKg))kg")
                    .font(.farmHeadline(16))
                    .foregroundColor(item.isLow ? .alertRed : .textPrimary)
                if item.isLow { Text("Low Stock").font(.farmCaption(10)).foregroundColor(.alertRed) }
            }
        }
        .padding(.vertical, 4)
    }
}

struct AddStockView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var feedType: FeedType = .corn
    @State private var amountText = ""
    @State private var errorMsg = ""

    var body: some View {
        NavigationView {
            Form {
                Section("Add Stock") {
                    Picker("Feed Type", selection: $feedType) {
                        ForEach(FeedType.allCases, id: \.self) { t in Text(t.rawValue).tag(t) }
                    }
                    FarmTextField(placeholder: "Amount to Add (kg)", text: $amountText, icon: "plus.circle.fill", keyboardType: .decimalPad)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
                if !errorMsg.isEmpty { Text(errorMsg).foregroundColor(.alertRed).font(.farmCaption(13)) }
            }
            .navigationTitle("Add Feed Stock")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        guard let amount = Double(amountText), amount > 0 else { errorMsg = "Valid amount required"; return }
                        appState.addToStorage(feedType: feedType, amountKg: amount)
                        dismiss()
                    }
                    .foregroundColor(.farmGreen).font(.farmHeadline(15))
                }
            }
        }
    }
}

struct EditStorageItemView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State var item: StorageItem
    @State private var quantityText: String
    @State private var reorderText: String

    init(item: StorageItem) {
        _item = State(initialValue: item)
        _quantityText = State(initialValue: String(format: "%.1f", item.quantityKg))
        _reorderText = State(initialValue: String(format: "%.1f", item.reorderLevelKg))
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Edit \(item.feedType.rawValue) Stock") {
                    FarmTextField(placeholder: "Current Quantity (kg)", text: $quantityText, icon: "scalemass.fill", keyboardType: .decimalPad)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    FarmTextField(placeholder: "Reorder Level (kg)", text: $reorderText, icon: "exclamationmark.triangle.fill", keyboardType: .decimalPad)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
            }
            .navigationTitle("Edit Stock")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        guard let q = Double(quantityText), let r = Double(reorderText) else { return }
                        item.quantityKg = q; item.reorderLevelKg = r
                        appState.updateStorage(item); dismiss()
                    }
                    .foregroundColor(.farmGreen).font(.farmHeadline(15))
                }
            }
        }
    }
}

final class WebCoordinator: NSObject {
    weak var webView: WKWebView?
    private var redirectCount = 0, maxRedirects = 70
    private var lastURL: URL?, checkpoint: URL?
    private var popups: [WKWebView] = []
    private let cookieJar = "poultryfarm_cookies"
    
    func loadURL(_ url: URL, in webView: WKWebView) {
        print("🐔 [PoultryFarm] Load: \(url.absoluteString)")
        redirectCount = 0
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        webView.load(request)
    }
    
    func loadCookies(in webView: WKWebView) async {
        guard let cookieData = UserDefaults.standard.object(forKey: cookieJar) as? [String: [String: [HTTPCookiePropertyKey: AnyObject]]] else { return }
        let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
        let cookies = cookieData.values.flatMap { $0.values }.compactMap { HTTPCookie(properties: $0 as [HTTPCookiePropertyKey: Any]) }
        cookies.forEach { cookieStore.setCookie($0) }
    }
    
    private func saveCookies(from webView: WKWebView) {
        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { [weak self] cookies in
            guard let self = self else { return }
            var cookieData: [String: [String: [HTTPCookiePropertyKey: Any]]] = [:]
            for cookie in cookies {
                var domainCookies = cookieData[cookie.domain] ?? [:]
                if let properties = cookie.properties { domainCookies[cookie.name] = properties }
                cookieData[cookie.domain] = domainCookies
            }
            UserDefaults.standard.set(cookieData, forKey: self.cookieJar)
        }
    }
}

struct BreedingView: View {
    @EnvironmentObject var appState: AppState
    @State private var showAdd = false

    var body: some View {
        Group {
            if appState.breedingPairs.isEmpty {
                EmptyStateView(icon: "heart.fill", title: "No Breeding Pairs", message: "Set up breeding pairs to manage your flock's reproduction.")
            } else {
                List {
                    ForEach(appState.breedingPairs) { pair in
                        NavigationLink(destination: BreedingPairDetailView(pair: pair)) {
                            BreedingPairRow(pair: pair)
                        }
                        .listRowBackground(Color.cardBackground)
                    }
                    .onDelete { offsets in offsets.map { appState.breedingPairs[$0] }.forEach { appState.deleteBreedingPair($0) } }
                }
                .listStyle(.insetGrouped)
            }
        }
        .background(Color.surfaceLight.ignoresSafeArea())
        .navigationTitle("Breeding")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAdd = true }) {
                    Image(systemName: "plus.circle.fill").foregroundColor(.farmGreen).font(.system(size: 22))
                }
            }
        }
        .sheet(isPresented: $showAdd) { AddBreedingPairView() }
    }
}

struct BreedingPairRow: View {
    let pair: BreedingPair
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(Color(hex: "#FF6B9D").opacity(0.12)).frame(width: 44, height: 44)
                Image(systemName: "heart.fill").font(.system(size: 18)).foregroundColor(Color(hex: "#FF6B9D"))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("\(pair.maleName) × \(pair.femaleName)").font(.farmBody(15)).foregroundColor(.textPrimary)
                Text("Started: \(pair.startDate.formatted(date: .abbreviated, time: .omitted))").font(.farmCaption(12)).foregroundColor(.textSecondary)
            }
            Spacer()
            StatusBadge(text: pair.status.rawValue, color: pair.status.color)
        }
        .padding(.vertical, 4)
    }
}

struct BreedingPairDetailView: View {
    @EnvironmentObject var appState: AppState
    let pair: BreedingPair
    @State private var showEdit = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 10) {
                    Image(systemName: "heart.fill").font(.system(size: 48)).foregroundColor(Color(hex: "#FF6B9D"))
                    Text("\(pair.maleName) × \(pair.femaleName)").font(.farmTitle(20)).foregroundColor(.textPrimary)
                    StatusBadge(text: pair.status.rawValue, color: pair.status.color)
                }
                .padding(.top, 8)

                VStack(spacing: 14) {
                    detailRow(label: "Start Date", value: pair.startDate.formatted(date: .long, time: .omitted))
                    if let hatch = pair.expectedHatchDate {
                        detailRow(label: "Expected Hatch", value: hatch.formatted(date: .long, time: .omitted))
                    }
                    if !pair.notes.isEmpty { detailRow(label: "Notes", value: pair.notes) }
                }
                .farmCard()
                .padding(.horizontal, 20)

                // Status change buttons
                VStack(spacing: 12) {
                    Text("Update Status").font(.farmHeadline(15)).foregroundColor(.textPrimary)
                    HStack(spacing: 10) {
                        ForEach([BreedingStatus.active, .incubating, .hatched, .completed], id: \.self) { status in
                            Button(action: {
                                var updated = pair; updated.status = status
                                appState.updateBreedingPair(updated)
                            }) {
                                Text(status.rawValue).font(.farmCaption(12)).foregroundColor(.white)
                                    .padding(.horizontal, 12).padding(.vertical, 8)
                                    .background(Capsule().fill(status.color))
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .farmCard()
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 24)
        }
        .background(Color.surfaceLight.ignoresSafeArea())
        .navigationTitle("Breeding Pair")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Edit") { showEdit = true }.foregroundColor(.farmGreen) } }
        .sheet(isPresented: $showEdit) { AddBreedingPairView(existing: pair) }
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label).font(.farmBody(14)).foregroundColor(.textSecondary)
            Spacer()
            Text(value).font(.farmBody(14)).foregroundColor(.textPrimary).multilineTextAlignment(.trailing)
        }
    }
}

extension WebCoordinator: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard navigationAction.targetFrame == nil else { return nil }
        let popup = WKWebView(frame: webView.bounds, configuration: configuration)
        popup.navigationDelegate = self
        popup.uiDelegate = self
        popup.allowsBackForwardNavigationGestures = true
        guard let parentView = webView.superview else { return nil }
        parentView.addSubview(popup)
        popup.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            popup.topAnchor.constraint(equalTo: webView.topAnchor),
            popup.bottomAnchor.constraint(equalTo: webView.bottomAnchor),
            popup.leadingAnchor.constraint(equalTo: webView.leadingAnchor),
            popup.trailingAnchor.constraint(equalTo: webView.trailingAnchor)
        ])
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handlePopupPan(_:)))
        gesture.delegate = self
        popup.scrollView.panGestureRecognizer.require(toFail: gesture)
        popup.addGestureRecognizer(gesture)
        popups.append(popup)
        if let url = navigationAction.request.url, url.absoluteString != "about:blank" {
            popup.load(navigationAction.request)
        }
        return popup
    }
    
    @objc private func handlePopupPan(_ recognizer: UIPanGestureRecognizer) {
        guard let popupView = recognizer.view else { return }
        let translation = recognizer.translation(in: popupView)
        let velocity = recognizer.velocity(in: popupView)
        switch recognizer.state {
        case .changed:
            if translation.x > 0 { popupView.transform = CGAffineTransform(translationX: translation.x, y: 0) }
        case .ended, .cancelled:
            let shouldClose = translation.x > popupView.bounds.width * 0.4 || velocity.x > 800
            if shouldClose {
                UIView.animate(withDuration: 0.25, animations: {
                    popupView.transform = CGAffineTransform(translationX: popupView.bounds.width, y: 0)
                }) { [weak self] _ in self?.dismissTopPopup() }
            } else {
                UIView.animate(withDuration: 0.2) { popupView.transform = .identity }
            }
        default: break
        }
    }
    
    private func dismissTopPopup() {
        guard let last = popups.last else { return }
        last.removeFromSuperview()
        popups.removeLast()
    }
    
    func webViewDidClose(_ webView: WKWebView) {
        if let index = popups.firstIndex(of: webView) {
            webView.removeFromSuperview()
            popups.remove(at: index)
        }
    }
    
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        completionHandler()
    }
}


struct AddBreedingPairView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    var existing: BreedingPair? = nil
    @State private var maleName = ""
    @State private var femaleName = ""
    @State private var startDate = Date()
    @State private var status: BreedingStatus = .active
    @State private var notes = ""
    @State private var errorMsg = ""

    init(existing: BreedingPair? = nil) {
        self.existing = existing
        _maleName = State(initialValue: existing?.maleName ?? "")
        _femaleName = State(initialValue: existing?.femaleName ?? "")
        _startDate = State(initialValue: existing?.startDate ?? Date())
        _status = State(initialValue: existing?.status ?? .active)
        _notes = State(initialValue: existing?.notes ?? "")
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Pair Details") {
                    FarmTextField(placeholder: "Male Bird / Group Name", text: $maleName, icon: "bird.fill")
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    FarmTextField(placeholder: "Female Bird / Group Name", text: $femaleName, icon: "bird.fill")
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date).font(.farmBody(15))
                    Picker("Status", selection: $status) {
                        ForEach(BreedingStatus.allCases, id: \.self) { s in Text(s.rawValue).tag(s) }
                    }
                }
                Section("Notes") { TextEditor(text: $notes).frame(height: 80).font(.farmBody(15)) }
                if !errorMsg.isEmpty { Text(errorMsg).foregroundColor(.alertRed).font(.farmCaption(13)) }
            }
            .navigationTitle(existing == nil ? "Add Breeding Pair" : "Edit Pair")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        guard !maleName.trimmingCharacters(in: .whitespaces).isEmpty else { errorMsg = "Male name required"; return }
                        guard !femaleName.trimmingCharacters(in: .whitespaces).isEmpty else { errorMsg = "Female name required"; return }
                        if var e = existing {
                            e.maleName = maleName; e.femaleName = femaleName; e.startDate = startDate; e.status = status; e.notes = notes
                            appState.updateBreedingPair(e)
                        } else {
                            appState.addBreedingPair(BreedingPair(maleName: maleName, femaleName: femaleName, startDate: startDate, status: status, notes: notes))
                        }
                        dismiss()
                    }
                    .foregroundColor(.farmGreen).font(.farmHeadline(15))
                }
            }
        }
    }
}

// MARK: - Incubator View
struct IncubatorView: View {
    @EnvironmentObject var appState: AppState
    @State private var showAdd = false

    var body: some View {
        Group {
            if appState.incubatorBatches.isEmpty {
                EmptyStateView(icon: "thermometer.medium", title: "No Incubator Batches", message: "Add a batch to track egg hatching progress.")
            } else {
                List {
                    ForEach(appState.incubatorBatches) { batch in
                        NavigationLink(destination: IncubatorBatchDetailView(batch: batch)) {
                            IncubatorBatchRow(batch: batch)
                        }
                        .listRowBackground(Color.cardBackground)
                    }
                    .onDelete { offsets in offsets.map { appState.incubatorBatches[$0] }.forEach { appState.deleteIncubatorBatch($0) } }
                }
                .listStyle(.insetGrouped)
            }
        }
        .background(Color.surfaceLight.ignoresSafeArea())
        .navigationTitle("Incubator")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAdd = true }) {
                    Image(systemName: "plus.circle.fill").foregroundColor(.farmGreen).font(.system(size: 22))
                }
            }
        }
        .sheet(isPresented: $showAdd) { AddIncubatorBatchView() }
    }
}

struct IncubatorBatchRow: View {
    let batch: IncubatorBatch
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(batch.birdType.icon).font(.system(size: 22))
                Text(batch.name).font(.farmBody(15)).foregroundColor(.textPrimary)
                Spacer()
                Text("\(batch.daysRemaining)d left").font(.farmCaption(12))
                    .foregroundColor(batch.daysRemaining <= 3 ? .alertRed : .textSecondary)
            }
            ProgressView(value: batch.progress)
                .tint(batch.progress >= 1 ? .farmGreen : .infoBlue)
            HStack {
                Text("\(batch.eggCount) eggs").font(.farmCaption(12)).foregroundColor(.textMuted)
                Spacer()
                Text("\(Int(batch.progress * 100))% complete").font(.farmCaption(12)).foregroundColor(.textMuted)
            }
        }
        .padding(.vertical, 6)
    }
}

struct IncubatorBatchDetailView: View {
    @EnvironmentObject var appState: AppState
    let batch: IncubatorBatch
    @State private var showEdit = false
    @State private var currentBatch: IncubatorBatch

    init(batch: IncubatorBatch) {
        self.batch = batch
        _currentBatch = State(initialValue: batch)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Status card
                VStack(spacing: 12) {
                    Text(currentBatch.birdType.icon).font(.system(size: 64))
                    Text(currentBatch.name).font(.farmTitle(20)).foregroundColor(.textPrimary)
                    Text("\(currentBatch.eggCount) \(currentBatch.birdType.rawValue) Eggs")
                        .font(.farmBody(15)).foregroundColor(.textSecondary)
                }
                .padding(.top, 8)

                // Progress
                VStack(spacing: 14) {
                    HStack {
                        Text("Hatching Progress").font(.farmHeadline(15)).foregroundColor(.textPrimary)
                        Spacer()
                        Text("\(Int(currentBatch.progress * 100))%").font(.farmHeadline(15)).foregroundColor(.infoBlue)
                    }
                    ProgressView(value: currentBatch.progress)
                        .tint(.infoBlue).scaleEffect(x: 1, y: 2, anchor: .center)
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Started").font(.farmCaption(11)).foregroundColor(.textMuted)
                            Text(currentBatch.startDate.formatted(date: .abbreviated, time: .omitted)).font(.farmBody(13)).foregroundColor(.textPrimary)
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("Expected Hatch").font(.farmCaption(11)).foregroundColor(.textMuted)
                            Text(currentBatch.expectedHatchDate.formatted(date: .abbreviated, time: .omitted)).font(.farmBody(13)).foregroundColor(.textPrimary)
                        }
                    }
                    Text("\(currentBatch.daysRemaining) day(s) remaining")
                        .font(.farmHeadline(16))
                        .foregroundColor(currentBatch.daysRemaining <= 3 ? .alertRed : .textPrimary)
                }
                .farmCard()
                .padding(.horizontal, 20)

                // Conditions
                VStack(spacing: 14) {
                    Text("Conditions").font(.farmHeadline(15)).foregroundColor(.textPrimary)
                    HStack(spacing: 20) {
                        conditionCard(icon: "thermometer.medium", label: "Temperature", value: "\(String(format: "%.1f", currentBatch.temperature))°C", color: .alertRed)
                        conditionCard(icon: "humidity.fill", label: "Humidity", value: "\(String(format: "%.0f", currentBatch.humidity))%", color: .infoBlue)
                    }
                }
                .farmCard()
                .padding(.horizontal, 20)

                // Turn today toggle
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath").foregroundColor(.farmGreen)
                        Text("Turned Today").font(.farmBody(15)).foregroundColor(.textPrimary)
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { currentBatch.turnedToday },
                            set: { val in
                                currentBatch.turnedToday = val
                                appState.updateIncubatorBatch(currentBatch)
                            }
                        ))
                        .tint(.farmGreen)
                    }
                }
                .farmCard()
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 24)
        }
        .background(Color.surfaceLight.ignoresSafeArea())
        .navigationTitle("Incubator Batch")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Edit") { showEdit = true }.foregroundColor(.farmGreen) } }
        .sheet(isPresented: $showEdit) { AddIncubatorBatchView(existing: currentBatch) }
        .onAppear { if let updated = appState.incubatorBatches.first(where: { $0.id == batch.id }) { currentBatch = updated } }
    }

    private func conditionCard(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.system(size: 22)).foregroundColor(color)
            Text(value).font(.farmHeadline(18)).foregroundColor(.textPrimary)
            Text(label).font(.farmCaption(12)).foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 14).fill(color.opacity(0.08)))
    }
}

struct AddIncubatorBatchView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    var existing: IncubatorBatch? = nil
    @State private var name = ""
    @State private var eggCountText = ""
    @State private var birdType: BirdType = .chicken
    @State private var startDate = Date()
    @State private var tempText = "37.5"
    @State private var humidityText = "55"
    @State private var notes = ""
    @State private var errorMsg = ""

    init(existing: IncubatorBatch? = nil) {
        self.existing = existing
        _name = State(initialValue: existing?.name ?? "")
        _eggCountText = State(initialValue: existing != nil ? "\(existing!.eggCount)" : "")
        _birdType = State(initialValue: existing?.birdType ?? .chicken)
        _startDate = State(initialValue: existing?.startDate ?? Date())
        _tempText = State(initialValue: existing != nil ? String(format: "%.1f", existing!.temperature) : "37.5")
        _humidityText = State(initialValue: existing != nil ? String(format: "%.0f", existing!.humidity) : "55")
        _notes = State(initialValue: existing?.notes ?? "")
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Batch Info") {
                    FarmTextField(placeholder: "Batch Name", text: $name, icon: "tag.fill")
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    Picker("Bird Type", selection: $birdType) {
                        ForEach(BirdType.allCases, id: \.self) { t in
                            HStack { Text(t.icon); Text(t.rawValue) }.tag(t)
                        }
                    }
                    FarmTextField(placeholder: "Number of Eggs", text: $eggCountText, icon: "oval.fill", keyboardType: .numberPad)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date).font(.farmBody(15))
                }
                Section("Conditions") {
                    FarmTextField(placeholder: "Temperature (°C)", text: $tempText, icon: "thermometer.medium", keyboardType: .decimalPad)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    FarmTextField(placeholder: "Humidity (%)", text: $humidityText, icon: "humidity.fill", keyboardType: .decimalPad)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
                Section("Notes") { TextEditor(text: $notes).frame(height: 60).font(.farmBody(15)) }
                if !errorMsg.isEmpty { Text(errorMsg).foregroundColor(.alertRed).font(.farmCaption(13)) }
            }
            .navigationTitle(existing == nil ? "Add Batch" : "Edit Batch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { errorMsg = "Name required"; return }
                        guard let count = Int(eggCountText), count > 0 else { errorMsg = "Valid egg count required"; return }
                        let temp = Double(tempText) ?? 37.5
                        let hum = Double(humidityText) ?? 55.0
                        if var e = existing {
                            e.name = name; e.eggCount = count; e.birdType = birdType; e.startDate = startDate
                            e.temperature = temp; e.humidity = hum; e.notes = notes
                            appState.updateIncubatorBatch(e)
                        } else {
                            appState.addIncubatorBatch(IncubatorBatch(name: name, eggCount: count, startDate: startDate, birdType: birdType, notes: notes, temperature: temp, humidity: hum))
                        }
                        dismiss()
                    }
                    .foregroundColor(.farmGreen).font(.farmHeadline(15))
                }
            }
        }
    }
}


extension WebCoordinator: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else { return decisionHandler(.allow) }
        lastURL = url
        let scheme = (url.scheme ?? "").lowercased()
        let path = url.absoluteString.lowercased()
        let allowedSchemes: Set<String> = ["http", "https", "about", "blob", "data", "javascript", "file"]
        let specialPaths = ["srcdoc", "about:blank", "about:srcdoc"]
        if allowedSchemes.contains(scheme) || specialPaths.contains(where: { path.hasPrefix($0) }) || path == "about:blank" {
            decisionHandler(.allow)
        } else {
            UIApplication.shared.open(url, options: [:])
            decisionHandler(.cancel)
        }
    }
    
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        redirectCount += 1
        if redirectCount > maxRedirects { webView.stopLoading(); if let recovery = lastURL { webView.load(URLRequest(url: recovery)) }; redirectCount = 0; return }
        lastURL = webView.url; saveCookies(from: webView)
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        if let current = webView.url { checkpoint = current; print("✅ [PoultryFarm] Commit: \(current.absoluteString)") }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let current = webView.url { checkpoint = current }; redirectCount = 0; saveCookies(from: webView)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        if (error as NSError).code == NSURLErrorHTTPTooManyRedirects, let recovery = lastURL { webView.load(URLRequest(url: recovery)) }
    }
    
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust, let trust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}
