import SwiftUI
import SwiftData

/// Tab showing all reminder lists and their pending counts.
struct ListsView: View {
    @Environment(\.modelContext) private var context

    @Query(sort: \ReminderList.sortOrder) private var lists: [ReminderList]
    @Query private var allReminders: [Reminder]

    var viewModel: RemindersViewModel
    @State var listViewModel = ListViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if lists.isEmpty {
                    EmptyStateView(
                        systemImage: "list.bullet.clipboard",
                        title: "No Lists",
                        subtitle: "Create a list to organize your reminders.",
                        actionTitle: "New List",
                        action: { listViewModel.showingAddList = true }
                    )
                } else {
                    listContent
                }
            }
            .navigationTitle("My Lists")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        listViewModel.showingAddList = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $listViewModel.showingAddList) {
                AddListView(listViewModel: listViewModel)
            }
            .confirmationDialog(
                "Delete \"\(listViewModel.listToDelete?.name ?? "List")\"?",
                isPresented: $listViewModel.showingDeleteAlert,
                titleVisibility: .visible
            ) {
                Button("Delete List", role: .destructive) {
                    listViewModel.executeConfirmedDelete(context: context)
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("All reminders in this list will also be deleted.")
            }
        }
    }

    // MARK: - List Content

    private var listContent: some View {
        List {
            ForEach(lists) { list in
                NavigationLink {
                    ListDetailView(
                        viewModel: viewModel,
                        listViewModel: listViewModel,
                        list: list
                    )
                } label: {
                    ListRowView(list: list)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    if !list.isDefault {
                        Button(role: .destructive) {
                            listViewModel.confirmDelete(list)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    Button {
                        listViewModel.listToEdit = list
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    .tint(.blue)
                }
            }
        }
        .listStyle(.insetGrouped)
        .sheet(item: $listViewModel.listToEdit) { list in
            AddListView(listViewModel: listViewModel, editingList: list)
        }
    }
}

// MARK: - List Row

private struct ListRowView: View {
    let list: ReminderList

    var body: some View {
        HStack(spacing: 14) {
            // Icon circle
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(list.color)
                    .frame(width: AppConstants.listIconSize, height: AppConstants.listIconSize)
                Image(systemName: list.iconName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(list.name)
                    .font(.body)
                Text("\(list.reminders.filter { !$0.isCompleted }.count) remaining")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if list.pendingCount > 0 {
                Text("\(list.pendingCount)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
