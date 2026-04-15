import Foundation
import SwiftUI
import UserNotifications


protocol NotificationService {
    func requestPermission(completion: @escaping (Bool) -> Void)
    func registerForPush()
}

final class SystemNotificationService: NotificationService {
    func requestPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, _ in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    func registerForPush() {
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
}
