import Foundation
import SwiftData

@MainActor
enum ArchiveService {
    static func archiveCompletedTasks(in context: ModelContext, now: Date = .now) throws {
        let endOfPreviousDay = Calendar.current.startOfDay(for: now)
        let descriptor = FetchDescriptor<TodoTask>(predicate: #Predicate { $0.archivedAt == nil })
        let tasks = try context.fetch(descriptor)
        for task in tasks where task.completedAt.map({ $0 < endOfPreviousDay }) == true {
            task.archivedAt = now
        }
        try context.save()
    }

    static func purgeExpiredArchives(in context: ModelContext, now: Date = .now) throws {
        let deadline = Calendar.current.date(byAdding: .day, value: -30, to: now)!
        let descriptor = FetchDescriptor<TodoTask>(predicate: #Predicate { $0.archivedAt != nil })
        let tasks = try context.fetch(descriptor)
        for task in tasks where task.archivedAt.map({ $0 < deadline }) == true {
            context.delete(task)
        }
        try context.save()
    }
}
