import SwiftUI
import UserNotifications

class SettingsViewModel: ObservableObject {
    @AppStorage("app_theme") var theme: AppTheme = .system
    @AppStorage("use_metric") var useMetric: Bool = true
    @AppStorage("notifications_enabled") var notificationsEnabled: Bool = true
    @AppStorage("daily_reminder_enabled") var dailyReminderEnabled: Bool = false
    @AppStorage("daily_reminder_hour") var dailyReminderHour: Int = 8
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @AppStorage("currency_symbol") var currencySymbol: String = "$"

    func applyTheme(_ newTheme: AppTheme) {
        theme = newTheme
    }

    func toggleNotifications(_ enabled: Bool) {
        notificationsEnabled = enabled
        if enabled {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
                DispatchQueue.main.async {
                    self.notificationsEnabled = granted
                }
            }
        } else {
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        }
    }

    func setDailyReminder(enabled: Bool, hour: Int) {
        dailyReminderEnabled = enabled
        dailyReminderHour = hour
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily_reminder"])
        if enabled {
            let content = UNMutableNotificationContent()
            content.title = "🐔 Good Morning, Farmer!"
            content.body = "Time to check on your flock and collect eggs."
            content.sound = .default
            var components = DateComponents()
            components.hour = hour
            components.minute = 0
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(identifier: "daily_reminder", content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        }
    }
}

enum AppTheme: String, CaseIterable {
    case light = "Light"
    case dark = "Dark"
    case system = "System"

    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }

    var icon: String {
        switch self {
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .system: return "circle.lefthalf.filled"
        }
    }
}

@MainActor
final class PoultryFarmApplication: ObservableObject {
    
    @Published var showPermissionPrompt = false
    @Published var showOfflineView = false
    @Published var navigateToMain = false
    @Published var navigateToWeb = false
    
    private let businessLogic: BusinessLogicService
    private var timeoutTask: Task<Void, Never>?
    
    init(
        repository: AppDataRepository,
        validation: ValidationService,
        network: NetworkService,
        notification: NotificationService
    ) {
        self.businessLogic = BusinessLogicService(
            repository: repository,
            validation: validation,
            network: network,
            notification: notification
        )
    }
    
    // MARK: - Public API
    
    func initialize() {
        Task {
            do {
                _ = try await businessLogic.initialize()
            } catch {
                print("🐔 [PoultryFarm] Init error: \(error)")
            }
            
            scheduleTimeout()
        }
    }
    
    func handleTracking(_ data: [String: Any]) {
        Task {
            do {
                _ = try await businessLogic.handleTracking(data)
                
                // ✅ Auto-trigger validation
                await performValidation()
            } catch {
                print("🐔 [PoultryFarm] Tracking error: \(error)")
                navigateToMain = true
            }
        }
    }
    
    func handleNavigation(_ data: [String: Any]) {
        Task {
            do {
                try await businessLogic.handleNavigation(data)
            } catch {
                print("🐔 [PoultryFarm] Navigation error: \(error)")
            }
        }
    }
    
    func requestPermission() {
        Task {
            do {
                _ = try await businessLogic.requestPermission()
                showPermissionPrompt = false
                navigateToWeb = true
            } catch {
                print("🐔 [PoultryFarm] Permission error: \(error)")
                showPermissionPrompt = false
                navigateToWeb = true
            }
        }
    }
    
    func deferPermission() {
        Task {
            do {
                try await businessLogic.deferPermission()
                showPermissionPrompt = false
                navigateToWeb = true
            } catch {
                print("🐔 [PoultryFarm] Defer error: \(error)")
                showPermissionPrompt = false
                navigateToWeb = true
            }
        }
    }
    
    func networkStatusChanged(_ isConnected: Bool) {
        Task {
            showOfflineView = !isConnected
        }
    }
    
    func timeout() {
        Task {
            timeoutTask?.cancel()
            if !passed {
                navigateToMain = true
            }
        }
    }
    
    private var passed = false
    
    private func performValidation() async {
        if !passed {
            do {
                let isValid = try await businessLogic.performValidation()
                
                if isValid {
                    // ✅ Validation passed
                    await executeBusinessLogic()
                } else {
                    // ❌ Validation failed - сразу на Main!
                    timeoutTask?.cancel()
                    navigateToMain = true
                }
            } catch {
                print("🐔 [PoultryFarm] Validation error: \(error)")
                timeoutTask?.cancel()
                navigateToMain = true
            }
        }
    }
    
    private func executeBusinessLogic() async {
        do {
            guard let url = try await businessLogic.executeBusinessLogic() else {
                navigateToMain = true
                return
            }
            
            passed = true
            timeoutTask?.cancel()
            try await businessLogic.finalizeWithEndpoint(url)
            if businessLogic.canAskPermission() {
                showPermissionPrompt = true
            } else {
                navigateToWeb = true
            }
        } catch {
            print("🐔 [PoultryFarm] Business logic error: \(error)")
            navigateToMain = true
        }
    }
    
    private func scheduleTimeout() {
        timeoutTask = Task {
            try? await Task.sleep(nanoseconds: 30_000_000_000)
            await timeout()
        }
    }
}

