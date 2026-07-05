import Foundation

public struct MarketSnapshot: Equatable, Sendable {
    public let asset: Stablecoin
    public let fiat: FiatCurrency
    public let referenceRate: Decimal
    public let quotes: [C2CQuote]
    public let transactionAmount: Decimal
    public let refreshedAt: Date

    public init(
        asset: Stablecoin,
        fiat: FiatCurrency,
        referenceRate: Decimal,
        quotes: [C2CQuote],
        transactionAmount: Decimal,
        refreshedAt: Date
    ) {
        self.asset = asset
        self.fiat = fiat
        self.referenceRate = referenceRate
        self.quotes = quotes
        self.transactionAmount = transactionAmount
        self.refreshedAt = refreshedAt
    }

    public var bestBuy: C2CQuote? {
        tradableQuotes(side: .buyStablecoin).min { lhs, rhs in
            lhs.price < rhs.price
        }
    }

    public var bestSell: C2CQuote? {
        tradableQuotes(side: .sellStablecoin).max { lhs, rhs in
            lhs.price < rhs.price
        }
    }

    public var buyPremiumText: String {
        guard let bestBuy else { return "--" }
        return StableFormat.premiumText(price: bestBuy.price, referenceRate: referenceRate)
    }

    public var sellPremiumText: String {
        guard let bestSell else { return "--" }
        return StableFormat.premiumText(price: bestSell.price, referenceRate: referenceRate)
    }

    public var menuTitle: String {
        let buyText = bestBuy.map { StableFormat.price($0.price) } ?? "--"
        let sellText = bestSell.map { StableFormat.price($0.price) } ?? "--"
        return "\(asset.rawValue) 入 \(buyText) / 出 \(sellText)"
    }

    public func tradableQuotes(side: UserTradeSide) -> [C2CQuote] {
        quotes
            .filter { quote in
                quote.asset == asset
                    && quote.fiat == fiat
                    && quote.side == side
                    && quote.isTradable(for: transactionAmount)
            }
            .sorted { lhs, rhs in
                switch side {
                case .buyStablecoin:
                    lhs.price < rhs.price
                case .sellStablecoin:
                    lhs.price > rhs.price
                }
            }
    }

    public func platformRows(
        limit: Int,
        visibleExchanges: [C2CExchange]? = nil
    ) -> [PlatformQuoteRow] {
        let buyQuotes = tradableQuotes(side: .buyStablecoin)
        let sellQuotes = tradableQuotes(side: .sellStablecoin)

        return C2CExchange.displayOrder(for: asset, visibleExchanges: visibleExchanges)
            .prefix(max(0, limit))
            .map { exchange in
                PlatformQuoteRow(
                    exchange: exchange,
                    buy: buyQuotes.first { $0.exchange == exchange },
                    sell: sellQuotes.first { $0.exchange == exchange }
                )
            }
    }

    public func platformRowCapacity(
        limit: Int,
        visibleExchanges: [C2CExchange]? = nil
    ) -> Int {
        min(max(0, limit), C2CExchange.maximumDisplayCount(visibleExchanges: visibleExchanges))
    }
}

public struct PlatformQuoteRow: Equatable, Sendable {
    public let exchange: C2CExchange
    public let buy: C2CQuote?
    public let sell: C2CQuote?

    public init(exchange: C2CExchange, buy: C2CQuote?, sell: C2CQuote?) {
        self.exchange = exchange
        self.buy = buy
        self.sell = sell
    }
}

private extension C2CExchange {
    static func maximumDisplayCount(visibleExchanges: [C2CExchange]?) -> Int {
        Stablecoin.allCases
            .map { displayOrder(for: $0, visibleExchanges: visibleExchanges).count }
            .max() ?? 0
    }

    static func displayOrder(
        for asset: Stablecoin,
        visibleExchanges: [C2CExchange]?
    ) -> [C2CExchange] {
        let supported: [C2CExchange] = switch asset {
        case .usdt:
            [.binance, .okx, .htx]
        case .usdc:
            [.binance, .okx]
        }

        guard let visibleExchanges else {
            return supported
        }

        return supported.filter { visibleExchanges.contains($0) }
    }
}
