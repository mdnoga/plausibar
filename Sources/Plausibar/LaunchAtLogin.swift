import Foundation
import ServiceManagement

enum LaunchAtLogin {
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    static var statusDescription: String {
        switch SMAppService.mainApp.status {
        case .notRegistered:     return "Off"
        case .enabled:           return "On"
        case .requiresApproval:  return "Needs approval in System Settings → Login Items"
        case .notFound:          return "Unavailable (run from /Applications)"
        @unknown default:        return "Unknown"
        }
    }

    @discardableResult
    static func set(_ enabled: Bool) -> Error? {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            return nil
        } catch {
            return error
        }
    }
}
