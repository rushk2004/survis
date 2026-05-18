import SwiftUI

/// App-wide constants to keep magic values in one place.
enum AppConstants {

    // MARK: - Layout
    static let cornerRadius: CGFloat     = 12
    static let rowCornerRadius: CGFloat  = 10
    static let listIconSize: CGFloat     = 34
    static let checkboxSize: CGFloat     = 22
    static let rowPadding: CGFloat       = 14
    static let sectionSpacing: CGFloat   = 20

    // MARK: - Default Lists
    /// Seed data for the four built-in lists created on first launch.
    static let defaultLists: [(name: String, color: String, icon: String)] = [
        ("Personal",  "blue",   "person.fill"),
        ("Work",      "orange", "briefcase.fill"),
        ("Shopping",  "green",  "cart.fill"),
        ("Study",     "purple", "book.fill"),
    ]

    // MARK: - Notification
    static let defaultNotificationHour   = 9
    static let defaultNotificationMinute = 0
}
