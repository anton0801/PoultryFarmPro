import SwiftUI
import Combine
import UserNotifications

// MARK: - App State (Central Store)
class AppState: ObservableObject {

    // MARK: - Auth
    @Published var isLoggedIn: Bool = false
    @Published var currentUser: UserProfile? = nil

    // MARK: - Data
    @Published var birdGroups: [BirdGroup] = []
    @Published var coops: [Coop] = []
    @Published var eggRecords: [EggRecord] = []
    @Published var feedRecords: [FeedRecord] = []
    @Published var storageItems: [StorageItem] = []
    @Published var breedingPairs: [BreedingPair] = []
    @Published var incubatorBatches: [IncubatorBatch] = []
    @Published var healthRecords: [HealthRecord] = []
    @Published var tasks: [FarmTask] = []
    @Published var feedCrops: [FeedCrop] = []
    @Published var costRecords: [CostRecord] = []
    @Published var activities: [ActivityItem] = []

    // MARK: - UserDefaults Keys
    private let userKey = "pfp_user"
    private let isLoggedInKey = "pfp_isLoggedIn"
    private let birdGroupsKey = "pfp_birdGroups"
    private let coopsKey = "pfp_coops"
    private let eggRecordsKey = "pfp_eggRecords"
    private let feedRecordsKey = "pfp_feedRecords"
    private let storageKey = "pfp_storage"
    private let breedingKey = "pfp_breeding"
    private let incubatorKey = "pfp_incubator"
    private let healthKey = "pfp_health"
    private let tasksKey = "pfp_tasks"
    private let cropsKey = "pfp_crops"
    private let costsKey = "pfp_costs"
    private let activitiesKey = "pfp_activities"

    init() {
        loadAll()
    }

    // MARK: - Load
    func loadAll() {
        isLoggedIn = UserDefaults.standard.bool(forKey: isLoggedInKey)
        if let data = UserDefaults.standard.data(forKey: userKey),
           let user = try? JSONDecoder().decode(UserProfile.self, from: data) {
            currentUser = user
        }
        birdGroups = load(key: birdGroupsKey) ?? []
        coops = load(key: coopsKey) ?? []
        eggRecords = load(key: eggRecordsKey) ?? []
        feedRecords = load(key: feedRecordsKey) ?? []
        storageItems = load(key: storageKey) ?? defaultStorage()
        breedingPairs = load(key: breedingKey) ?? []
        incubatorBatches = load(key: incubatorKey) ?? []
        healthRecords = load(key: healthKey) ?? []
        tasks = load(key: tasksKey) ?? []
        feedCrops = load(key: cropsKey) ?? []
        costRecords = load(key: costsKey) ?? []
        activities = load(key: activitiesKey) ?? []
    }

