import Foundation

public enum RefreshIntervalOption: Int, Codable, CaseIterable, Identifiable, Sendable {
    case oneMinute = 60
    case fifteenMinutes = 900
    case thirtyMinutes = 1_800
    case oneHour = 3_600

    public var id: Int { rawValue }
    public var seconds: Int { rawValue }

    public var displayName: String {
        switch self {
        case .oneMinute:
            "1 分钟"
        case .fifteenMinutes:
            "15 分钟"
        case .thirtyMinutes:
            "30 分钟"
        case .oneHour:
            "1 小时"
        }
    }

    public static let defaultOption: RefreshIntervalOption = .oneMinute

    public static func option(seconds: Int) -> RefreshIntervalOption {
        RefreshIntervalOption(rawValue: seconds) ?? defaultOption
    }
}
