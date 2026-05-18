import SwiftUI
import SwiftData

/// Displays all reminders belonging to a specific list.
struct ListDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss)      private var dismiss

    @Query private var allReminders: [Reminder]

    var viewModel: RemindersViewModel
    var listViewModel: ListViewModel
    let list: ReminderList

    @State private var selectedReminder: Reminder? = nil
    @State private var showingAddReminder           = false
    @State private var sortOption                   = SortOption.dueDate
    @State private var showCompleted                = false
    @State private var showingEditList              = false

    private var pendingReminders: [Reminder] {
        viewModel.apply(
            filter: .all,
            listFilter: list,
            search: "",
            sort: sortOption,
            showCompleted: false,
            to: allReminders
        )
    }

    private var completedReminders: [Reminder] {
        allReminders
            .filter { $0.list?.id == list.id && $0.isCompleted }
            .sorted { ($0.completedAt ?? $0.updatedAt) > ($1.completedAt ?? $1.updatedAt) }
    }

    var body: some View {
        Group {
            if pendingReminders.isEmpty && completedReminders.isEmpty {
                EmptyStateView.noReminders { showingAddReminder = true }
            } else {
                List {
                    // MARK: Pending
                    if !pendingReminders.isEmpty {
                        Section {
                            ForEach(pendingReminders) { reminder in
                                ReminderRowView(
                                    reminder: reminder,
                                    onToggleComplete: { viewModel.toggleComplete(reminder, context: context) },
                                    onDelete: { viewModel.confirmDelete(reminder) },
                                    onTap: { selectedReminder = reminder }
                                )
                                .listRowInsets(EdgeInsets())
                                .listRowSeparator(.hidden)
                            }
                        }
                    }

                    // MARK: Completed
                    if !completedReminders.isEmpty {
                        Section {
                            DisclosureGroup(
                                isExpanded: $showCompleted,
                                content: {
                                    ForEach(completedReminders.prefix(20)) { reminder in
                                        ReminderRowView(
                                            reminder: reminder,
                                            onToggleComplete: { viewModel.toggleComplete(reminder, context: context) },
                                            onDelete: { viewModel.confirmDelete(reminder) },
                                            onTap: { selectedReminder = reminder }
                                        )
                                        .listRowInsets(EdgeInsets())
                                        .listRowSeparator(.hidden)
                                    }
                                },
                                label: {
                                    Label("Completed (\(completedReminders.count))", systemImage: "checkmark.circle.fill")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(.secondary)
                                }
                            )
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle(list.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddReminder = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(list.color)
                }
            }
            ToolbarItem(placement: .secondaryAction) {
                Menu {
                    // Sort options
                    Menu("Sort By") {
                        ForEach(SortOption.allCases) { option in
                            Button {
                                sortOption = option
                            } label: {
                                Label(option.rawValue, systemImage: option.systemImage)
                                if sortOption == option {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                    Divider()
                    Button {
                        showingEditList = true
                    } label: {
                        Label("Edit List", systemImage: "pencil")
                    }
                    if !list.isDefault {
                        Button(role: .destructive) {
                            listViewModel.confirmDelete(list)
                        } label: {
                            Label("Delete List", systemImage: "trash")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingAddReminder) {
            AddReminderView(viewModel: viewModel, preselectedList: list)
        }
        .sheet(isPresented: $showingEditList) {
            AddListView(listViewModel: listViewModel, editingList: list)
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
        .confirmationDialog(
            "Delete \"\(list.name)\"?",
            isPresented: $listViewModel.showingDeleteAlert,
            titleVisibility: .visible
        ) {
            Button("Delete List", role: .destructive) {
                listViewModel.executeConfirmedDelete(context: context)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("All reminders in this list will also be deleted.")
        }
    }
}
