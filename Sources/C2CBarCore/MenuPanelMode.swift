import Foundation

public enum MenuPanelMode: Equatable, Sendable {
    case market
    case settings

    public var showsMarketControls: Bool {
        self == .market
    }

    public var title: String? {
        switch self {
        case .market:
            return nil
        case .settings:
            return "设置"
        }
    }

    public var trailingSystemImageName: String {
        switch self {
        case .market:
            return "gearshape"
        case .settings:
            return "xmark"
        }
    }

    public mutating func toggleSettings() {
        self = self == .settings ? .market : .settings
    }
}
