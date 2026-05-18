import SwiftUI

/// Sheet for creating or editing a reminder list.
struct AddListView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss)      private var dismiss

    var listViewModel: ListViewModel
    /// When non-nil, the view edits the existing list instead of creating a new one.
    var editingList: ReminderList? = nil

    @State private var name         = ""
    @State private var selectedColor = "blue"
    @State private var selectedIcon  = "list.bullet"
    @FocusState private var nameFocused: Bool

    private let columns = Array(repeating: GridItem(.flexible()), count: 5)

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Name
                Section {
                    HStack(spacing: 12) {
                        // Icon preview
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(named: selectedColor))
                                .frame(width: 36, height: 36)
                            Image(systemName: selectedIcon)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.white)
                        }
                        TextField("List Name", text: $name)
                            .focused($nameFocused)
                            .font(.body.weight(.medium))
                    }
                }

                // MARK: Color Picker
                Section("Color") {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(ListColor.allCases) { lc in
                            Button {
                                withAnimation(.smoothSpring) { selectedColor = lc.rawValue }
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(lc.color)
                                        .frame(width: 34, height: 34)
                                    if selectedColor == lc.rawValue {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundStyle(.white)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }

                // MARK: Icon Picker
                Section("Icon") {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(ListIcon.allCases) { li in
                            Button {
                                withAnimation(.smoothSpring) { selectedIcon = li.rawValue }
                            } label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 7)
                                        .fill(
                                            selectedIcon == li.rawValue
                                                ? Color(named: selectedColor)
                                                : Color(.tertiarySystemFill)
                                        )
                                        .frame(width: 38, height: 38)
                                    Image(systemName: li.rawValue)
                                        .font(.system(size: 16))
                                        .foregroundStyle(
                                            selectedIcon == li.rawValue ? .white : .primary
                                        )
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle(editingList == nil ? "New List" : "Edit List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(editingList == nil ? "Add" : "Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(name.isBlank)
                }
            }
            .onAppear {
                if let list = editingList {
                    name          = list.name
                    selectedColor = list.colorName
                    selectedIcon  = list.iconName
                }
                nameFocused = true
            }
        }
    }

    private func save() {
        if let list = editingList {
            listViewModel.updateList(list, name: name, colorName: selectedColor, iconName: selectedIcon)
        } else {
            listViewModel.addList(name: name, colorName: selectedColor, iconName: selectedIcon, context: context)
        }
        dismiss()
    }
}
