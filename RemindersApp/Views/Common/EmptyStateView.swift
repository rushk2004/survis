import SwiftUI

/// Full-screen or inline empty-state placeholder with icon, title, and subtitle.
struct EmptyStateView: View {
    let systemImage: String
    let title: String
    let subtitle: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 52, weight: .thin))
                .foregroundStyle(.secondary)
                .symbolRenderingMode(.hierarchical)

            VStack(spacing: 6) {
                Text(title)
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.accentColor)
                }
                .padding(.top, 4)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preset configurations

extension EmptyStateView {
    static func noReminders(action: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            systemImage: "checkmark.circle",
            title: "No Reminders",
            subtitle: "Tap + to create your first reminder.",
            actionTitle: "New Reminder",
            action: action
        )
    }

    static func noResults() -> EmptyStateView {
        EmptyStateView(
            systemImage: "magnifyingglass",
            title: "No Results",
            subtitle: "Try a different search term or filter."
        )
    }

    static func allDone() -> EmptyStateView {
        EmptyStateView(
            systemImage: "checkmark.seal.fill",
            title: "All Done!",
            subtitle: "You have no pending reminders here."
        )
    }
}

#Preview {
    EmptyStateView.noReminders {}
}
