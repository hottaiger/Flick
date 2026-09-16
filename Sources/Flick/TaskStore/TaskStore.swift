import Foundation
import SwiftData
import Combine

@MainActor
final class TaskStore: ObservableObject {
    @Published private(set) var tasks: [TodoTask] = []
    @Published private(set) var activeTasks: [TodoTask] = []
    @Published private(set) var completedTasks: [TodoTask] = []
    @Published private(set) var archivedTasks: [TodoTask] = []
    /// 单栏看板列表：置顶任务在前（最新置顶的最上），普通任务按 sortOrder。
    @Published private(set) var boardTasks: [TodoTask] = []
    @Published private(set) var saveError: String?
    /// 看板内轻提示（如"复制成功"），短暂展示后自动清空。
    @Published private(set) var toast: String?
    private var toastDismissTask: Task<Void, Never>?
    let context: ModelContext

    init(context: ModelContext) {
        self.context = context
        refresh()
    }

    /// 兼容保留：按 bucket 过滤的列表（历史数据/测试用）。看板 UI 已改为单栏 `boardTasks`。
    func tasks(in bucket: TaskBucket) -> [TodoTask] {
        activeTasks
            .filter { bucket == .now ? ($0.bucket == .now || $0.bucket == .today) : $0.bucket == bucket }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    @discardableResult
    func add(title: String, bucket: TaskBucket = .now) -> TodoTask? {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else { return nil }
        let task = TodoTask(title: cleanTitle, bucket: bucket, sortOrder: nextOrder())
        context.insert(task)
        saveAndRefresh()
        return task
    }

    func update(_ task: TodoTask, title: String, priority: TaskPriority, dueDate: Date?, note: String) {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else { return }
        task.title = cleanTitle
        task.priority = priority
        task.dueDate = dueDate
        task.note = note
        saveAndRefresh()
    }

    /// 单栏内移动：传 `neighbor` 插到该任务之前（中值 sortOrder），省略则追加到普通区末尾。
    func move(_ task: TodoTask, before neighbor: TodoTask?) {
        task.sortOrder = insertionSortOrder(for: task, before: neighbor)
        saveAndRefresh()
    }

    func complete(_ task: TodoTask) {
        task.completedAt = .now
        saveAndRefresh()
    }

    func reopen(_ task: TodoTask) {
        task.completedAt = nil
        task.archivedAt = nil
        task.sortOrder = nextOrder()
        saveAndRefresh()
    }

    func delete(_ task: TodoTask) {
        context.delete(task)
        saveAndRefresh()
    }

    func deferToTomorrow(_ task: TodoTask) {
        task.dueDate = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: .now))
        task.bucket = .today
        task.sortOrder = nextOrder()
        saveAndRefresh()
    }

    func setPriority(_ task: TodoTask, priority: TaskPriority) {
        task.priority = priority
        saveAndRefresh()
    }

    /// 置顶/取消置顶；置顶后固定排在看板最前（最新的在最上）。
    func togglePin(_ task: TodoTask) {
        task.pinnedAt = task.isPinned ? nil : .now
        saveAndRefresh()
    }

    /// Restore an archived task: clears `archivedAt` but keeps `completedAt`, so the task
    /// reappears in the "已完成" section. Use `reopen(_:)` afterwards to make it active again.
    func unarchive(_ task: TodoTask) {
        task.archivedAt = nil
        saveAndRefresh()
    }

    func refresh() {
        let descriptor = FetchDescriptor<TodoTask>(sortBy: [SortDescriptor(\.createdAt)])
        do {
            tasks = try context.fetch(descriptor)
        } catch {
            tasks = []
            saveError = error.localizedDescription
        }
        recomputeDerivedLists()
    }

    func clearError() {
        saveError = nil
    }

    func showToast(_ text: String) {
        toast = text
        toastDismissTask?.cancel()
        toastDismissTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 1_600_000_000)
            guard !Task.isCancelled else { return }
            self?.toast = nil
        }
    }

    private func recomputeDerivedLists() {
        activeTasks = tasks.filter { !$0.isCompleted && !$0.isArchived }
        completedTasks = tasks.filter { $0.isCompleted && !$0.isArchived }.sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
        archivedTasks = tasks.filter { $0.isArchived }.sorted { ($0.archivedAt ?? .distantPast) > ($1.archivedAt ?? .distantPast) }
        let pinned = activeTasks.filter { $0.isPinned }.sorted { ($0.pinnedAt ?? .distantPast) > ($1.pinnedAt ?? .distantPast) }
        let normal = activeTasks.filter { !$0.isPinned }.sorted {
            $0.sortOrder != $1.sortOrder ? $0.sortOrder < $1.sortOrder : $0.createdAt < $1.createdAt
        }
        boardTasks = pinned + normal
    }

    private func nextOrder() -> Double {
        (activeTasks.filter { !$0.isPinned }.map(\.sortOrder).max() ?? -1) + 1
    }

    private func insertionSortOrder(for task: TodoTask, before neighbor: TodoTask?) -> Double {
        let column = boardTasks.filter { !$0.isPinned && $0.id != task.id }
        guard let neighbor, !neighbor.isPinned, let idx = column.firstIndex(where: { $0.id == neighbor.id }) else {
            return (column.map(\.sortOrder).max() ?? -1) + 1
        }
        let neighborOrder = column[idx].sortOrder
        if idx == 0 { return neighborOrder - 1 }
        return (column[idx - 1].sortOrder + neighborOrder) / 2
    }

    private func saveAndRefresh() {
        do {
            try context.save()
        } catch {
            saveError = error.localizedDescription
        }
        refresh()
    }
}
