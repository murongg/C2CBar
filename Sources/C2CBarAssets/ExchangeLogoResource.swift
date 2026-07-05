import AppKit
import Foundation
import C2CBarCore

public enum C2CBarAssetBundle {
    public static let bundle = Bundle.module
}

public enum ExchangeLogoResource {
    public static func name(for exchange: C2CExchange) -> String {
        exchange.logoResourceName
    }

    public static func url(for exchange: C2CExchange) -> URL? {
        let resourceName = exchange.logoResourceName

        // SwiftPM may flatten processed resource folders in the bundle, so keep both lookup paths valid.
        return Bundle.module.url(
            forResource: resourceName,
            withExtension: "png",
            subdirectory: "Logos"
        ) ?? Bundle.module.url(
            forResource: resourceName,
            withExtension: "png"
        )
    }

    public static func image(for exchange: C2CExchange) -> NSImage? {
        guard let url = url(for: exchange) else { return nil }
        return ImageCache.shared.image(for: url)
    }
}

final class ImageCache: @unchecked Sendable {
    static let shared = ImageCache()

    private let lock = NSLock()
    private var images: [URL: NSImage] = [:]

    func image(for url: URL) -> NSImage? {
        lock.lock()
        if let image = images[url] {
            lock.unlock()
            return image
        }
        lock.unlock()

        guard let image = NSImage(contentsOf: url) else {
            return nil
        }

        lock.lock()
        images[url] = image
        lock.unlock()

        return image
    }
}

private extension C2CExchange {
    var logoResourceName: String {
        switch self {
        case .binance:
            return "binance"
        case .okx:
            return "okx"
        case .htx:
            return "htx"
        case .gate:
            return "gate"
        case .mexc:
            return "mexc"
        case .bybit:
            return "bybit"
        case .bitget:
            return "bitget"
        }
    }
}
