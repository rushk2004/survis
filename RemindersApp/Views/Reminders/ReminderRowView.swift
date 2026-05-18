import SwiftUI
import SwiftData

/// A single reminder row with checkbox, title, meta info, and swipe actions.
struct ReminderRowView: View {
    let reminder: Reminder
    let onToggleComplete: () -> Void
    let onDelete: () -> Void
    var onTap: (() -> Void)? = nil

    @State private var isPressed = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // MARK: Checkbox
            Button(action: onToggleComplete) {
                ZStack {
                    Circle()
                        .strokeBorder(checkboxColor, lineWidth: 1.5)
                        .frame(width: AppConstants.checkboxSize, height: AppConstants.checkboxSize)

                    if reminder.isCompleted {
                        Circle()
                            .fill(checkboxColor)
                            .frame(width: AppConstants.checkboxSize, height: AppConstants.checkboxSize)
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .buttonStyle(.plain)
            .animation(.smoothSpring, value: reminder.isCompleted)
            .padding(.top, 1)

            // MARK: Content
            VStack(alignment: .leading, spacing: 4) {
                // Title
                Text(reminder.title)
                    .font(.body)
                    .strikethrough(reminder.isCompleted, color: .secondary)
                    .foregroundStyle(reminder.isCompleted ? .secondary : .primary)
                    .lineLimit(2)

                // Meta row: date, priority, list
                HStack(spacing: 8) {
                    if let _ = reminder.dueDate {
                        Label {
                            Text(reminder.formattedDueDate)
                        } icon: {
                            Image(systemName: "calendar")
                        }
                        .font(.caption)
                        .foregroundStyle(dueDateColor)
                    }

                    PriorityIcon(priority: reminder.priority)

                    if let list = reminder.list {
                        HStack(spacing: 3) {
                            Circle()
                                .fill(list.color)
                                .frame(width: 6, height: 6)
                            Text(list.name)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Notes preview (first line only)
                if !reminder.notes.isEmpty && !reminder.isCompleted {
                    Text(reminder.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)

            // Repeat indicator
            if reminder.repeatInterval != .never {
                Image(systemName: "arrow.clockwise")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 4)
            }
        }
        .padding(.horizontal, AppConstants.rowPadding)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .onTapGesture { onTap?() }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button(action: onToggleComplete) {
                Label(
                    reminder.isCompleted ? "Undo" : "Complete",
                    systemImage: reminder.isCompleted ? "arrow.uturn.backward" : "checkmark.circle"
                )
            }
            .tint(reminder.isCompleted ? .gray : .green)
        }
    }

    // MARK: - Helpers

    private var checkboxColor: Color {
        reminder.list?.color ?? Color(named: reminder.priority.colorName).opacity(0.8)
    }

    private var dueDateColor: Color {
        if reminder.isCompleted { return .secondary }
        if reminder.isOverdue   { return .red }
        if reminder.isToday     { return .orange }
        return .secondary
    }
}
