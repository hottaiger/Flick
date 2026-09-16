import XCTest
import SwiftData
@testable import Flick

final class ArchiveServiceTests: XCTestCase {
    @MainActor func testArchivesPreviousDayCompletionAndPurgesAfterThirtyDays() throws {
        let context = try TestSupport.makeContext()
        let oldCompletion = Calendar.current.date(byAdding: .day, value: -1, to: .now)!
        let task = TodoTask(title: "已完成", completedAt: oldCompletion)
        context.insert(task)
        try ArchiveService.archiveCompletedTasks(in: context)
        XCTAssertNotNil(task.archivedAt)
        try ArchiveService.purgeExpiredArchives(in: context, now: Calendar.current.date(byAdding: .day, value: 31, to: .now)!)
        XCTAssertTrue(try context.fetch(FetchDescriptor<TodoTask>()).isEmpty)
    }

    @MainActor func testSameDayCompletionNotArchived() throws {
        let context = try TestSupport.makeContext()
        let task = TodoTask(title: "今天完成", completedAt: .now)
        context.insert(task)
        try ArchiveService.archiveCompletedTasks(in: context)
        XCTAssertNil(task.archivedAt)
    }

    @MainActor func testArchivingIsIdempotent() throws {
        let context = try TestSupport.makeContext()
        let old = Calendar.current.date(byAdding: .day, value: -2, to: .now)!
        let task = TodoTask(title: "已完成", completedAt: old)
        context.insert(task)
        try ArchiveService.archiveCompletedTasks(in: context)
        let firstArchived = try XCTUnwrap(task.archivedAt)
        try ArchiveService.archiveCompletedTasks(in: context)
        XCTAssertEqual(task.archivedAt, firstArchived)
    }

    @MainActor func testPurgeBoundaryIsExclusive() throws {
        // purge uses `archivedAt < deadline`; exactly 30 days is kept, 31 is deleted.
        let context = try TestSupport.makeContext()
        let now = Date()
        let archived = { (daysAgo: Int) in Calendar.current.date(byAdding: .day, value: -daysAgo, to: now)! }
        let keep30 = TodoTask(title: "恰30天", completedAt: archived(31), archivedAt: archived(30))
        let delete31 = TodoTask(title: "31天", completedAt: archived(32), archivedAt: archived(31))
        context.insert(keep30)
        context.insert(delete31)
        try context.save()
        try ArchiveService.purgeExpiredArchives(in: context, now: now)
        let remaining = try context.fetch(FetchDescriptor<TodoTask>())
        XCTAssertTrue(remaining.contains(where: { $0.id == keep30.id }))
        XCTAssertFalse(remaining.contains(where: { $0.id == delete31.id }))
    }

    @MainActor func testPurgeDoesNotDeleteUnfinishedTasks() throws {
        let context = try TestSupport.makeContext()
        let unfinished = TodoTask(title: "未完成")
        context.insert(unfinished)
        try ArchiveService.purgeExpiredArchives(in: context)
        let remaining = try context.fetch(FetchDescriptor<TodoTask>())
        XCTAssertTrue(remaining.contains(where: { $0.id == unfinished.id }))
    }

    @MainActor func testEmptyStoreDoesNotCrash() throws {
        let context = try TestSupport.makeContext()
        try ArchiveService.archiveCompletedTasks(in: context)
        try ArchiveService.purgeExpiredArchives(in: context)
        XCTAssertTrue(try context.fetch(FetchDescriptor<TodoTask>()).isEmpty)
    }
}
