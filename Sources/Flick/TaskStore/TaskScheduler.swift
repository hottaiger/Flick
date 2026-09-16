import Foundation
import SwiftData

@MainActor
final class TaskScheduler {
    private let context: ModelContext
    private var timer: Timer?

    init(context: ModelContext) { self.context = context }

    func start() { scheduleNextArchivePass() }
    func stop() { timer?.invalidate(); timer = nil }

    private func scheduleNextArchivePass() {
        timer?.invalidate()
        let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: .now))!
        timer = Timer(fireAt: nextDay, interval: 0, target: TimerTarget { [weak self] in self?.runPass() }, selector: #selector(TimerTarget.fire), userInfo: nil, repeats: false)
        RunLoop.main.add(timer!, forMode: .common)
    }

    private func runPass() {
        do {
            try ArchiveService.archiveCompletedTasks(in: context)
            try ArchiveService.purgeExpiredArchives(in: context)
        } catch {
            NSLog("Flick scheduled archive failed: \(error.localizedDescription)")
        }
        scheduleNextArchivePass()
    }
}

private final class TimerTarget: NSObject {
    let action: () -> Void
    init(action: @escaping () -> Void) { self.action = action }
    @objc func fire() { action() }
}
