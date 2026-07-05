import Foundation

public struct MenuPanelContentPolicy: Equatable, Sendable {
    public let displayMode: DisplayMode

    public init(displayMode: DisplayMode) {
        self.displayMode = displayMode
    }

    public var showsReferenceRate: Bool {
        true
    }

    public var showsPlatformTable: Bool {
        displayMode != .minimal
    }

    public var showsCompactPlatformTable: Bool {
        displayMode == .compact
    }

    public var showsFooter: Bool {
        true
    }

    public var reservesPlatformRows: Bool {
        displayMode == .standard
    }
}
