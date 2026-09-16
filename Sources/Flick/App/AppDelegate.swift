import AppKit
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

enum StatusBarIcon {
    static let symbolName = "fish.fill"
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private(set) var settings = AppSettings()
    private(set) var store: TaskStore!
    private(set) var panelController: NotchPanelController!
    private var shortcut: GlobalShortcutManager?
    private var scheduler: TaskScheduler?
    private var statusItem: NSStatusItem?
    private var settingsWindow: NSWindow?
    private(set) var recoveryMessage: String?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        installStatusItem()
        let factory = ModelContainerFactory.make()
        recoveryMessage = factory.recoveryMessage
        store = TaskStore(context: factory.container.mainContext)
        do {
            try ArchiveService.archiveCompletedTasks(in: store.context)
            try ArchiveService.purgeExpiredArchives(in: store.context)
        } catch {
            present(error)
        }
        scheduler = TaskScheduler(context: store.context)
        scheduler?.start()
        panelController = NotchPanelController(store: store, settings: settings)
        shortcut = GlobalShortcutManager { [weak self] in self?.panelController.toggle() }
        configureShortcut(settings.shortcutChoice)
        if settings.launchAtLogin {
            do {
                try LaunchAtLoginService.setEnabled(true)
            } catch {
                settings.launchAtLogin = LaunchAtLoginService.isEnabled
            }
        }
        if let recoveryMessage {
            DispatchQueue.main.async { [weak self] in self?.present(recoveryMessage, title: L10n.t("recovery.title")) }
        }
    }

    @discardableResult
    func configureShortcut(_ choice: ShortcutChoice) -> Bool {
        guard let shortcut else { return false }
        let ok = shortcut.register(choice)
        if !ok {
            _ = shortcut.register(settings.shortcutChoice)
        }
        return ok
    }
    func refreshPanelPlacement() { panelController.collapse() }

    private func installStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.image = NSImage(systemSymbolName: StatusBarIcon.symbolName, accessibilityDescription: "Flick")
        item.button?.title = ""
        item.button?.toolTip = "Flick"
        item.button?.setAccessibilityLabel("Flick")
        let menu = NSMenu()
        menu.addItem(withTitle: L10n.t("menu.openBoard"), action: #selector(togglePanel), keyEquivalent: "")
        menu.addItem(withTitle: L10n.t("menu.export"), action: #selector(exportTasks), keyEquivalent: "")
        menu.addItem(withTitle: L10n.t("menu.import"), action: #selector(importTasks), keyEquivalent: "")
        menu.addItem(withTitle: L10n.t("menu.settings"), action: #selector(showSettings), keyEquivalent: ",")
        menu.addItem(.separator())
        menu.addItem(withTitle: L10n.t("menu.quit"), action: #selector(quit), keyEquivalent: "q")
        menu.items.forEach { $0.target = self }
        item.menu = menu
        statusItem = item
    }

    @objc private func togglePanel() { panelController.toggle() }
    @objc private func quit() { NSApp.terminate(nil) }

    @objc private func showSettings() {
        if settingsWindow == nil {
            let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 440, height: 320), styleMask: [.titled, .closable], backing: .buffered, defer: false)
            window.title = L10n.t("settings.windowTitle")
            window.isReleasedWhenClosed = false
            window.contentView = NSHostingView(rootView: SettingsView(settings: settings, appDelegate: self))
            window.center()
            settingsWindow = window
        }
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
    }

    @objc private func exportTasks() {
        do {
            let panel = NSSavePanel()
            panel.allowedContentTypes = [.json]
            panel.nameFieldStringValue = "Flick-backup.json"
            guard panel.runModal() == .OK, let url = panel.url else { return }
            try TaskTransferService.exportData(from: store.context).write(to: url, options: .atomic)
        } catch { present(error) }
    }

    @objc private func importTasks() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try TaskTransferService.importData(Data(contentsOf: url), into: store.context)
            store.refresh()
        } catch { present(error) }
    }

    private func present(_ error: Error) {
        let alert = NSAlert(error: error)
        alert.runModal()
    }

    private func present(_ message: String, title: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.runModal()
    }
}
