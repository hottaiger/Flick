import XCTest
import SwiftData
@testable import Flick

final class TaskTransferServiceTests: XCTestCase {
    @MainActor func testExportThenImportPreservesTask() throws {
        let source = try TestSupport.makeContext()
        source.insert(TodoTask(title: "备份", bucket: .later, priority: .high, note: "说明"))
        try source.save()
        let data = try TaskTransferService.exportData(from: source)
        let destination = try TestSupport.makeContext()
        try TaskTransferService.importData(data, into: destination)
        let result = try destination.fetch(FetchDescriptor<TodoTask>())
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.title, "备份")
        XCTAssertEqual(result.first?.priority, .high)
    }

    @MainActor func testRejectsUnsupportedVersion() throws {
        let data = "{\"version\":99,\"exportedAt\":\"2026-08-09T00:00:00Z\",\"tasks\":[]}".data(using: .utf8)!
        let context = try TestSupport.makeContext()
        XCTAssertThrowsError(try TaskTransferService.importData(data, into: context))
    }

    @MainActor func testRejectsMalformedJSON() throws {
        let malformed = "not json".data(using: .utf8)!
        let context = try TestSupport.makeContext()
        XCTAssertThrowsError(try TaskTransferService.importData(malformed, into: context))
    }

    @MainActor func testImportDoesNotDuplicateExistingID() throws {
        let context = try TestSupport.makeContext()
        context.insert(TodoTask(title: "原"))
        try context.save()
        let data = try TaskTransferService.exportData(from: context)
        try TaskTransferService.importData(data, into: context)
        XCTAssertEqual(try context.fetch(FetchDescriptor<TodoTask>()).count, 1)
    }

    @MainActor func testRoundTripPreservesAllFields() throws {
        let source = try TestSupport.makeContext()
        let due = Calendar.current.date(byAdding: .day, value: 3, to: .now)!
        let created = Calendar.current.date(byAdding: .day, value: -1, to: .now)!
        let completed = Calendar.current.date(byAdding: .hour, value: -2, to: .now)!
        let archived = Calendar.current.date(byAdding: .hour, value: -1, to: .now)!
        source.insert(TodoTask(title: "全字段", bucket: .later, priority: .high, dueDate: due, note: "备注内容", createdAt: created, completedAt: completed, archivedAt: archived, sortOrder: 5))
        try source.save()
        let data = try TaskTransferService.exportData(from: source)
        let dest = try TestSupport.makeContext()
        try TaskTransferService.importData(data, into: dest)
        let restored = try XCTUnwrap(try dest.fetch(FetchDescriptor<TodoTask>()).first)
        XCTAssertEqual(restored.title, "全字段")
        XCTAssertEqual(restored.bucket, .later)
        XCTAssertEqual(restored.priority, .high)
        XCTAssertEqual(restored.note, "备注内容")
        XCTAssertEqual(restored.sortOrder, 5)
        // ISO8601 round-trip truncates to whole seconds; compare via epoch with tolerance.
        XCTAssertEqual(restored.createdAt.timeIntervalSince1970, created.timeIntervalSince1970, accuracy: 1.0)
        XCTAssertEqual(try XCTUnwrap(restored.dueDate).timeIntervalSince1970, due.timeIntervalSince1970, accuracy: 1.0)
        XCTAssertEqual(try XCTUnwrap(restored.completedAt).timeIntervalSince1970, completed.timeIntervalSince1970, accuracy: 1.0)
        XCTAssertEqual(try XCTUnwrap(restored.archivedAt).timeIntervalSince1970, archived.timeIntervalSince1970, accuracy: 1.0)
    }
}
