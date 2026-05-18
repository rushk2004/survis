import SwiftUI
import SwiftData

/// Full-screen edit view for an existing reminder.
struct ReminderDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss)      private var dismiss

    @Query(sort: \ReminderList.sortOrder) private var lists: [ReminderList]

    var viewModel: RemindersViewModel
    let reminder: Reminder

    // MARK: - Editable State (mirrors Reminder fields)

    @State private var title          = ""
    @State private var notes          = ""
    @State private var hasDueDate     = false
    @State private var dueDate        = Date()
    @State private var hasTime        = false
    @State private var priority       = Priority.none
    @State private var repeatInterval = RepeatInterval.never
    @State private var selectedList: ReminderList? = nil

    @State private var hasChanges     = false
    @State private var showDiscardAlert = false

    var body: some View {
        Form {
            // MARK: Title & Notes
            Section {
                TextField("Title", text: $title, axis: .vertical)
                    .font(.body.weight(.medium))
                    .onChange(of: title) { hasChanges = true }

                TextField("Notes", text: $notes, axis: .vertical)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(3...12)
                    .onChange(of: notes) { hasChanges = true }
            }

            // MARK: Date & Time
            Section {
                Toggle("Due Date", isOn: $hasDueDate.animation(.smoothSpring))
                    .onChange(of: hasDueDate) { hasChanges = true }

                if hasDueDate {
                    DatePicker(
                        "Date",
                        selection: $dueDate,
                        displayedComponents: hasTime ? [.date, .hourAndMinute] : .date
                    )
                    .datePickerStyle(.graphical)
                    .onChange(of: dueDate) { hasChanges = true }

                    Toggle("Include Time", isOn: $hasTime.animation())
                        .onChange(of: hasTime) { hasChanges = true }
                }
            }

            // MARK: Priority & Repeat
            Section {
                Picker("Priority", selection: $priority) {
                    ForEach(Priority.allCases, id: \.self) { p in
                        Label(p.label, systemImage: p.systemImage).tag(p)
                    }
                }
                .onChange(of: priority) { hasChanges = true }

                Picker("Repeat", selection: $repeatInterval) {
                    ForEach(RepeatInterval.allCases, id: \.self) { r in
                        Text(r.rawValue).tag(r)
                    }
                }
                .onChange(of: repeatInterval) { hasChanges = true }
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
                    .onChange(of: selectedList) { hasChanges = true }
                }
            }

            // MARK: Meta Info
            Section {
                LabeledContent("Created") {
                    Text(reminder.createdAt.formatted(.dateTime.month().day().year().hour().minute()))
                        .foregroundStyle(.secondary)
                }
                if let completedAt = reminder.completedAt {
                    LabeledContent("Completed") {
                        Text(completedAt.formatted(.dateTime.month().day().year().hour().minute()))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .font(.caption)

            // MARK: Delete
            Section {
                Button(role: .destructive) {
                    viewModel.confirmDelete(reminder)
                } label: {
                    Label("Delete Reminder", systemImage: "trash")
                }
            }
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save(); dismiss() }
                    .fontWeight(.semibold)
                    .disabled(!hasChanges || title.isBlank)
            }
        }
        .confirmationDialog("Delete Reminder", isPresented: $viewModel.showingDeleteAlert, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                viewModel.executeConfirmedDelete(context: context)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This reminder will be permanently deleted.")
        }
        .onAppear(perform: loadState)
    }

    // MARK: - Helpers

    private func loadState() {
        title          = reminder.title
        notes          = reminder.notes
        hasDueDate     = reminder.dueDate != nil
        dueDate        = reminder.dueDate ?? Date()
        hasTime        = reminder.hasTime
        priority       = reminder.priority
        repeatInterval = reminder.repeatInterval
        selectedList   = reminder.list
    }

    private func save() {
        reminder.title          = title.trimmingCharacters(in: .whitespacesAndNewlines)
        reminder.notes          = notes
        reminder.dueDate        = hasDueDate ? dueDate : nil
        reminder.hasTime        = hasTime
        reminder.priority       = priority
        reminder.repeatInterval = repeatInterval
        reminder.list           = selectedList
        viewModel.updateReminder(reminder, context: context)
    }
}
