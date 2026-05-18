import Foundation
import SwiftData

// MARK: - Enums

/// Priority level assigned to a reminder.
enum Priority: Int, Codable, CaseIterable, Comparable {
    case none = 0
    case low = 1
    case medium = 2
    case high = 3

    var label: String {
        switch self {
        case .none:   return "None"
        case .low:    return "Low"
        case .medium: return "Medium"
        case .high:   return "High"
        }
    }

    var systemImage: String {
        switch self {
        case .none:   return "minus.circle"
        case .low:    return "arrow.down.circle.fill"
        case .medium: return "exclamationmark.circle.fill"
        case .high:   return "exclamationmark.2"
        }
    }

    /// A human-readable color name used by the UI layer.
    var colorName: String {
        switch self {
        case .none:   return "gray"
        case .low:    return "blue"
        case .medium: return "orange"
        case .high:   return "red"
        }
    }

    static func < (lhs: Priority, rhs: Priority) -> Bool { lhs.rawValue < rhs.rawValue }
}

/// How often a reminder repeats after completion.
enum RepeatInterval: String, Codable, CaseIterable {
    case never     = "Never"
    case daily     = "Daily"
    case weekly    = "Weekly"
    case biweekly  = "Bi-Weekly"
    case monthly   = "Monthly"
    case yearly    = "Yearly"

    /// Returns the calendar component and value to add for the next occurrence.
    var nextOccurrence: (component: Calendar.Component, value: Int)? {
        switch self {
        case .never:    return nil
        case .daily:    return (.day, 1)
        case .weekly:   return (.weekOfYear, 1)
        case .biweekly: return (.weekOfYear, 2)
        case .monthly:  return (.month, 1)
        case .yearly:   return (.year, 1)
        }
    }
}

/// Available sort orders for reminder lists.
enum SortOption: String, CaseIterable, Identifiable {
    case dueDate      = "Due Date"
    case priority     = "Priority"
    case creationDate = "Creation Date"
    case title        = "Title"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .dueDate:      return "calendar"
        case .priority:     return "exclamationmark.triangle"
        case .creationDate: return "clock"
        case .title:        return "textformat.abc"
        }
    }
}

/// Filter presets shown in the home screen and search bar.
enum FilterOption: String, CaseIterable, Identifiable {
    case all       = "All"
    case today     = "Today"
    case upcoming  = "Upcoming"
    case overdue   = "Overdue"
    case completed = "Completed"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .all:       return "tray.full"
        case .today:     return "sun.max"
        case .upcoming:  return "calendar.badge.clock"
        case .overdue:   return "exclamationmark.triangle"
        case .completed: return "checkmark.circle"
        }
    }
}

// MARK: - Reminder Model

/// Core SwiftData model representing a single reminder.
@Model
final class Reminder {

    // MARK: Stored properties
    var id: UUID
    var title: String
    var notes: String
    var dueDate: Date?
    /// Whether the due date includes a specific time component.
    var hasTime: Bool
    /// Stored as raw Int to avoid SwiftData enum encoding edge cases.
    var priorityRaw: Int
    var isCompleted: Bool
    var completedAt: Date?
    /// Stored as raw String for the same reason as priorityRaw.
    var repeatIntervalRaw: String
    var createdAt: Date
    var updatedAt: Date
    /// Stable identifier used to cancel/update the scheduled UNNotification.
    var notificationID: String

    /// The list this reminder belongs to (nil = uncategorized / Inbox).
    var list: ReminderList?

    // MARK: Computed wrappers for enums

    var priority: Priority {
        get { Priority(rawValue: priorityRaw) ?? .none }
        set { priorityRaw = newValue.rawValue; updatedAt = Date() }
    }

    var repeatInterval: RepeatInterval {
        get { RepeatInterval(rawValue: repeatIntervalRaw) ?? .never }
        set { repeatIntervalRaw = newValue.rawValue; updatedAt = Date() }
    }

    // MARK: Computed date helpers

    var isOverdue: Bool {
        guard let due = dueDate, !isCompleted else { return false }
        let now = Date()
        if hasTime { return due < now }
        // Date-only: overdue if the day has already passed
        return Calendar.current.startOfDay(for: due) < Calendar.current.startOfDay(for: now)
    }

    var isToday: Bool {
        guard let due = dueDate else { return false }
        return Calendar.current.isDateInToday(due)
    }

    /// True when the due date is strictly in the future (tomorrow or later).
    var isUpcoming: Bool {
        guard let due = dueDate, !isCompleted else { return false }
        let startOfTomorrow = Calendar.current.startOfDay(
            for: Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        )
        return Calendar.current.startOfDay(for: due) >= startOfTomorrow
    }

    /// Human-readable due date string relative to today.
    var formattedDueDate: String {
        guard let due = dueDate else { return "" }
        let timeStr = due.formatted(.dateTime.hour().minute())
        if Calendar.current.isDateInToday(due) {
            return hasTime ? "Today at \(timeStr)" : "Today"
        } else if Calendar.current.isDateInYesterday(due) {
            return hasTime ? "Yesterday at \(timeStr)" : "Yesterday"
        } else if Calendar.current.isDateInTomorrow(due) {
            return hasTime ? "Tomorrow at \(timeStr)" : "Tomorrow"
        } else {
            let dateStr = due.formatted(.dateTime.month(.abbreviated).day().year())
            return hasTime ? "\(dateStr) at \(timeStr)" : dateStr
        }
    }

    // MARK: Init

    init(
        title: String,
        notes: String = "",
        dueDate: Date? = nil,
        hasTime: Bool = false,
        priority: Priority = .none,
        repeatInterval: RepeatInterval = .never,
        list: ReminderList? = nil
    ) {
        self.id               = UUID()
        self.title            = title
        self.notes            = notes
        self.dueDate          = dueDate
        self.hasTime          = hasTime
        self.priorityRaw      = priority.rawValue
        self.isCompleted      = false
        self.repeatIntervalRaw = repeatInterval.rawValue
        self.createdAt        = Date()
        self.updatedAt        = Date()
        self.notificationID   = UUID().uuidString
        self.list             = list
    }
}
