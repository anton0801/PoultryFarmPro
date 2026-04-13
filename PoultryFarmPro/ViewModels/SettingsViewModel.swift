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
