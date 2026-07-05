import XCTest
@testable import C2CBarCore

final class MarketSnapshotTests: XCTestCase {
    func testSummaryChoosesBestUserPricesFromTradableQuotes() {
        let quotes = [
            C2CQuote(
                id: "binance-buy-expensive",
                exchange: .binance,
                asset: .usdt,
                fiat: .cny,
                side: .buyStablecoin,
                price: Decimal(string: "7.31")!,
                availableAssetAmount: Decimal(string: "1000"),
                minFiatAmount: Decimal(string: "100"),
                maxFiatAmount: Decimal(string: "20000"),
                merchantName: "Example Seller A",
                completedOrders: 120,
                completionRate: Decimal(string: "0.98"),
                paymentMethods: ["Bank"],
                updatedAt: Date(timeIntervalSince1970: 100)
            ),
            C2CQuote(
                id: "okx-buy-cheap",
                exchange: .okx,
                asset: .usdt,
                fiat: .cny,
                side: .buyStablecoin,
                price: Decimal(string: "7.25")!,
                availableAssetAmount: Decimal(string: "1000"),
                minFiatAmount: Decimal(string: "100"),
                maxFiatAmount: Decimal(string: "20000"),
                merchantName: "Example Seller B",
                completedOrders: 430,
                completionRate: Decimal(string: "0.99"),
                paymentMethods: ["Bank"],
                updatedAt: Date(timeIntervalSince1970: 101)
            ),
            C2CQuote(
                id: "binance-sell-high",
                exchange: .binance,
                asset: .usdt,
                fiat: .cny,
                side: .sellStablecoin,
                price: Decimal(string: "7.34")!,
                availableAssetAmount: Decimal(string: "1000"),
                minFiatAmount: Decimal(string: "100"),
                maxFiatAmount: Decimal(string: "20000"),
                merchantName: "Example Buyer A",
                completedOrders: 250,
                completionRate: Decimal(string: "0.97"),
                paymentMethods: ["Bank"],
                updatedAt: Date(timeIntervalSince1970: 102)
            ),
            C2CQuote(
                id: "okx-sell-low",
                exchange: .okx,
                asset: .usdt,
                fiat: .cny,
                side: .sellStablecoin,
                price: Decimal(string: "7.30")!,
                availableAssetAmount: Decimal(string: "1000"),
                minFiatAmount: Decimal(string: "100"),
                maxFiatAmount: Decimal(string: "20000"),
                merchantName: "Example Buyer B",
                completedOrders: 250,
                completionRate: Decimal(string: "0.97"),
                paymentMethods: ["Bank"],
                updatedAt: Date(timeIntervalSince1970: 103)
            )
        ]

        let snapshot = MarketSnapshot(
            asset: .usdt,
            fiat: .cny,
            referenceRate: Decimal(string: "7.197")!,
            quotes: quotes,
            transactionAmount: Decimal(string: "1000")!,
            refreshedAt: Date(timeIntervalSince1970: 110)
        )

        XCTAssertEqual(snapshot.bestBuy?.id, "okx-buy-cheap")
        XCTAssertEqual(snapshot.bestSell?.id, "binance-sell-high")
        XCTAssertEqual(snapshot.buyPremiumText, "+0.74%")
        XCTAssertEqual(snapshot.sellPremiumText, "+1.99%")
        XCTAssertEqual(snapshot.menuTitle, "USDT 入 7.250 / 出 7.340")
    }

    func testSummaryIgnoresQuotesOutsideTransactionAmount() {
        let quotes = [
            C2CQuote(
                id: "too-large-minimum",
                exchange: .binance,
                asset: .usdc,
                fiat: .cny,
                side: .buyStablecoin,
                price: Decimal(string: "7.10")!,
                availableAssetAmount: Decimal(string: "1000"),
                minFiatAmount: Decimal(string: "5000"),
                maxFiatAmount: Decimal(string: "10000"),
                merchantName: nil,
                completedOrders: nil,
                completionRate: nil,
                paymentMethods: [],
                updatedAt: Date(timeIntervalSince1970: 100)
            ),
            C2CQuote(
                id: "tradable",
                exchange: .okx,
                asset: .usdc,
                fiat: .cny,
                side: .buyStablecoin,
                price: Decimal(string: "7.20")!,
                availableAssetAmount: Decimal(string: "1000"),
                minFiatAmount: Decimal(string: "100"),
                maxFiatAmount: Decimal(string: "2000"),
                merchantName: nil,
                completedOrders: nil,
                completionRate: nil,
                paymentMethods: [],
                updatedAt: Date(timeIntervalSince1970: 100)
            )
        ]

        let snapshot = MarketSnapshot(
            asset: .usdc,
            fiat: .cny,
            referenceRate: Decimal(string: "7.197")!,
            quotes: quotes,
            transactionAmount: Decimal(string: "1000")!,
            refreshedAt: Date(timeIntervalSince1970: 110)
        )

        XCTAssertEqual(snapshot.bestBuy?.id, "tradable")
    }

