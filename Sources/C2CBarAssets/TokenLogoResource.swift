import AppKit
import Foundation
import C2CBarCore

public enum TokenLogoResource {
    public static func name(for stablecoin: Stablecoin) -> String {
        stablecoin.logoResourceName
    }

    public static func url(for stablecoin: Stablecoin) -> URL? {
        let resourceName = stablecoin.logoResourceName

        // SwiftPM may flatten processed resource folders in the bundle, so keep both lookup paths valid.
        return Bundle.module.url(
            forResource: resourceName,
            withExtension: "png",
            subdirectory: "Tokens"
        ) ?? Bundle.module.url(
            forResource: resourceName,
            withExtension: "png"
        )
    }

    public static func image(for stablecoin: Stablecoin) -> NSImage? {
        guard let url = url(for: stablecoin) else { return nil }
        return ImageCache.shared.image(for: url)
    }
}

private extension Stablecoin {
    var logoResourceName: String {
        switch self {
        case .usdt:
            return "usdt"
        case .usdc:
            return "usdc"
        }
    }
}
