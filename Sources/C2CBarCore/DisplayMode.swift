import Foundation

public enum DisplayMode: String, Codable, CaseIterable, Identifiable, Sendable {
    case standard = "标准"
    case compact = "紧凑"
    case minimal = "极简"

    public var id: String { rawValue }

    public var visibleRowCount: Int {
        switch self {
        case .standard:
            return 5
        case .compact:
            return 4
        case .minimal:
            return 2
        }
    }
}
