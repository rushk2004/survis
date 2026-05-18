import Foundation
import UserNotifications
import SwiftUI

/// Manages scheduling and cancellation of local reminder notifications.
@MainActor
final class NotificationManager: ObservableObject {

    static let shared = NotificationManager()

    /// Whether the user has granted notification permission.
    @Published private(set) var isAuthorized = false

    private init() {}

    // MARK: - Authorization

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { [weak self] granted, error in
            Task { @MainActor in
                self?.isAuthorized = granted
                if let error {
                    print("[NotificationManager] Authorization error: \(error.localizedDescription)")
                }
            }
        }
    }

    func checkAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }

    // MARK: - Scheduling

    /// Schedules (or replaces) a notification for the given reminder.
    /// Does nothing if the reminder has no due date or is already completed.
    func scheduleNotification(for reminder: Reminder) {
        guard let dueDate = reminder.dueDate, !reminder.isCompleted else { return }

        let center = UNUserNotificationCenter.current()
        // Cancel any existing notification for this reminder first
        center.removePendingNotificationRequests(withIdentifiers: [reminder.notificationID])

        let content = UNMutableNotificationContent()
        content.title = reminder.title
        content.sound = .default
        content.badge = 1

        if !reminder.notes.isEmpty {
            content.body = reminder.notes
        } else if let listName = reminder.list?.name {
            content.body = listName
        } else {
            content.body = "Reminder"
        }

        // Add category info for potential action buttons
        content.categoryIdentifier = "REMINDER"

        // Build date components for the trigger
        var components: Set<Calendar.Component> = [.year, .month, .day]
        if reminder.hasTime {
            components.formUnion([.hour, .minute])
        } else {
            // Fire at 9 AM on date-only reminders
            components.formUnion([.hour, .minute])
            var cal = Calendar.current
            var dateComponents = cal.dateComponents(components, from: dueDate)
            dateComponents.hour   = 9
            dateComponents.minute = 0
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: dateComponents, repeats: false
            )
            let request = UNNotificationRequest(
                identifier: reminder.notificationID, content: content, trigger: trigger
            )
            center.add(request) { error in
                if let error { print("[NotificationManager] Schedule error: \(error)") }
            }
            return
        }

        let dateComponents = Calendar.current.dateComponents(components, from: dueDate)
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents, repeats: false
        )
        let request = UNNotificationRequest(
            identifier: reminder.notificationID, content: content, trigger: trigger
        )
        center.add(request) { error in
            if let error { print("[NotificationManager] Schedule error: \(error)") }
        }
    }

    /// Cancels the pending notification for a reminder.
    func cancelNotification(for reminder: Reminder) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [reminder.notificationID]
        )
    }

    /// Cancels all pending notifications.
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    // MARK: - Repeat Support

    /// After a repeating reminder is completed, schedules the next occurrence
    /// and returns the updated due date, or nil if the interval is .never.
    func nextDueDate(after date: Date, interval: RepeatInterval) -> Date? {
        guard let (component, value) = interval.nextOccurrence else { return nil }
        return Calendar.current.date(byAdding: component, value: value, to: date)
    }

    // MARK: - Notification Category Registration

    /// Registers a "Mark Complete" action category. Call once at app launch.
    func registerNotificationCategories() {
        let completeAction = UNNotificationAction(
            identifier: "COMPLETE_ACTION",
            title: "Mark Complete",
            options: [.foreground]
        )
        let category = UNNotificationCategory(
            identifier: "REMINDER",
            actions: [completeAction],
            intentIdentifiers: [],
            options: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
}
