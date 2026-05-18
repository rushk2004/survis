import Foundation
import SwiftData
import Observation

/// View-model for managing reminder lists (create, update, delete, seed defaults).
@Observable
final class ListViewModel {

    // MARK: - State

    var showingAddList  = false
    var listToEdit: ReminderList? = nil
    var listToDelete: ReminderList? = nil
    var showingDeleteAlert = false

    // MARK: - Default List Seeding

    /// Inserts the built-in lists if no lists exist yet. Call once at app launch.
    func seedDefaultListsIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<ReminderList>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }

        for (index, item) in AppConstants.defaultLists.enumerated() {
            let list = ReminderList(
                name: item.name,
                colorName: item.color,
                iconName: item.icon,
                isDefault: true,
                sortOrder: index
            )
            context.insert(list)
        }
    }

    // MARK: - CRUD

    func addList(
        name: String,
        colorName: String,
        iconName: String,
        context: ModelContext
    ) {
        guard !name.isBlank else { return }
        let descriptor = FetchDescriptor<ReminderList>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        let list = ReminderList(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            colorName: colorName,
            iconName: iconName,
            isDefault: false,
            sortOrder: count
        )
        context.insert(list)
    }

    func updateList(_ list: ReminderList, name: String, colorName: String, iconName: String) {
        guard !name.isBlank else { return }
        list.name      = name.trimmingCharacters(in: .whitespacesAndNewlines)
        list.colorName = colorName
        list.iconName  = iconName
    }

    func deleteList(_ list: ReminderList, context: ModelContext) {
        // Cancel notifications for all reminders in this list before cascade-delete
        for reminder in list.reminders {
            NotificationManager.shared.cancelNotification(for: reminder)
        }
        context.delete(list)
    }

    func confirmDelete(_ list: ReminderList) {
        listToDelete   = list
        showingDeleteAlert = true
    }

    func executeConfirmedDelete(context: ModelContext) {
        if let list = listToDelete {
            deleteList(list, context: context)
            listToDelete = nil
        }
    }

    // MARK: - Sorting

    func sortedLists(_ lists: [ReminderList]) -> [ReminderList] {
        lists.sorted { $0.sortOrder < $1.sortOrder }
    }
}
