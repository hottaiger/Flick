import SwiftUI

struct TaskEditorView: View {
    let task: TodoTask
    @ObservedObject var store: TaskStore
    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var priority: TaskPriority
    @State private var dueDate: Date
    @State private var hasDueDate: Bool
    @State private var note: String

    init(task: TodoTask, store: TaskStore) {
        self.task = task; self.store = store
        _title = State(initialValue: task.title); _priority = State(initialValue: task.priority)
        _dueDate = State(initialValue: task.dueDate ?? .now); _hasDueDate = State(initialValue: task.dueDate != nil)
        _note = State(initialValue: task.note)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L10n.t("editor.title")).font(.headline)
            TextField(L10n.t("editor.titleField"), text: $title)
            Picker(L10n.t("editor.priority"), selection: $priority) { ForEach(TaskPriority.allCases) { Text($0.title).tag($0) } }.pickerStyle(.segmented)
            Toggle(L10n.t("editor.dueToggle"), isOn: $hasDueDate)
            if hasDueDate { DatePicker(L10n.t("editor.dueDate"), selection: $dueDate, displayedComponents: [.date, .hourAndMinute]) }
            TextField(L10n.t("editor.note"), text: $note, axis: .vertical).lineLimit(3...6)
            HStack { Button(L10n.t("editor.cancel")) { dismiss() }; Spacer(); Button(L10n.t("editor.save")) { store.update(task, title: title, priority: priority, dueDate: hasDueDate ? dueDate : nil, note: note); dismiss() }.keyboardShortcut(.defaultAction) }
        }
        .padding().frame(width: 360)
    }
}