    private func load<T: Decodable>(key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    private func save<T: Encodable>(_ value: T, key: String) {
        if let data = try? JSONEncoder().encode(value) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func defaultStorage() -> [StorageItem] {
        return [
            StorageItem(feedType: .corn, quantityKg: 50, reorderLevelKg: 10),
            StorageItem(feedType: .wheat, quantityKg: 30, reorderLevelKg: 8),
            StorageItem(feedType: .feedMix, quantityKg: 20, reorderLevelKg: 5),
            StorageItem(feedType: .pellets, quantityKg: 40, reorderLevelKg: 10)
        ]
    }

    // MARK: - Auth
    func login(email: String, password: String) -> Bool {
        if let data = UserDefaults.standard.data(forKey: userKey),
           let user = try? JSONDecoder().decode(UserProfile.self, from: data) {
            if user.email.lowercased() == email.lowercased() {
                currentUser = user
                isLoggedIn = true
                UserDefaults.standard.set(true, forKey: isLoggedInKey)
                return true
            }
        }
        return false
    }

    func register(name: String, email: String, password: String, farmName: String) {
        let user = UserProfile(name: name, email: email, farmName: farmName)
        currentUser = user
        isLoggedIn = true
        save(user, key: userKey)
        UserDefaults.standard.set(true, forKey: isLoggedInKey)
    }

    func logout() {
        isLoggedIn = false
        currentUser = nil
        UserDefaults.standard.set(false, forKey: isLoggedInKey)
    }

    func deleteAccount() {
        logout()
        let keys = [userKey, birdGroupsKey, coopsKey, eggRecordsKey, feedRecordsKey,
                    storageKey, breedingKey, incubatorKey, healthKey, tasksKey,
                    cropsKey, costsKey, activitiesKey]
        keys.forEach { UserDefaults.standard.removeObject(forKey: $0) }
        birdGroups = []; coops = []; eggRecords = []; feedRecords = []
        storageItems = defaultStorage(); breedingPairs = []; incubatorBatches = []
        healthRecords = []; tasks = []; feedCrops = []; costRecords = []; activities = []
    }

    func updateProfile(name: String, farmName: String) {
        guard var user = currentUser else { return }
        user.name = name
        user.farmName = farmName
        currentUser = user
        save(user, key: userKey)
    }

    // MARK: - Bird Groups
    func addBirdGroup(_ group: BirdGroup) {
        birdGroups.append(group)
        save(birdGroups, key: birdGroupsKey)
        addActivity(.birdAdded, description: "Added \(group.count) \(group.birdType.rawValue)(s) — \(group.name)")
    }

    func updateBirdGroup(_ group: BirdGroup) {
        if let idx = birdGroups.firstIndex(where: { $0.id == group.id }) {
            birdGroups[idx] = group
            save(birdGroups, key: birdGroupsKey)
        }
    }

    func deleteBirdGroup(_ group: BirdGroup) {
        birdGroups.removeAll { $0.id == group.id }
        save(birdGroups, key: birdGroupsKey)
    }

    // MARK: - Coops
    func addCoop(_ coop: Coop) {
        coops.append(coop)
        save(coops, key: coopsKey)
    }

    func updateCoop(_ coop: Coop) {
        if let idx = coops.firstIndex(where: { $0.id == coop.id }) {
            coops[idx] = coop
            save(coops, key: coopsKey)
        }
    }

    func deleteCoop(_ coop: Coop) {
        coops.removeAll { $0.id == coop.id }
        save(coops, key: coopsKey)
    }

    // MARK: - Egg Records
    func addEggRecord(_ record: EggRecord) {
        eggRecords.append(record)
        save(eggRecords, key: eggRecordsKey)
        addActivity(.eggCollected, description: "Collected \(record.count) eggs from \(record.birdGroupName)")
    }

    func deleteEggRecord(_ record: EggRecord) {
        eggRecords.removeAll { $0.id == record.id }
        save(eggRecords, key: eggRecordsKey)
    }

    // MARK: - Feed Records
    func addFeedRecord(_ record: FeedRecord) {
        feedRecords.append(record)
        save(feedRecords, key: feedRecordsメKey)
        // Deduct from storage
        if let idx = storageItems.firstIndex(where: { $0.feedType == record.feedType }) {
            storageItems[idx].quantityKg = max(0, storageItems[idx].quantityKg - record.amountKg)
            save(storageItems, key: storageKey)
        }
        addActivity(.feedRecorded, description: "Fed \(record.amountKg)kg \(record.feedType.rawValue) to \(record.birdGroupName)")
    }

    func deleteFeedRecord(_ record: FeedRecord) {
        feedRecords.removeAll { $0.id == record.id }
        save(feedRecords, key: feedRecordsKey)
    }

    private var feedRecordsメKey: String { feedRecordsKey }

    // MARK: - Storage
    func updateStorage(_ item: StorageItem) {
        if let idx = storageItems.firstIndex(where: { $0.id == item.id }) {
            storageItems[idx] = item
        } else {
            storageItems.append(item)
        }
        save(storageItems, key: storageKey)
    }

    func addToStorage(feedType: FeedType, amountKg: Double) {
        if let idx = storageItems.firstIndex(where: { $0.feedType == feedType }) {
            storageItems[idx].quantityKg += amountKg
            storageItems[idx].lastUpdated = Date()
        } else {
            storageItems.append(StorageItem(feedType: feedType, quantityKg: amountKg, reorderLevelKg: 5))
        }
        save(storageItems, key: storageKey)
    }

    // MARK: - Breeding
    func addBreedingPair(_ pair: BreedingPair) {
        breedingPairs.append(pair)
        save(breedingPairs, key: breedingKey)
        addActivity(.incubatorUpdated, description: "New breeding pair: \(pair.maleName) x \(pair.femaleName)")
    }

    func updateBreedingPair(_ pair: BreedingPair) {
        if let idx = breedingPairs.firstIndex(where: { $0.id == pair.id }) {
            breedingPairs[idx] = pair
            save(breedingPairs, key: breedingKey)
        }
    }

    func deleteBreedingPair(_ pair: BreedingPair) {
        breedingPairs.removeAll { $0.id == pair.id }
        save(breedingPairs, key: breedingKey)
    }

    // MARK: - Incubator
    func addIncubatorBatch(_ batch: IncubatorBatch) {
        incubatorBatches.append(batch)
        save(incubatorBatches, key: incubatorKey)
        addActivity(.incubatorUpdated, description: "Incubator batch started: \(batch.eggCount) \(batch.birdType.rawValue) eggs")
        scheduleIncubatorNotification(for: batch)
    }

    func updateIncubatorBatch(_ batch: IncubatorBatch) {
        if let idx = incubatorBatches.firstIndex(where: { $0.id == batch.id }) {
            incubatorBatches[idx] = batch
            save(incubatorBatches, key: incubatorKey)
        }
    }

    func deleteIncubatorBatch(_ batch: IncubatorBatch) {
        incubatorBatches.removeAll { $0.id == batch.id }
        save(incubatorBatches, key: incubatorKey)
    }

    // MARK: - Health
    func addHealthRecord(_ record: HealthRecord) {
        healthRecords.append(record)
        save(healthRecords, key: healthKey)
        addActivity(.healthRecorded, description: "Health issue logged for \(record.birdGroupName): \(record.issue)")
    }

    func updateHealthRecord(_ record: HealthRecord) {
        if let idx = healthRecords.firstIndex(where: { $0.id == record.id }) {
            healthRecords[idx] = record
            save(healthRecords, key: healthKey)
        }
    }

    func deleteHealthRecord(_ record: HealthRecord) {
        healthRecords.removeAll { $0.id == record.id }
        save(healthRecords, key: healthKey)
    }

    // MARK: - Tasks
    func addTask(_ task: FarmTask) {
        tasks.append(task)
        save(tasks, key: tasksKey)
        if task.recurring != .none {
            scheduleTaskNotification(for: task)
        }
    }

    func toggleTask(_ task: FarmTask) {
        if let idx = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[idx].completed.toggle()
            save(tasks, key: tasksKey)
            if tasks[idx].completed {
                addActivity(.taskCompleted, description: "Completed: \(task.title)")
            }
        }
    }

    func deleteTask(_ task: FarmTask) {
        tasks.removeAll { $0.id == task.id }
        save(tasks, key: tasksKey)
    }

    // MARK: - Feed Crops
    func addFeedCrop(_ crop: FeedCrop) {
        feedCrops.append(crop)
        save(feedCrops, key: cropsKey)
        addActivity(.cropUpdated, description: "New crop planted: \(crop.name)")
    }

    func updateFeedCrop(_ crop: FeedCrop) {
        if let idx = feedCrops.firstIndex(where: { $0.id == crop.id }) {
            feedCrops[idx] = crop
            save(feedCrops, key: cropsKey)
        }
    }

    func harvestCrop(_ crop: FeedCrop, yieldKg: Double) {
        if let idx = feedCrops.firstIndex(where: { $0.id == crop.id }) {
            feedCrops[idx].status = .harvested
            feedCrops[idx].actualYieldKg = yieldKg
            save(feedCrops, key: cropsKey)
            // Add to storage
            let feedType = feedTypeForCrop(crop.cropType)
            addToStorage(feedType: feedType, amountKg: yieldKg)
            addActivity(.cropUpdated, description: "Harvested \(yieldKg)kg of \(crop.name)")
        }
    }

    func deleteFeedCrop(_ crop: FeedCrop) {
        feedCrops.removeAll { $0.id == crop.id }
        save(feedCrops, key: cropsKey)
    }

    private func feedTypeForCrop(_ cropType: CropType) -> FeedType {
        switch cropType {
        case .corn: return .corn
        case .wheat: return .wheat
        case .barley: return .barley
        case .soybeans: return .soybeans
        default: return .feedMix
        }
    }

    // MARK: - Costs
    func addCostRecord(_ record: CostRecord) {
        costRecords.append(record)
        save(costRecords, key: costsKey)
        addActivity(.costAdded, description: "Cost recorded: $\(String(format: "%.2f", record.amount)) - \(record.description)")
    }

    func deleteCostRecord(_ record: CostRecord) {
        costRecords.removeAll { $0.id == record.id }
        save(costRecords, key: costsKey)
    }

    // MARK: - Activities
    func addActivity(_ type: ActivityType, description: String) {
        let activity = ActivityItem(type: type, description: description)
        activities.insert(activity, at: 0)
        if activities.count > 100 { activities = Array(activities.prefix(100)) }
        save(activities, key: activitiesKey)
    }

    // MARK: - Computed Dashboad Stats
    var totalBirdCount: Int {
        birdGroups.reduce(0) { $0 + $1.count }
    }

    var todayEggCount: Int {
        let today = Calendar.current.startOfDay(for: Date())
        return eggRecords
            .filter { Calendar.current.startOfDay(for: $0.date) == today }
            .reduce(0) { $0 + $1.count }
    }

    var weekEggCount: Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return eggRecords
            .filter { $0.date >= weekAgo }
            .reduce(0) { $0 + $1.count }
    }

