import Foundation

public struct MenuPanelWindowSize: Equatable, Sendable {
    public let width: Double
    public let height: Double

    public init(width: Double, height: Double) {
        self.width = width
        self.height = height
    }
}

public enum MenuPanelWindowLayout {
    public static let width = 392.0

    public static func windowSize(measuredContentHeight: Double) -> MenuPanelWindowSize {
        MenuPanelWindowSize(
            width: width,
            height: ceil(max(1, measuredContentHeight))
        )
    }
}

public struct MenuPanelWindowResizeRequest: Equatable, Sendable {
    public let targetSize: MenuPanelWindowSize

    public static func request(
        current: MenuPanelWindowSize,
        target: MenuPanelWindowSize,
        tolerance: Double = 0.5
    ) -> MenuPanelWindowResizeRequest? {
        let widthDelta = abs(current.width - target.width)
        let heightDelta = abs(current.height - target.height)

        guard widthDelta > tolerance || heightDelta > tolerance else {
            return nil
        }

        return MenuPanelWindowResizeRequest(targetSize: target)
    }
}
