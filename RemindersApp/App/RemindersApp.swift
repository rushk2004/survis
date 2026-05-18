import SwiftUI
import SwiftData
import UserNotifications

@main
struct RemindersApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    /// Shared model container for the app.
    let container: ModelContainer

    init() {
        do {
            let schema = Schema([Reminder.self, ReminderList.self])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
                .onAppear {
                    NotificationManager.shared.requestAuthorization()
                    NotificationManager.shared.registerNotificationCategories()
                }
        }
    }
}
