import Foundation
import UserNotifications

actor NotificationService {
    static let shared = NotificationService()

    private init() {}

    /// Request permission to send notifications
    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound])
            return granted
        } catch {
            print("Failed to request notification permission: \(error)")
            return false
        }
    }

    /// Send a notification when a job fails
    func sendJobFailedNotification(jobName: String) async {
        let content = UNMutableNotificationContent()
        content.title = "Job Failed"
        content.body = "Job '\(jobName)' failed"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // Deliver immediately
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("Failed to send notification: \(error)")
        }
    }

    /// Send a notification when a job succeeds
    func sendJobSucceededNotification(jobName: String) async {
        let content = UNMutableNotificationContent()
        content.title = "Job Succeeded"
        content.body = "Job '\(jobName)' completed successfully"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // Deliver immediately
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("Failed to send notification: \(error)")
        }
    }
}
