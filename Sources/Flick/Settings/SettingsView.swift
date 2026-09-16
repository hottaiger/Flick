import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    let appDelegate: AppDelegate
    @State private var launchError: String?
    @State private var shortcutError: String?

    var body: some View {
        Form {
            Section(L10n.t("settings.behavior")) {
                Toggle(L10n.t("settings.showCount"), isOn: $settings.showsTaskCount)
                Picker(L10n.t("settings.autoCollapse"), selection: $settings.autoCollapseSeconds) { Text(L10n.t("settings.off")).tag(0.0); Text(L10n.t("settings.seconds.5")).tag(5.0); Text(L10n.t("settings.seconds.10")).tag(10.0); Text(L10n.t("settings.seconds.30")).tag(30.0) }
                Picker(L10n.t("settings.shortcut"), selection: Binding(get: { settings.shortcutChoice }, set: { newValue in
                    if appDelegate.configureShortcut(newValue) {
                        settings.shortcutChoice = newValue
                        shortcutError = nil
                    } else {
                        shortcutError = L10n.t("settings.shortcutError")
                    }
                })) { ForEach(ShortcutChoice.allCases) { Text($0.title).tag($0) } }
                if let shortcutError { Text(shortcutError).foregroundStyle(.red) }
            }
            Section(L10n.t("settings.display")) { Picker(L10n.t("settings.placement"), selection: Binding(get: { settings.externalDisplayPlacement }, set: { settings.externalDisplayPlacement = $0; appDelegate.refreshPanelPlacement() })) { ForEach(ExternalDisplayPlacement.allCases) { Text($0.title).tag($0) } } }
            Section(L10n.t("settings.launch")) {
                Toggle(L10n.t("settings.launchAtLogin"), isOn: $settings.launchAtLogin).onChange(of: settings.launchAtLogin) { _, enabled in do { try LaunchAtLoginService.setEnabled(enabled) } catch { launchError = error.localizedDescription; settings.launchAtLogin = LaunchAtLoginService.isEnabled } }
                if let launchError { Text(launchError).foregroundStyle(.red) }
            }
        }.padding().frame(width: 420)
    }
}
