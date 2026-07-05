import Foundation
import C2CBarCore
import UserNotifications

enum NotificationServiceStatus: Equatable {
    case notRequested
    case authorized
    case denied
    case unavailable
    case failed(String)

    var displayText: String {
        switch self {
        case .notRequested:
            "未请求"
        case .authorized:
            "已授权"
        case .denied:
            "未授权"
        case .unavailable:
            "不可用"
        case .failed:
            "通知失败"
        }
    }
}

@MainActor
protocol PriceAlertNotifying {
    func requestAuthorization() async -> NotificationServiceStatus
    func deliver(_ event: PriceAlertEvent) async -> NotificationServiceStatus
}

@MainActor
final class PriceAlertNotificationService: PriceAlertNotifying {
    private let centerProvider: () -> UNUserNotificationCenter
    private let supportsUserNotifications: Bool

    init(
        bundleURL: URL = Bundle.main.bundleURL,
        centerProvider: @escaping () -> UNUserNotificationCenter = { .current() }
    ) {
        self.centerProvider = centerProvider
        supportsUserNotifications = AppRuntimePolicy.supportsUserNotifications(bundleURL: bundleURL)
    }

    func requestAuthorization() async -> NotificationServiceStatus {
        guard supportsUserNotifications else {
            return .unavailable
        }

        let center = centerProvider()
        return await withCheckedContinuation { (continuation: CheckedContinuation<NotificationServiceStatus, Never>) in
            center.requestAuthorization(options: [.alert, .sound]) { granted, error in
                if let error {
                    continuation.resume(returning: .failed(error.localizedDescription))
                } else {
                    continuation.resume(returning: granted ? .authorized : .denied)
                }
            }
        }
    }

    func deliver(_ event: PriceAlertEvent) async -> NotificationServiceStatus {
        let authorizationStatus = await requestAuthorization()
        guard authorizationStatus == .authorized else {
            return authorizationStatus
        }

        let center = centerProvider()
        let content = UNMutableNotificationContent()
        content.title = event.title
        content.body = event.body
        content.sound = .default
        content.threadIdentifier = "C2CBar.price-alerts"

        let request = UNNotificationRequest(
            identifier: "C2CBar.\(event.id)",
            content: content,
            trigger: nil
        )

        return await withCheckedContinuation { (continuation: CheckedContinuation<NotificationServiceStatus, Never>) in
            center.add(request) { error in
                if let error {
                    continuation.resume(returning: .failed(error.localizedDescription))
                } else {
                    continuation.resume(returning: .authorized)
                }
            }
        }
    }
}
