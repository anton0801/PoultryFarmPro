import Foundation
import AppsFlyerLib

// MARK: - AppData Repository

final class AppDataRepository: Repository {
    typealias Entity = AppData
    
    private let storage: StorageService
    
    init(storage: StorageService) {
        self.storage = storage
    }
    
    func save(_ entity: AppData) async throws {
        storage.saveTracking(entity.tracking)
        storage.saveNavigation(entity.navigation)
        if let endpoint = entity.endpoint {
            storage.saveEndpoint(endpoint)
        }
        if let mode = entity.mode {
            storage.saveMode(mode)
        }
        storage.savePermissions(entity.permission)
        if !entity.isFirstLaunch {
            storage.markLaunched()
        }
    }
    
    func fetch() async throws -> AppData? {
        let stored = storage.loadState()
        
        return AppData(
            tracking: stored.tracking,
            navigation: stored.navigation,
            endpoint: stored.endpoint,
            mode: stored.mode,
            isFirstLaunch: stored.isFirstLaunch,
            permission: AppData.PermissionData(
                isGranted: stored.permission.isGranted,
                isDenied: stored.permission.isDenied,
                lastAsked: stored.permission.lastAsked
            ),
            metadata: [:]
        )
    }
    
    func delete() async throws {
        // Not implemented for now
    }
    
    func exists() async -> Bool {
        let stored = storage.loadState()
        return !stored.tracking.isEmpty
    }
}

// MARK: - Business Logic Service

final class BusinessLogicService {
    private let repository: AppDataRepository
    private let validation: ValidationService
    private let network: NetworkService
    private let notification: NotificationService
    
    private var data: AppData = .initial
    
    init(
        repository: AppDataRepository,
        validation: ValidationService,
        network: NetworkService,
        notification: NotificationService
    ) {
        self.repository = repository
        self.validation = validation
        self.network = network
        self.notification = notification
    }
    
    // MARK: - Initialize
    
    func initialize() async throws -> AppData {
        if let stored = try await repository.fetch() {
            data = stored
            // ❌ НЕ ЗАГРУЖАЕМ endpoint!
            data.endpoint = nil
        }
        return data
    }
    
    // MARK: - Handle Tracking
    
    func handleTracking(_ trackingData: [String: Any]) async throws -> AppData {
        let converted = trackingData.mapValues { "\($0)" }
        data.tracking = converted
        try await repository.save(data)
        return data
    }
    
    func handleNavigation(_ navigationData: [String: Any]) async throws {
        let converted = navigationData.mapValues { "\($0)" }
        data.navigation = converted
        try await repository.save(data)
    }
    
    // MARK: - Validation
    
    func performValidation() async throws -> Bool {
        guard data.hasTracking() else {
            return false
        }
        
        do {
            let isValid = try await validation.validate()
            return isValid
        } catch {
            print("🐔 [PoultryFarm] Validation error: \(error)")
            return false
        }
    }
    
    // MARK: - Business Logic
    
    func executeBusinessLogic() async throws -> String? {
        // Check temp_url
        if let temp = UserDefaults.standard.string(forKey: "temp_url"), !temp.isEmpty {
            return temp
        }
        
        // Check organic + first launch
        let attributionProcessed = data.metadata["attribution_processed"] == "true"
        if data.isOrganic() && data.isFirstLaunch && !attributionProcessed {
            data.metadata["attribution_processed"] = "true"
            try await executeOrganicFlow()
        }
        
        // Fetch endpoint
        return try await fetchEndpoint()
    }
    
    private func executeOrganicFlow() async throws {
        try? await Task.sleep(nanoseconds: 5_000_000_000)
        
        let deviceID = AppsFlyerLib.shared().getAppsFlyerUID()
        
        var fetched = try await network.fetchAttribution(deviceID: deviceID)
        
        for (key, value) in data.navigation {
            if fetched[key] == nil {
                fetched[key] = value
            }
        }
        
        let converted = fetched.mapValues { "\($0)" }
        data.tracking = converted
        try await repository.save(data)
    }
    
    private func fetchEndpoint() async throws -> String {
        let trackingDict = data.tracking.mapValues { $0 as Any }
        let url = try await network.fetchEndpoint(tracking: trackingDict)
        return url
    }
    
    func finalizeWithEndpoint(_ url: String) async throws {
        data.endpoint = url
        data.mode = "Active"
        data.isFirstLaunch = false
        
        try await repository.save(data)
    }
    
    // MARK: - Permission
    
    func requestPermission() async throws -> AppData.PermissionData {
        // ✅ Локальная копия для избежания inout capture
        var localPermission = data.permission
        
        let updatedPermission = await withCheckedContinuation {
            (continuation: CheckedContinuation<AppData.PermissionData, Never>) in
            
            notification.requestPermission { granted in
                var permission = localPermission
                
                if granted {
                    permission.isGranted = true
                    permission.isDenied = false
                    permission.lastAsked = Date()
                    self.notification.registerForPush()
                } else {
                    permission.isGranted = false
                    permission.isDenied = true
                    permission.lastAsked = Date()
                }
                
                continuation.resume(returning: permission)
            }
        }
        
        data.permission = updatedPermission
        try await repository.save(data)
        return updatedPermission
    }
    
    func deferPermission() async throws {
        data.permission.lastAsked = Date()
        try await repository.save(data)
    }
    
    func canAskPermission() -> Bool {
        data.permission.canAsk
    }
}
