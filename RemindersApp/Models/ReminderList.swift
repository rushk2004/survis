import Foundation
import SwiftData
import SwiftUI

// MARK: - List Color Options

/// Palette of colors the user can pick for a custom list.
enum ListColor: String, CaseIterable, Identifiable {
    case blue   = "blue"
    case red    = "red"
    case green  = "green"
    case orange = "orange"
    case purple = "purple"
    case pink   = "pink"
    case yellow = "yellow"
    case teal   = "teal"
    case indigo = "indigo"
    case brown  = "brown"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .blue:   return .blue
        case .red:    return .red
        case .green:  return .green
        case .orange: return .orange
        case .purple: return .purple
        case .pink:   return .pink
        case .yellow: return .yellow
        case .teal:   return .teal
        case .indigo: return .indigo
        case .brown:  return .brown
        }
    }

    var label: String { rawValue.capitalized }
}

// MARK: - List Icon Options

/// SF Symbol names available as list icons.
enum ListIcon: String, CaseIterable, Identifiable {
    case list        = "list.bullet"
    case home        = "house.fill"
    case work        = "briefcase.fill"
    case shopping    = "cart.fill"
    case study       = "book.fill"
    case health      = "heart.fill"
    case finance     = "dollarsign.circle.fill"
    case travel      = "airplane"
    case gym         = "figure.walk"
    case star        = "star.fill"
    case flag        = "flag.fill"
    case bell        = "bell.fill"
    case gift        = "gift.fill"
    case music       = "music.note"
    case photo       = "photo.fill"

    var id: String { rawValue }
}

// MARK: - ReminderList Model

/// A named collection of reminders, analogous to Apple Reminders "Lists".
@Model
final class ReminderList {

    var id: UUID
    var name: String
    /// Raw string matching a `ListColor` case.
    var colorName: String
    /// SF Symbol name for the list icon.
    var iconName: String
    var createdAt: Date
    /// Default lists (Inbox, Personal, Work, Shopping, Study) cannot be deleted.
    var isDefault: Bool
    /// Controls ordering in the sidebar.
    var sortOrder: Int

    @Relationship(deleteRule: .cascade)
    var reminders: [Reminder] = []

    // MARK: Computed helpers

    var color: Color {
        ListColor(rawValue: colorName)?.color ?? .blue
    }

    /// Number of incomplete reminders — shown as a badge.
    var pendingCount: Int {
        reminders.filter { !$0.isCompleted }.count
    }

    // MARK: Init

    init(
        name: String,
        colorName: String = "blue",
        iconName: String = "list.bullet",
        isDefault: Bool = false,
        sortOrder: Int = 0
    ) {
        self.id        = UUID()
        self.name      = name
        self.colorName = colorName
        self.iconName  = iconName
        self.createdAt = Date()
        self.isDefault = isDefault
        self.sortOrder = sortOrder
    }
}
