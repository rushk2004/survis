import SwiftUI
import SwiftData

/// Sheet for creating a new reminder. On save, delegates to the view-model.
struct AddReminderView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss)      private var dismiss

    @Query(sort: \ReminderList.sortOrder) private var lists: [ReminderList]

    var viewModel: RemindersViewModel
    /// Pre-select a list when opened from a list detail view.
    var preselectedList: ReminderList? = nil

    // MARK: - Form State

    @State private var title          = ""
    @State private var notes          = ""
    @State private var hasDueDate     = false
    @State private var dueDate        = Date()
    @State private var hasTime        = false
    @State private var priority       = Priority.none
    @State private var repeatInterval = RepeatInterval.never
    @State private var selectedList: ReminderList? = nil
    @FocusState private var titleFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Title & Notes
                Section {
                    TextField("Title", text: $title, axis: .vertical)
                        .font(.body.weight(.medium))
                        .focused($titleFocused)
                        .submitLabel(.next)

                    TextField("Notes", text: $notes, axis: .vertical)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(3...8)
                }

                // MARK: Date & Time
                Section {
                    Toggle("Due Date", isOn: $hasDueDate.animation(.smoothSpring))
                    if hasDueDate {
                        DatePicker(
                            "Date",
                            selection: $dueDate,
                            displayedComponents: hasTime ? [.date, .hourAndMinute] : .date
                        )
                        .datePickerStyle(.graphical)

                        Toggle("Include Time", isOn: $hasTime.animation())
                    }
                }

                // MARK: Priority & Repeat
                Section {
                    Picker("Priority", selection: $priority) {
                        ForEach(Priority.allCases, id: \.self) { p in
                            Label(p.label, systemImage: p.systemImage)
                                .tag(p)
                        }
                    }

                    Picker("Repeat", selection: $repeatInterval) {
                        ForEach(RepeatInterval.allCases, id: \.self) { r in
                            Text(r.rawValue).tag(r)
                        }
                    }
                }

                // MARK: List Assignment
                if !lists.isEmpty {
                    Section("List") {
                        Picker("List", selection: $selectedList) {
                            Text("None").tag(Optional<ReminderList>.none)
                            ForEach(lists) { list in
                                Label {
                                    Text(list.name)
                                } icon: {
                                    Image(systemName: list.iconName)
                                        .foregroundStyle(list.color)
                                }
                                .tag(Optional(list))
                            }
                        }
                        .pickerStyle(.navigationLink)
                    }
                }
            }
            .navigationTitle("New Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { save() }
                        .fontWeight(.semibold)
                        .disabled(title.isBlank)
                }
            }
            .onAppear {
                selectedList = preselectedList
                titleFocused = true
            }
        }
    }

    // MARK: - Actions

    private func save() {
        viewModel.addReminder(
            title:          title,
            notes:          notes,
            dueDate:        hasDueDate ? dueDate : nil,
            hasTime:        hasTime,
            priority:       priority,
            repeatInterval: repeatInterval,
            list:           selectedList,
            context:        context
        )
        dismiss()
    }
}
