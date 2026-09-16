import AppKit
import SwiftUI

@MainActor
final class NotchPanelController: NSObject, ObservableObject {
    private static let collapsedCapsuleWidth: CGFloat = 104
    @Published private(set) var isExpanded = false
    @Published private(set) var transitionPhase: PanelTransitionPhase = .collapsed
    @Published private(set) var collapseAnimationID: UInt = 0
    private let panel: NotchPanelWindow
    private let store: TaskStore
    private let settings: AppSettings
    private var inactivityTimer: Timer?
    private var globalMonitor: Any?
    private var screenParametersObserver: NSObjectProtocol?
    private let usesTrailingSummaryLayout: Bool
    private let isNotchAttached: Bool

    init(store: TaskStore, settings: AppSettings) {
        self.store = store
        self.settings = settings
        let screen = DisplayPlacementResolver.preferredScreen() ?? NSScreen.screens[0]
        usesTrailingSummaryLayout = false
        isNotchAttached = DisplayPlacementResolver.notchRightFrame(on: screen, width: Self.collapsedCapsuleWidth) != nil
        panel = NotchPanelWindow(contentRect: Self.collapsedSurfaceFrame(on: screen, placement: settings.externalDisplayPlacement))
        super.init()
        panel.contentView = NSHostingView(rootView: NotchSurfaceView(controller: self, store: store, settings: settings, usesTrailingSummaryLayout: usesTrailingSummaryLayout, isNotchAttached: isNotchAttached))
        panel.orderFrontRegardless()
        screenParametersObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            DispatchQueue.main.async { [weak self] in self?.repositionForDisplayChange() }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in self?.repositionForDisplayChange() }
        }
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown]) { [weak self] event in
            guard let self, self.isExpanded, !self.panel.frame.contains(event.locationInWindow) else { return }
            DispatchQueue.main.async { [weak self] in self?.collapse() }
        }
    }

    deinit {
        if let globalMonitor { NSEvent.removeMonitor(globalMonitor) }
        if let screenParametersObserver { NotificationCenter.default.removeObserver(screenParametersObserver) }
    }

    func toggle() { isExpanded ? collapse() : expand() }

    func expand() {
        guard !isExpanded else { return }
        let screen = DisplayPlacementResolver.preferredScreen() ?? NSScreen.screens[0]
        // accessory 应用需要显式激活，否则键盘事件仍发给前台应用，输入框无法打字
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
        transitionPhase = .expanding
        isExpanded = true
        resize(to: DisplayPlacementResolver.expandedFrame(on: screen, placement: settings.externalDisplayPlacement)) { [weak self] in
            guard self?.isExpanded == true else { return }
            self?.transitionPhase = .expanded
        }
        resetInactivityTimer()
    }

    func collapse() {
        guard isExpanded else { return }
        let screen = DisplayPlacementResolver.preferredScreen() ?? NSScreen.screens[0]
        transitionPhase = .collapsing
        collapseAnimationID &+= 1
        isExpanded = false
        inactivityTimer?.invalidate()
        resize(to: Self.collapsedSurfaceFrame(on: screen, placement: settings.externalDisplayPlacement)) { [weak self] in
            guard self?.isExpanded == false else { return }
            self?.transitionPhase = .collapsed
        }
    }

    func registerActivity() { if isExpanded { resetInactivityTimer() } }

    private func repositionForDisplayChange() {
        let screen = DisplayPlacementResolver.preferredScreen() ?? NSScreen.screens[0]
        let frame = isExpanded
            ? DisplayPlacementResolver.expandedFrame(on: screen, placement: settings.externalDisplayPlacement)
            : Self.collapsedSurfaceFrame(on: screen, placement: settings.externalDisplayPlacement)
        panel.setFrame(frame, display: true)
    }

    private func resetInactivityTimer() {
        inactivityTimer?.invalidate()
        guard settings.autoCollapseSeconds > 0 else { return }
        inactivityTimer = Timer.scheduledTimer(withTimeInterval: settings.autoCollapseSeconds, repeats: false) { [weak self] _ in
            DispatchQueue.main.async { [weak self] in self?.collapse() }
        }
    }

    private static func collapsedSurfaceFrame(on screen: NSScreen, placement: ExternalDisplayPlacement) -> NSRect {
        DisplayPlacementResolver.collapsedSurfaceFrame(
            on: screen,
            capsuleWidth: Self.collapsedCapsuleWidth,
            placement: placement
        )
    }

    private func resize(to frame: NSRect, completion: @escaping () -> Void = {}) {
        let duration = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion ? 0 : 0.22
        guard duration > 0 else {
            panel.setFrame(frame, display: true)
            completion()
            return
        }
        NSAnimationContext.runAnimationGroup { context in
            context.duration = duration
            panel.animator().setFrame(frame, display: true)
        } completionHandler: {
            completion()
        }
    }
}
