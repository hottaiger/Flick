import Foundation
import SwiftData

enum TaskBucket: String, CaseIterable, Codable, Identifiable, Sendable {
    case now
    case today
    case later

    var id: String { rawValue }
    var title: String {
        switch self {
        case .now: L10n.t("board.now")
        case .today: L10n.t("board.today")
        case .later: L10n.t("board.later")
        }
    }
}

enum TaskPriority: Int, CaseIterable, Codable, Identifiable, Sendable {
    case low = 0
    case medium = 1
    case high = 2

    var id: Int { rawValue }
    var title: String {
        switch self {
        case .low: L10n.t("priority.low")
        case .medium: L10n.t("priority.medium")
        case .high: L10n.t("priority.high")
        }
    }
}

@Model
final class TodoTask {
    @Attribute(.unique) var id: UUID
    var title: String
    var bucketRawValue: String
    var priorityRawValue: Int
    var dueDate: Date?
    var note: String
    var createdAt: Date
    var completedAt: Date?
    var archivedAt: Date?
    var pinnedAt: Date?
    var sortOrder: Double

    init(
        id: UUID = UUID(),
        title: String,
        bucket: TaskBucket = .today,
        priority: TaskPriority = .medium,
        dueDate: Date? = nil,
        note: String = "",
        createdAt: Date = .now,
        completedAt: Date? = nil,
        archivedAt: Date? = nil,
        pinnedAt: Date? = nil,
        sortOrder: Double = 0
    ) {
        self.id = id
        self.title = title
        self.bucketRawValue = bucket.rawValue
        self.priorityRawValue = priority.rawValue
        self.dueDate = dueDate
        self.note = note
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.archivedAt = archivedAt
        self.pinnedAt = pinnedAt
        self.sortOrder = sortOrder
    }

    var bucket: TaskBucket {
        get { TaskBucket(rawValue: bucketRawValue) ?? .today }
        set { bucketRawValue = newValue.rawValue }
    }

    var priority: TaskPriority {
        get { TaskPriority(rawValue: priorityRawValue) ?? .medium }
        set { priorityRawValue = newValue.rawValue }
    }

    var isCompleted: Bool { completedAt != nil }
    var isArchived: Bool { archivedAt != nil }
    var isPinned: Bool { pinnedAt != nil }
    var isDueSoon: Bool {
        guard let dueDate, !isCompleted else { return false }
        return dueDate >= .now && dueDate <= Calendar.current.date(byAdding: .hour, value: 24, to: .now)!
    }
    var isOverdue: Bool {
        guard let dueDate, !isCompleted else { return false }
        return dueDate < .now
    }
}
