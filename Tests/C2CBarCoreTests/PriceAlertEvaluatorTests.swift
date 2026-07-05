import XCTest
@testable import C2CBarCore

final class PriceAlertEvaluatorTests: XCTestCase {
    func testEvaluatesSellPremiumAlertWhenBestSellExceedsThreshold() {
        var evaluator = PriceAlertEvaluator()
        let snapshot = makeSnapshot(
            referenceRate: Decimal(string: "7.00")!,
            quotes: [
                makeQuote(
                    id: "binance-sell",
                    exchange: .binance,
                    side: .sellStablecoin,
                    price: Decimal(string: "7.15")!
                )
            ]
        )

        let events = evaluator.evaluate(snapshot: snapshot, now: Date(timeIntervalSince1970: 100))

        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events[0].kind, .sellPremiumAboveThreshold)
        XCTAssertEqual(events[0].title, "USDT 出金溢价超过 2%")
        XCTAssertEqual(events[0].body, "Binance 出金 7.150，高于基准 +2.14%")
    }

    func testEvaluatesBuyPriceAlertWhenBestBuyFallsBelowThreshold() {
        var evaluator = PriceAlertEvaluator()
        let snapshot = makeSnapshot(
            referenceRate: Decimal(string: "7.20")!,
            quotes: [
                makeQuote(
                    id: "okx-buy",
                    exchange: .okx,
                    side: .buyStablecoin,
                    price: Decimal(string: "7.24")!
                )
            ]
        )

        let events = evaluator.evaluate(snapshot: snapshot, now: Date(timeIntervalSince1970: 100))

        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events[0].kind, .buyPriceBelowThreshold)
        XCTAssertEqual(events[0].title, "OKX 入金低于 7.25")
        XCTAssertEqual(events[0].body, "USDT 入金 7.240，低于提醒价 7.250")
    }

    func testSuppressesDuplicateAlertsInsideCooldown() {
        var evaluator = PriceAlertEvaluator(
            rules: .default,
            cooldown: 1_800
        )
        let snapshot = makeSnapshot(
            referenceRate: Decimal(string: "7.00")!,
            quotes: [
                makeQuote(
                    id: "binance-sell",
                    exchange: .binance,
                    side: .sellStablecoin,
                    price: Decimal(string: "7.15")!
                )
            ]
        )

        let first = evaluator.evaluate(snapshot: snapshot, now: Date(timeIntervalSince1970: 100))
        let duplicate = evaluator.evaluate(snapshot: snapshot, now: Date(timeIntervalSince1970: 200))
        let afterCooldown = evaluator.evaluate(snapshot: snapshot, now: Date(timeIntervalSince1970: 2_000))

        XCTAssertEqual(first.count, 1)
        XCTAssertTrue(duplicate.isEmpty)
        XCTAssertEqual(afterCooldown.count, 1)
    }

    private func makeSnapshot(
        referenceRate: Decimal,
        quotes: [C2CQuote]
    ) -> MarketSnapshot {
        MarketSnapshot(
            asset: .usdt,
            fiat: .cny,
            referenceRate: referenceRate,
            quotes: quotes,
            transactionAmount: Decimal(1_000),
            refreshedAt: Date(timeIntervalSince1970: 100)
        )
    }

    private func makeQuote(
        id: String,
        exchange: C2CExchange,
        side: UserTradeSide,
        price: Decimal
    ) -> C2CQuote {
        C2CQuote(
            id: id,
            exchange: exchange,
            asset: .usdt,
            fiat: .cny,
            side: side,
            price: price,
            availableAssetAmount: Decimal(1_000),
            minFiatAmount: Decimal(100),
            maxFiatAmount: Decimal(2_000),
            merchantName: "Example Merchant",
            completedOrders: 100,
            completionRate: Decimal(string: "0.99"),
            paymentMethods: ["Bank"],
            updatedAt: Date(timeIntervalSince1970: 100)
        )
    }
}
