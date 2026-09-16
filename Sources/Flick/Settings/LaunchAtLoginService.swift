import ServiceManagement

enum LaunchAtLoginService {
    static func setEnabled(_ enabled: Bool) throws {
        if enabled { try SMAppService.mainApp.register() }
        else { try SMAppService.mainApp.unregister() }
    }

    static var isEnabled: Bool { SMAppService.mainApp.status == .enabled }
}
