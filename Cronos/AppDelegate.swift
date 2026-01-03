import Foundation
import AppKit
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    weak var jobManager: JobManager?

    func applicationDidFinishLaunching(_ notification: Notification) {
        UNUserNotificationCenter.current().delegate = self
    }

    // Handle notification clicks
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        if let jobIdString = userInfo["jobId"] as? String,
           let jobId = UUID(uuidString: jobIdString) {
            Task { @MainActor in
                // Find the job and open log history
                if let job = jobManager?.jobs.first(where: { $0.id == jobId }) {
                    jobManager?.selectedJobForHistory = job
                    NSApp.activate(ignoringOtherApps: true)

                    // Open the log-history window
                    if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "log-history" }) {
                        window.makeKeyAndOrderFront(nil)
                    } else {
                        NSApp.sendAction(Selector(("openWindow:")), to: nil, from: "log-history")
                    }
                }
            }
        }

        completionHandler()
    }

    // Show notifications even when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
