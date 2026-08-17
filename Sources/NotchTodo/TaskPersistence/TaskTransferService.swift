import Foundation
import SwiftData

struct TaskTransferDocument: Codable {
    static let currentVersion = 1
    let version: Int
    let exportedAt: Date
    let tasks: [TaskTransferItem]
}

struct TaskTransferItem: Codable, Identifiable {
    let id: UUID
    let title: String
    let bucket: TaskBucket
    let priority: TaskPriority
    let dueDate: Date?
    let note: String
    let createdAt: Date
    let completedAt: Date?
    let archivedAt: Date?
    let pinnedAt: Date?
    let sortOrder: Double

    init(task: TodoTask) {
        id = task.id; title = task.title; bucket = task.bucket; priority = task.priority
        dueDate = task.dueDate; note = task.note; createdAt = task.createdAt
        completedAt = task.completedAt; archivedAt = task.archivedAt; pinnedAt = task.pinnedAt; sortOrder = task.sortOrder
    }
}

@MainActor
enum TaskTransferService {
    static func exportData(from context: ModelContext) throws -> Data {
        let tasks = try context.fetch(FetchDescriptor<TodoTask>()).map(TaskTransferItem.init(task:))
        return try JSONEncoder.notchTodo.encode(TaskTransferDocument(version: TaskTransferDocument.currentVersion, exportedAt: .now, tasks: tasks))
    }

    static func importData(_ data: Data, into context: ModelContext) throws {
        let document = try JSONDecoder.notchTodo.decode(TaskTransferDocument.self, from: data)
        guard document.version == TaskTransferDocument.currentVersion else { throw TransferError.unsupportedVersion }
        guard document.tasks.allSatisfy({ !$0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else { throw TransferError.emptyTitle }
        let existingIDs = Set(try context.fetch(FetchDescriptor<TodoTask>()).map(\.id))
        for item in document.tasks where !existingIDs.contains(item.id) {
            context.insert(TodoTask(id: item.id, title: item.title, bucket: item.bucket, priority: item.priority, dueDate: item.dueDate, note: item.note, createdAt: item.createdAt, completedAt: item.completedAt, archivedAt: item.archivedAt, pinnedAt: item.pinnedAt, sortOrder: item.sortOrder))
        }
        try context.save()
    }

    enum TransferError: LocalizedError { case unsupportedVersion, emptyTitle
        var errorDescription: String? { self == .unsupportedVersion ? L10n.t("error.unsupportedVersion") : L10n.t("error.emptyTitle") }
    }
}

private extension JSONEncoder {
    static var notchTodo: JSONEncoder { let encoder = JSONEncoder(); encoder.dateEncodingStrategy = .iso8601; encoder.outputFormatting = [.prettyPrinted, .sortedKeys]; return encoder }
}

private extension JSONDecoder {
    static var notchTodo: JSONDecoder { let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601; return decoder }
}
