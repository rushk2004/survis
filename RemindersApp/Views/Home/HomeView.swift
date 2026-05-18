import SwiftUI
import SwiftData

/// The main "Today" home screen showing overdue, today, and upcoming sections.
struct HomeView: View {
    @Environment(\.modelContext) private var context

    @Query private var allReminders: [Reminder]

    var viewModel: RemindersViewModel

    @State private var selectedReminder: Reminder?   = nil
    @State private var showingAddReminder             = false
    @State private var showCompleted                  = false

    // MARK: - Computed Sections

    private var overdueReminders:   [Reminder] { viewModel.overdueReminders(from: allReminders) }
    private var todayReminders:     [Reminder] { viewModel.todayReminders(from: allReminders) }
    private var upcomingReminders:  [Reminder] { viewModel.upcomingReminders(from: allReminders) }
    private var noDueDateReminders: [Reminder] { viewModel.noDueDateReminders(from: allReminders) }
    private var completedReminders: [Reminder] { viewModel.completedReminders(from: allReminders) }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: AppConstants.sectionSpacing) {

                    // MARK: Summary Cards
                    summaryCards

                    // MARK: Overdue
                    if !overdueReminders.isEmpty {
                        reminderSection(
                            title: "Overdue",
                            systemImage: "exclamationmark.triangle.fill",
                            color: .red,
                            reminders: overdueReminders
                        )
                    }

                    // MARK: Today
                    reminderSection(
                        title: "Today",
                        systemImage: "sun.max.fill",
                        color: .orange,
                        reminders: todayReminders,
                        emptyMessage: "No reminders due today."
                    )

                    // MARK: Upcoming
                    if !upcomingReminders.isEmpty {
                        reminderSection(
                            title: "Upcoming",
                            systemImage: "calendar",
                            color: .blue,
                            reminders: upcomingReminders
                        )
                    }

                    // MARK: No Date
                    if !noDueDateReminders.isEmpty {
                        reminderSection(
                            title: "No Date",
                            systemImage: "tray.full",
                            color: .secondary,
                            reminders: noDueDateReminders
                        )
                    }

                    // MARK: Completed Toggle
                    if !completedReminders.isEmpty {
                        completedSection
                    }

                    Spacer(minLength: 60)
                }
                .padding(.vertical, 16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Reminders")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddReminder = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingAddReminder) {
                AddReminderView(viewModel: viewModel)
            }
            .navigationDestination(item: $selectedReminder) { reminder in
                ReminderDetailView(viewModel: viewModel, reminder: reminder)
            }
            .confirmationDialog(
                "Delete Reminder",
                isPresented: $viewModel.showingDeleteAlert,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    viewModel.executeConfirmedDelete(context: context)
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This reminder will be permanently deleted.")
            }
        }
    }

    // MARK: - Summary Cards

    private var summaryCards: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                SummaryCard(
                    title: "Overdue",
                    count: overdueReminders.count,
                    icon: "exclamationmark.triangle.fill",
                    color: .red
                )
                SummaryCard(
                    title: "Today",
                    count: todayReminders.count,
                    icon: "sun.max.fill",
                    color: .orange
                )
                SummaryCard(
                    title: "Upcoming",
                    count: upcomingReminders.count,
                    icon: "calendar",
                    color: .blue
                )
                SummaryCard(
                    title: "Completed",
                    count: completedReminders.count,
                    icon: "checkmark.circle.fill",
                    color: .green
                )
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Reminder Section Builder

    @ViewBuilder
    private func reminderSection(
        title: String,
        systemImage: String,
        color: Color,
        reminders: [Reminder],
        emptyMessage: String? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Section header
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .foregroundStyle(color)
                    .font(.subheadline.weight(.semibold))
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(color)
                Spacer()
                Text("\(reminders.count)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)

            if reminders.isEmpty, let msg = emptyMessage {
                Text(msg)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
            } else {
                // Reminder rows
                VStack(spacing: 0) {
                    ForEach(reminders) { reminder in
                        ReminderRowView(
                            reminder: reminder,
                            onToggleComplete: { viewModel.toggleComplete(reminder, context: context) },
                            onDelete: { viewModel.confirmDelete(reminder) },
                            onTap: { selectedReminder = reminder }
                        )
                        if reminder.id != reminders.last?.id {
                            Divider().padding(.leading, 50)
                        }
                    }
                }
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: AppConstants.cornerRadius))
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Completed Section

    private var completedSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.smoothSpring) { showCompleted.toggle() }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.subheadline.weight(.semibold))
                    Text("Completed")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.green)
                    Spacer()
                    Text("\(completedReminders.count)")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    Image(systemName: showCompleted ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
            }
            .buttonStyle(.plain)

            if showCompleted {
                VStack(spacing: 0) {
                    ForEach(completedReminders.prefix(15)) { reminder in
                        ReminderRowView(
                            reminder: reminder,
                            onToggleComplete: { viewModel.toggleComplete(reminder, context: context) },
                            onDelete: { viewModel.confirmDelete(reminder) },
                            onTap: { selectedReminder = reminder }
                        )
                        if reminder.id != completedReminders.prefix(15).last?.id {
                            Divider().padding(.leading, 50)
                        }
                    }
                }
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: AppConstants.cornerRadius))
                .padding(.horizontal, 16)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
}

// MARK: - Summary Card

private struct SummaryCard: View {
    let title: String
    let count: Int
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                Spacer()
            }
            Text("\(count)")
                .font(.system(size: 28, weight: .bold, design: .rounded))
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(width: 120)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.cornerRadius))
    }
}
