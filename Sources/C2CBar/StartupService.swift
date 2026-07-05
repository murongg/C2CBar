import Foundation
import ServiceManagement

enum StartupServiceStatus: Equatable {
    case enabled
    case disabled
    case requiresApproval
    case unavailable
    case failed(String)

    var displayText: String {
        switch self {
        case .enabled:
            "已开启"
        case .disabled:
            "未开启"
        case .requiresApproval:
            "需系统批准"
        case .unavailable:
            "不可用"
        case .failed:
            "设置失败"
        }
    }
}

protocol StartupServiceManaging {
    var status: StartupServiceStatus { get }
    func setEnabled(_ enabled: Bool) throws
    func openSystemSettings()
}

final class StartupService: StartupServiceManaging {
    var status: StartupServiceStatus {
        switch SMAppService.mainApp.status {
        case .enabled:
            .enabled
        case .notRegistered:
            .disabled
        case .requiresApproval:
            .requiresApproval
        case .notFound:
            .unavailable
        @unknown default:
            .unavailable
        }
    }

    func setEnabled(_ enabled: Bool) throws {
        if enabled {
            guard status != .enabled else { return }
            try SMAppService.mainApp.register()
        } else {
            guard status != .disabled else { return }
            try SMAppService.mainApp.unregister()
        }
    }

    func openSystemSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }
}
