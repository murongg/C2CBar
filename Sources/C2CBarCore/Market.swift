import Foundation

public enum C2CExchange: String, Codable, CaseIterable, Identifiable, Sendable {
    case binance = "Binance"
    case okx = "OKX"
    case htx = "HTX"
    case gate = "Gate"
    case mexc = "MEXC"
    case bybit = "Bybit"
    case bitget = "Bitget"

    public var id: String { rawValue }

    public static var liveSupported: [C2CExchange] {
        [.binance, .okx, .htx]
    }
}

public enum Stablecoin: String, Codable, CaseIterable, Identifiable, Sendable {
    case usdt = "USDT"
    case usdc = "USDC"

    public var id: String { rawValue }
}

public enum FiatCurrency: String, Codable, CaseIterable, Identifiable, Sendable {
    case cny = "CNY"

    public var id: String { rawValue }
}

public enum UserTradeSide: String, Codable, CaseIterable, Identifiable, Sendable {
    case buyStablecoin
    case sellStablecoin

    public var id: String { rawValue }
}

public struct C2CQuote: Identifiable, Codable, Equatable, Sendable {
    public let id: String
    public let exchange: C2CExchange
    public let asset: Stablecoin
    public let fiat: FiatCurrency
    public let side: UserTradeSide
    public let price: Decimal
    public let availableAssetAmount: Decimal?
    public let minFiatAmount: Decimal?
    public let maxFiatAmount: Decimal?
    public let merchantName: String?
    public let completedOrders: Int?
    public let completionRate: Decimal?
    public let paymentMethods: [String]
    public let updatedAt: Date

    public init(
        id: String,
        exchange: C2CExchange,
        asset: Stablecoin,
        fiat: FiatCurrency,
        side: UserTradeSide,
        price: Decimal,
        availableAssetAmount: Decimal?,
        minFiatAmount: Decimal?,
        maxFiatAmount: Decimal?,
        merchantName: String?,
        completedOrders: Int?,
        completionRate: Decimal?,
        paymentMethods: [String],
        updatedAt: Date
    ) {
        self.id = id
        self.exchange = exchange
        self.asset = asset
        self.fiat = fiat
        self.side = side
        self.price = price
        self.availableAssetAmount = availableAssetAmount
        self.minFiatAmount = minFiatAmount
        self.maxFiatAmount = maxFiatAmount
        self.merchantName = merchantName
        self.completedOrders = completedOrders
        self.completionRate = completionRate
        self.paymentMethods = paymentMethods
        self.updatedAt = updatedAt
    }

    public func isTradable(for fiatAmount: Decimal) -> Bool {
        if let minFiatAmount, fiatAmount < minFiatAmount {
            return false
        }

        if let maxFiatAmount, fiatAmount > maxFiatAmount {
            return false
        }

        return true
    }
}
