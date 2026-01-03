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
    func sendJobFailedNotification(jobId: UUID, jobName: String, output: String?) async {
        let content = UNMutableNotificationContent()
        content.title = "Job Failed"

        if let output = output, !output.isEmpty {
            let preview = truncateOutput(output, maxLength: 100)
            content.body = "Job '\(jobName)' failed\n\(preview)"
        } else {
            content.body = "Job '\(jobName)' failed"
        }

        content.sound = .default
        content.userInfo = ["jobId": jobId.uuidString]

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
    func sendJobSucceededNotification(jobId: UUID, jobName: String, output: String?) async {
        let content = UNMutableNotificationContent()
        content.title = "Job Succeeded"

        if let output = output, !output.isEmpty {
            let preview = truncateOutput(output, maxLength: 100)
            content.body = "Job '\(jobName)'\n\(preview)"
        } else {
            content.body = "Job '\(jobName)' completed successfully"
        }

        content.sound = .default
        content.userInfo = ["jobId": jobId.uuidString]

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

    /// Truncate output to a reasonable preview length
    private func truncateOutput(_ output: String, maxLength: Int) -> String {
        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
        // Get last lines (most relevant for output)
        let lines = trimmed.components(separatedBy: .newlines)
        let lastLines = lines.suffix(3).joined(separator: "\n")

        if lastLines.count <= maxLength {
            return lastLines
        }
        return String(lastLines.suffix(maxLength - 1)) + "…"
    }
}
