import SwiftUI

/// A compact badge showing the priority level with icon and color.
struct PriorityBadge: View {
    let priority: Priority

    var body: some View {
        if priority != .none {
            HStack(spacing: 3) {
                Image(systemName: priority.systemImage)
                Text(priority.label)
                    .font(.caption2.weight(.medium))
            }
            .font(.caption2)
            .foregroundStyle(badgeColor)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(badgeColor.opacity(0.12), in: Capsule())
        }
    }

    private var badgeColor: Color { Color(named: priority.colorName) }
}

/// Just the icon — used inline in reminder rows.
struct PriorityIcon: View {
    let priority: Priority

    var body: some View {
        if priority != .none {
            Image(systemName: priority.systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color(named: priority.colorName))
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        PriorityBadge(priority: .high)
        PriorityBadge(priority: .medium)
        PriorityBadge(priority: .low)
        PriorityBadge(priority: .none)
    }
    .padding()
}