    func testPlatformRowsOnlyIncludeSupportedLiveExchanges() {
        let quotes = [
            C2CQuote(
                id: "binance-buy",
                exchange: .binance,
                asset: .usdc,
                fiat: .cny,
                side: .buyStablecoin,
                price: Decimal(string: "7.26")!,
                availableAssetAmount: Decimal(string: "1000"),
                minFiatAmount: Decimal(string: "100"),
                maxFiatAmount: Decimal(string: "2000"),
                merchantName: nil,
                completedOrders: nil,
                completionRate: nil,
                paymentMethods: [],
                updatedAt: Date(timeIntervalSince1970: 100)
            ),
            C2CQuote(
                id: "okx-sell",
                exchange: .okx,
                asset: .usdc,
                fiat: .cny,
                side: .sellStablecoin,
                price: Decimal(string: "7.32")!,
                availableAssetAmount: Decimal(string: "1000"),
                minFiatAmount: Decimal(string: "100"),
                maxFiatAmount: Decimal(string: "2000"),
                merchantName: nil,
                completedOrders: nil,
                completionRate: nil,
                paymentMethods: [],
                updatedAt: Date(timeIntervalSince1970: 101)
            )
        ]

        let snapshot = MarketSnapshot(
            asset: .usdc,
            fiat: .cny,
            referenceRate: Decimal(string: "7.197")!,
            quotes: quotes,
            transactionAmount: Decimal(string: "1000")!,
            refreshedAt: Date(timeIntervalSince1970: 110)
        )

        let rows = snapshot.platformRows(limit: 5)

        XCTAssertEqual(rows.map(\.exchange), [.binance, .okx])
        XCTAssertEqual(rows.count, 2)
        XCTAssertEqual(rows[0].buy?.id, "binance-buy")
        XCTAssertNil(rows[0].sell)
    }

    func testPlatformRowsRespectVisibleExchangeFilter() {
        let quotes = [
            C2CQuote(
                id: "binance-buy",
                exchange: .binance,
                asset: .usdt,
                fiat: .cny,
                side: .buyStablecoin,
                price: Decimal(string: "7.25")!,
                availableAssetAmount: Decimal(string: "1000"),
                minFiatAmount: Decimal(string: "100"),
                maxFiatAmount: Decimal(string: "2000"),
                merchantName: nil,
                completedOrders: nil,
                completionRate: nil,
                paymentMethods: [],
                updatedAt: Date(timeIntervalSince1970: 100)
            ),
            C2CQuote(
                id: "okx-buy",
                exchange: .okx,
                asset: .usdt,
                fiat: .cny,
                side: .buyStablecoin,
                price: Decimal(string: "7.24")!,
                availableAssetAmount: Decimal(string: "1000"),
                minFiatAmount: Decimal(string: "100"),
                maxFiatAmount: Decimal(string: "2000"),
                merchantName: nil,
                completedOrders: nil,
                completionRate: nil,
                paymentMethods: [],
                updatedAt: Date(timeIntervalSince1970: 101)
            ),
            C2CQuote(
                id: "htx-buy",
                exchange: .htx,
                asset: .usdt,
                fiat: .cny,
                side: .buyStablecoin,
                price: Decimal(string: "7.26")!,
                availableAssetAmount: Decimal(string: "1000"),
                minFiatAmount: Decimal(string: "100"),
                maxFiatAmount: Decimal(string: "2000"),
                merchantName: nil,
                completedOrders: nil,
                completionRate: nil,
                paymentMethods: [],
                updatedAt: Date(timeIntervalSince1970: 102)
            )
        ]

        let snapshot = MarketSnapshot(
            asset: .usdt,
            fiat: .cny,
            referenceRate: Decimal(string: "7.197")!,
            quotes: quotes,
            transactionAmount: Decimal(string: "1000")!,
            refreshedAt: Date(timeIntervalSince1970: 110)
        )

        let rows = snapshot.platformRows(limit: 5, visibleExchanges: [.binance, .htx])

        XCTAssertEqual(rows.map(\.exchange), [.binance, .htx])
        XCTAssertEqual(rows.map { $0.buy?.id }, ["binance-buy", "htx-buy"])
    }

    func testPlatformRowCapacityKeepsStableHeightAcrossAssets() {
        let snapshot = MarketSnapshot(
            asset: .usdc,
            fiat: .cny,
            referenceRate: Decimal(string: "7.197")!,
            quotes: [],
            transactionAmount: Decimal(string: "1000")!,
            refreshedAt: Date(timeIntervalSince1970: 110)
        )

        XCTAssertEqual(snapshot.platformRows(limit: 5).count, 2)
        XCTAssertEqual(snapshot.platformRowCapacity(limit: 5), 3)
    }

    func testPlatformRowCapacityTracksVisibleExchanges() {
        let snapshot = MarketSnapshot(
            asset: .usdt,
            fiat: .cny,
            referenceRate: Decimal(string: "7.197")!,
            quotes: [],
            transactionAmount: Decimal(string: "1000")!,
            refreshedAt: Date(timeIntervalSince1970: 110)
        )

        XCTAssertEqual(
            snapshot.platformRowCapacity(limit: 5, visibleExchanges: [.okx]),
            1
        )
    }
}
