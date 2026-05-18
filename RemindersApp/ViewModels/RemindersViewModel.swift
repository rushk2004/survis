import Foundation
import SwiftData
import SwiftUI
import Observation

/// Central view-model for reminder operations, filtering, and sorting.
/// Views fetch reminders via `@Query` and delegate mutations here.
@Observable
final class RemindersViewModel {

    // MARK: - Filter / Search State

    var searchText    = ""
    var selectedSort  = SortOption.dueDate
    var showCompleted = false
    var selectedFilter = FilterOption.all
    var selectedListFilter: ReminderList? = nil

    // MARK: - Sheet / Alert Presentation State

    var showingAddReminder    = false
    var showingAddList        = false
    var reminderToDelete: Reminder? = nil
    var showingDeleteAlert    = false

    // MARK: - Filtering

    /// Applies active filters and sort order to an array returned by @Query.
    func apply(
        filter: FilterOption,
        listFilter: ReminderList?,
        search: String,
        sort: SortOption,
        showCompleted: Bool,
        to reminders: [Reminder]
    ) -> [Reminder] {
        var result = reminders

        // Completed visibility
        if !showCompleted {
            result = result.filter { !$0.isCompleted }
        }

        // Filter preset
        switch filter {
        case .all:       break
        case .today:     result = result.filter { $0.isToday }
        case .upcoming:  result = result.filter { $0.isUpcoming }
        case .overdue:   result = result.filter { $0.isOverdue }
        case .completed: result = result.filter { $0.isCompleted }
        }

        // List filter
        if let list = listFilter {
            result = result.filter { $0.list?.id == list.id }
        }

        // Full-text search on title and notes
        if !search.trimmingCharacters(in: .whitespaces).isEmpty {
            let q = search.lowercased()
            result = result.filter {
                $0.title.lowercased().contains(q) ||
                $0.notes.lowercased().contains(q)
            }
        }

        // Sort
        switch sort {
        case .dueDate:
            result.sort {
                switch ($0.dueDate, $1.dueDate) {
                case let (a?, b?): return a < b
                case (nil, _?):   return false
                case (_?, nil):   return true
                default:          return $0.createdAt < $1.createdAt
                }
            }
        case .priority:
            result.sort { $0.priority > $1.priority }
        case .creationDate:
            result.sort { $0.createdAt > $1.createdAt }
        case .title:
            result.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        }

        return result
    }

    // MARK: - Home Screen Sections

    func todayReminders(from reminders: [Reminder]) -> [Reminder] {
        reminders.filter { $0.isToday && !$0.isCompleted }
            .sorted { lhs, rhs in
                switch (lhs.dueDate, rhs.dueDate) {
                case let (a?, b?): return a < b
                default: return lhs.createdAt < rhs.createdAt
                }
            }
    }

    func overdueReminders(from reminders: [Reminder]) -> [Reminder] {
        reminders.filter { $0.isOverdue && !$0.isToday }
            .sorted { lhs, rhs in
                switch (lhs.dueDate, rhs.dueDate) {
                case let (a?, b?): return a < b
                default: return lhs.createdAt < rhs.createdAt
                }
            }
    }

    func upcomingReminders(from reminders: [Reminder]) -> [Reminder] {
        reminders.filter { $0.isUpcoming && !$0.isCompleted }
            .sorted { lhs, rhs in
                switch (lhs.dueDate, rhs.dueDate) {
                case let (a?, b?): return a < b
                default: return lhs.createdAt < rhs.createdAt
                }
            }
    }

    func completedReminders(from reminders: [Reminder]) -> [Reminder] {
        reminders.filter { $0.isCompleted }
            .sorted { ($0.completedAt ?? $0.updatedAt) > ($1.completedAt ?? $1.updatedAt) }
    }

    func noDueDateReminders(from reminders: [Reminder]) -> [Reminder] {
        reminders.filter { $0.dueDate == nil && !$0.isCompleted }
            .sorted { $0.createdAt < $1.createdAt }
    }

    // MARK: - CRUD Operations

    func addReminder(
        title: String,
        notes: String,
        dueDate: Date?,
        hasTime: Bool,
        priority: Priority,
        repeatInterval: RepeatInterval,
        list: ReminderList?,
        context: ModelContext
    ) {
        guard !title.isBlank else { return }
        let reminder = Reminder(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            notes: notes,
            dueDate: dueDate,
            hasTime: hasTime,
            priority: priority,
            repeatInterval: repeatInterval,
            list: list
        )
        context.insert(reminder)
        NotificationManager.shared.scheduleNotification(for: reminder)
    }

    func toggleComplete(_ reminder: Reminder, context: ModelContext) {
        withAnimation(.smoothSpring) {
            reminder.isCompleted.toggle()
            reminder.completedAt = reminder.isCompleted ? Date() : nil
            reminder.updatedAt   = Date()
        }

        if reminder.isCompleted {
            NotificationManager.shared.cancelNotification(for: reminder)

            // Schedule a new reminder for the next occurrence if repeat is active
            if reminder.repeatInterval != .never, let due = reminder.dueDate {
                if let nextDue = NotificationManager.shared.nextDueDate(
                    after: due, interval: reminder.repeatInterval
                ) {
                    let next = Reminder(
                        title: reminder.title,
                        notes: reminder.notes,
                        dueDate: nextDue,
                        hasTime: reminder.hasTime,
                        priority: reminder.priority,
                        repeatInterval: reminder.repeatInterval,
                        list: reminder.list
                    )
                    context.insert(next)
                    NotificationManager.shared.scheduleNotification(for: next)
                }
            }
        } else {
            NotificationManager.shared.scheduleNotification(for: reminder)
        }
    }

    func updateReminder(_ reminder: Reminder, context: ModelContext) {
        reminder.updatedAt = Date()
        NotificationManager.shared.cancelNotification(for: reminder)
        NotificationManager.shared.scheduleNotification(for: reminder)
    }

    func deleteReminder(_ reminder: Reminder, context: ModelContext) {
        NotificationManager.shared.cancelNotification(for: reminder)
        context.delete(reminder)
    }

    func confirmDelete(_ reminder: Reminder) {
        reminderToDelete = reminder
        showingDeleteAlert = true
    }

    func executeConfirmedDelete(context: ModelContext) {
        if let reminder = reminderToDelete {
            deleteReminder(reminder, context: context)
            reminderToDelete = nil
        }
    }
}
