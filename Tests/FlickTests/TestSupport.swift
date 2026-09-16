import SwiftData
@testable import Flick

@MainActor
enum TestSupport {
    /// Shared in-memory ModelContext for tests that operate directly on a context
    /// (ArchiveService, TaskTransferService) without going through TaskStore.
    static func makeContext() throws -> ModelContext {
        try ModelContainer(for: TodoTask.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)).mainContext
    }
}
