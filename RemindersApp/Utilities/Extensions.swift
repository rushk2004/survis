import SwiftUI
import Foundation

// MARK: - Color Extensions

extension Color {
    /// Initialize from a `ListColor`-style name string.
    init(named name: String) {
        switch name {
        case "red":    self = .red
        case "green":  self = .green
        case "orange": self = .orange
        case "purple": self = .purple
        case "pink":   self = .pink
        case "yellow": self = .yellow
        case "teal":   self = .teal
        case "indigo": self = .indigo
        case "brown":  self = .brown
        default:       self = .blue
        }
    }

    /// A lighter variant of this color, useful for backgrounds.
    var lighter: Color { opacity(0.15) }
}

// MARK: - Date Extensions

extension Date {
    /// Returns true if the date is within the next 7 days (exclusive of today).
    var isThisWeek: Bool {
        let cal = Calendar.current
        guard let weekFromNow = cal.date(byAdding: .day, value: 7, to: Date()) else { return false }
        return self > Date() && self <= weekFromNow
    }

    /// Short relative string like "Today", "Tomorrow", or "3 days ago".
    var relativeString: String {
        let cal = Calendar.current
        if cal.isDateInToday(self)     { return "Today" }
        if cal.isDateInTomorrow(self)  { return "Tomorrow" }
        if cal.isDateInYesterday(self) { return "Yesterday" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }

    /// Start of the calendar day for this date.
    var startOfDay: Date { Calendar.current.startOfDay(for: self) }

    /// End of the calendar day for this date (23:59:59).
    var endOfDay: Date {
        var comps = DateComponents()
        comps.day = 1
        comps.second = -1
        return Calendar.current.date(byAdding: comps, to: startOfDay)!
    }
}

// MARK: - String Extensions

extension String {
    var isBlank: Bool { trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
}

// MARK: - View Extensions

extension View {
    /// Applies a card-style background with rounded corners and shadow.
    func cardStyle(cornerRadius: CGFloat = 12) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
    }

    /// Conditionally applies a view modifier.
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition { transform(self) } else { self }
    }

    /// Shows a badge overlay on the top-trailing corner.
    func badge(_ count: Int) -> some View {
        overlay(alignment: .topTrailing) {
            if count > 0 {
                Text("\(count)")
                    .font(.caption2.bold())
                    .foregroundStyle(.white)
                    .padding(4)
                    .background(Color.red, in: Circle())
                    .offset(x: 6, y: -6)
            }
        }
    }
}

// MARK: - Animation Helpers

extension Animation {
    static var smoothSpring: Animation {
        .spring(response: 0.4, dampingFraction: 0.75)
    }
}