    var totalFeedStorageKg: Double {
        storageItems.reduce(0) { $0 + $1.quantityKg }
    }

    var activeBreedingCount: Int {
        breedingPairs.filter { $0.status == .active || $0.status == .incubating }.count
    }

    var openHealthIssues: Int {
        healthRecords.filter { !$0.resolved }.count
    }

    var pendingTasks: Int {
        tasks.filter { !$0.completed }.count
    }

    // MARK: - Notifications
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
    }

    private func scheduleIncubatorNotification(for batch: IncubatorBatch) {
        let content = UNMutableNotificationContent()
        content.title = "🐣 Hatch Day!"
        content.body = "\(batch.eggCount) \(batch.birdType.rawValue) eggs in '\(batch.name)' are due to hatch today!"
        content.sound = .default

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute],
                                                          from: batch.expectedHatchDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: "hatch_\(batch.id)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }

    private func scheduleTaskNotification(for task: FarmTask) {
        let content = UNMutableNotificationContent()
        content.title = "🐔 Farm Task Reminder"
        content.body = task.title
        content.sound = .default

        var components = Calendar.current.dateComponents([.hour, .minute], from: task.dueDate)
        components.hour = components.hour ?? 8

        var trigger: UNNotificationTrigger
        switch task.recurring {
        case .daily:
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        case .weekly:
            components.weekday = Calendar.current.component(.weekday, from: task.dueDate)
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        default:
            let dc = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: task.dueDate)
            trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: false)
        }

        let request = UNNotificationRequest(identifier: "task_\(task.id)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }

    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
