import AppKit
import SwiftUI

enum TaskTitleClipboard {
    static func copy(_ title: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(title, forType: .string)
    }
}

struct TaskCardView: View {
    let task: TodoTask
    let store: TaskStore
    @Binding var editorTask: TodoTask?
    let activity: () -> Void

    var body: some View {
        cardContent
            .padding(7)
            .background(.background.opacity(0.55), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            .contentShape(Rectangle())
            .onTapGesture { editorTask = task; activity() }
            .focusable()
            .onKeyPress(.return, phases: .down) { context in
                guard context.modifiers.contains(.command) else { return .ignored }
                MainActor.assumeIsolated { toggleCompletion() }
                return .handled
            }
            .onKeyPress(.delete, phases: .down) { _ in
                MainActor.assumeIsolated { store.delete(task); activity() }
                return .handled
            }
            .contextMenu {
                Menu(L10n.t("card.priority")) { ForEach(TaskPriority.allCases) { priority in Button(priority.title) { store.setPriority(task, priority: priority) } } }
                Button(L10n.t("card.defer")) { store.deferToTomorrow(task) }
                Button(L10n.t("card.delete"), role: .destructive) { store.delete(task) }
            }
            .dropDestination(for: String.self) { identifiers, _ in
                guard let raw = identifiers.first,
                      let id = UUID(uuidString: raw),
                      let dragged = store.tasks.first(where: { $0.id == id }),
                      dragged.id != task.id else { return false }
                store.move(dragged, before: task)
                activity()
                return true
            }
            .accessibilityElement(children: .combine)
    }

    /// Card row content extracted so the body's modifier chain stays type-checkable.
    @MainActor
    @ViewBuilder
    private var cardContent: some View {
        HStack(alignment: .top, spacing: 6) {
            Button {
                toggleCompletion()
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(task.isCompleted ? .green : priorityColor)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(task.isCompleted ? L10n.t("card.reopenAccessibility", task.title) : L10n.t("card.completeAccessibility", task.title))
            VStack(alignment: .leading, spacing: 3) {
                Text(task.title).font(.system(size: 12, weight: .medium)).strikethrough(task.isCompleted).lineLimit(2)
                if let dueDate = task.dueDate {
                    Label(task.isOverdue ? L10n.t("card.overdue") : dueDate.formatted(.dateTime.month(.abbreviated).day()), systemImage: task.isOverdue ? "exclamationmark.circle.fill" : "calendar")
                        .font(.system(size: 9)).foregroundStyle(task.isOverdue ? .red : (task.isDueSoon ? .orange : .secondary))
                }
            }
            Spacer(minLength: 0)
            Button {
                store.togglePin(task)
                activity()
            } label: {
                Image(systemName: task.isPinned ? "pin.fill" : "pin")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(task.isPinned ? .blue : .secondary)
            }
            .buttonStyle(.plain)
            .help(task.isPinned ? L10n.t("card.unpin") : L10n.t("card.pin"))
            .accessibilityLabel(task.isPinned ? L10n.t("card.unpinAccessibility", task.title) : L10n.t("card.pinAccessibility", task.title))
            Button {
                TaskTitleClipboard.copy(task.title)
                activity()
            } label: {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help(L10n.t("card.copyTitle"))
            .accessibilityLabel(L10n.t("card.copyAccessibility", task.title))
        }
    }

    @MainActor
    private func toggleCompletion() {
        task.isCompleted ? store.reopen(task) : store.complete(task)
        activity()
    }

    private var priorityColor: Color { switch task.priority { case .high: .red; case .medium: .blue; case .low: .gray } }
}
