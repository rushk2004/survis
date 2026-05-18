import SwiftUI
import SwiftData

/// Full-featured search and filter screen.
struct SearchView: View {
    @Environment(\.modelContext) private var context

    @Query private var allReminders: [Reminder]
    @Query(sort: \ReminderList.sortOrder) private var lists: [ReminderList]

    var viewModel: RemindersViewModel

    @State private var searchText      = ""
    @State private var selectedFilter  = FilterOption.all
    @State private var selectedList: ReminderList? = nil
    @State private var selectedPriority: Priority?  = nil
    @State private var selectedSort    = SortOption.dueDate
    @State private var selectedReminder: Reminder? = nil
    @State private var showingFilters  = false

    private var filteredReminders: [Reminder] {
        var result = viewModel.apply(
            filter: selectedFilter,
            listFilter: selectedList,
            search: searchText,
            sort: selectedSort,
            showCompleted: selectedFilter == .completed,
            to: allReminders
        )
        if let priority = selectedPriority {
            result = result.filter { $0.priority == priority }
        }
        return result
    }

    private var isFiltering: Bool {
        selectedFilter != .all || selectedList != nil || selectedPriority != nil
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: Filter Chips
                filterChipsRow

                // MARK: Results List
                if filteredReminders.isEmpty {
                    if searchText.isEmpty && !isFiltering {
                        EmptyStateView(
                            systemImage: "magnifyingglass",
                            title: "Search Reminders",
                            subtitle: "Search by title, notes, or use the filters above."
                        )
                    } else {
                        EmptyStateView.noResults()
                    }
                } else {
                    List {
                        Section {
                            Text("\(filteredReminders.count) reminder\(filteredReminders.count == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                        }

                        ForEach(filteredReminders) { reminder in
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
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Reminders, notes…")
            .toolbar {
                ToolbarItem(placement: .secondaryAction) {
                    Menu {
                        // Sort options
                        Section("Sort By") {
                            ForEach(SortOption.allCases) { option in
                                Button {
                                    selectedSort = option
                                } label: {
                                    Label(option.rawValue, systemImage: option.systemImage)
                                    if selectedSort == option {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                        if isFiltering {
                            Divider()
                            Button(role: .destructive) { clearFilters() } label: {
                                Label("Clear Filters", systemImage: "xmark.circle")
                            }
                        }
                    } label: {
                        Image(systemName: isFiltering
                              ? "line.3.horizontal.decrease.circle.fill"
                              : "line.3.horizontal.decrease.circle")
                    }
                }
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

    // MARK: - Filter Chips

    private var filterChipsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Status filter
                ForEach(FilterOption.allCases) { filter in
                    FilterChip(
                        label: filter.rawValue,
                        systemImage: filter.systemImage,
                        isSelected: selectedFilter == filter
                    ) {
                        withAnimation(.smoothSpring) { selectedFilter = filter }
                    }
                }

                Divider()
                    .frame(height: 20)
                    .padding(.horizontal, 2)

                // Priority filter
                ForEach(Priority.allCases.filter { $0 != .none }, id: \.self) { p in
                    FilterChip(
                        label: p.label,
                        systemImage: p.systemImage,
                        isSelected: selectedPriority == p,
                        color: Color(named: p.colorName)
                    ) {
                        withAnimation(.smoothSpring) {
                            selectedPriority = selectedPriority == p ? nil : p
                        }
                    }
                }

                if !lists.isEmpty {
                    Divider()
                        .frame(height: 20)
                        .padding(.horizontal, 2)

                    // List filter
                    ForEach(lists) { list in
                        FilterChip(
                            label: list.name,
                            systemImage: list.iconName,
                            isSelected: selectedList?.id == list.id,
                            color: list.color
                        ) {
                            withAnimation(.smoothSpring) {
                                selectedList = selectedList?.id == list.id ? nil : list
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(Color(.systemBackground))
        Divider()
    }

    private func clearFilters() {
        withAnimation(.smoothSpring) {
            selectedFilter   = .all
            selectedList     = nil
            selectedPriority = nil
        }
    }
}

// MARK: - Filter Chip

private struct FilterChip: View {
    let label: String
    let systemImage: String
    let isSelected: Bool
    var color: Color = .accentColor
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.caption.weight(.medium))
                Text(label)
                    .font(.caption.weight(.medium))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .foregroundStyle(isSelected ? .white : .primary)
            .background(
                isSelected
                    ? color
                    : Color(.tertiarySystemFill),
                in: Capsule()
            )
        }
        .buttonStyle(.plain)
    }
}
