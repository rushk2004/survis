import UIKit
import UserNotifications
import SwiftData

/// Handles app lifecycle events and UNUserNotificationCenter delegate callbacks.
final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// Display notifications even when the app is in the foreground.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }

    /// Handle taps on notifications and notification actions.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let notificationID = response.notification.request.identifier

        if response.actionIdentifier == "COMPLETE_ACTION" {
            // Mark reminder as complete via the shared model container context.
            // The actual toggle is lightweight enough to perform here.
            Task { @MainActor in
                do {
                    let schema = Schema([Reminder.self, ReminderList.self])
                    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
                    let container = try ModelContainer(for: schema, configurations: [config])
                    let context   = container.mainContext

                    let descriptor = FetchDescriptor<Reminder>(
                        predicate: #Predicate { $0.notificationID == notificationID }
                    )
                    if let reminder = try context.fetch(descriptor).first {
                        reminder.isCompleted = true
                        reminder.completedAt = Date()
                        NotificationManager.shared.cancelNotification(for: reminder)
                    }
                } catch {
                    print("[AppDelegate] Failed to complete reminder from notification: \(error)")
                }
            }
        }
        completionHandler()
    }

    // MARK: - Badge Reset

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Reset badge count when user opens the app
        UNUserNotificationCenter.current().setBadgeCount(0) { _ in }
    }
}
