import Foundation

public enum MockMarket {
    public static let referenceRate = Decimal(string: "7.197")!

    public static let refreshedAt = Date(timeIntervalSince1970: 1_783_205_600)

    public static let quotes: [C2CQuote] = [
        .mock(
            id: "binance-usdt-buy",
            exchange: .binance,
            asset: .usdt,
            side: .buyStablecoin,
            price: "7.259",
            minFiat: "500",
            maxFiat: "50000",
            merchant: "Alpha Desk",
            completedOrders: 18240,
            completionRate: "0.993",
            payments: ["Bank", "Alipay"]
        ),
        .mock(
            id: "okx-usdt-buy",
            exchange: .okx,
            asset: .usdt,
            side: .buyStablecoin,
            price: "7.261",
            minFiat: "1000",
            maxFiat: "80000",
            merchant: "North Bridge",
            completedOrders: 8887,
            completionRate: "0.996",
            payments: ["Bank"]
        ),
        .mock(
            id: "bybit-usdt-buy",
            exchange: .bybit,
            asset: .usdt,
            side: .buyStablecoin,
            price: "7.256",
            minFiat: "100",
            maxFiat: "20000",
            merchant: "River Pay",
            completedOrders: 4210,
            completionRate: "0.982",
            payments: ["Bank", "WeChat"]
        ),
        .mock(
            id: "gate-usdt-buy",
            exchange: .gate,
            asset: .usdt,
            side: .buyStablecoin,
            price: "7.258",
            minFiat: "300",
            maxFiat: "30000",
            merchant: "Gate Maker",
            completedOrders: 3201,
            completionRate: "0.988",
            payments: ["Bank"]
        ),
        .mock(
            id: "binance-usdt-sell",
            exchange: .binance,
            asset: .usdt,
            side: .sellStablecoin,
            price: "7.336",
            minFiat: "500",
            maxFiat: "100000",
            merchant: "Amber Desk",
            completedOrders: 184820,
            completionRate: "0.999",
            payments: ["Bank"]
        ),
        .mock(
            id: "okx-usdt-sell",
            exchange: .okx,
            asset: .usdt,
            side: .sellStablecoin,
            price: "7.330",
            minFiat: "1000",
            maxFiat: "50000",
            merchant: "Harbor Trade",
            completedOrders: 12940,
            completionRate: "0.994",
            payments: ["Bank", "Alipay"]
        ),
        .mock(
            id: "bybit-usdt-sell",
            exchange: .bybit,
            asset: .usdt,
            side: .sellStablecoin,
            price: "7.321",
            minFiat: "100",
            maxFiat: "25000",
            merchant: "Mint House",
            completedOrders: 7432,
            completionRate: "0.987",
            payments: ["Bank"]
        ),
        .mock(
            id: "gate-usdt-sell",
            exchange: .gate,
            asset: .usdt,
            side: .sellStablecoin,
            price: "7.326",
            minFiat: "300",
            maxFiat: "40000",
            merchant: "Blue Atlas",
            completedOrders: 5421,
            completionRate: "0.989",
            payments: ["Bank"]
        ),
        .mock(
            id: "binance-usdc-buy",
            exchange: .binance,
            asset: .usdc,
            side: .buyStablecoin,
            price: "7.268",
            minFiat: "500",
            maxFiat: "50000",
            merchant: "Circle Desk",
            completedOrders: 6021,
            completionRate: "0.992",
            payments: ["Bank"]
        ),
        .mock(
            id: "okx-usdc-buy",
            exchange: .okx,
            asset: .usdc,
            side: .buyStablecoin,
            price: "7.263",
            minFiat: "1000",
            maxFiat: "45000",
            merchant: "Union Maker",
            completedOrders: 2180,
            completionRate: "0.984",
            payments: ["Bank", "Alipay"]
        ),
        .mock(
            id: "binance-usdc-sell",
            exchange: .binance,
            asset: .usdc,
            side: .sellStablecoin,
            price: "7.329",
            minFiat: "500",
            maxFiat: "80000",
            merchant: "Nova Desk",
            completedOrders: 7310,
            completionRate: "0.991",
            payments: ["Bank"]
        ),
        .mock(
            id: "okx-usdc-sell",
            exchange: .okx,
            asset: .usdc,
            side: .sellStablecoin,
            price: "7.324",
            minFiat: "1000",
            maxFiat: "35000",
            merchant: "USDC Bridge",
            completedOrders: 1842,
            completionRate: "0.979",
            payments: ["Bank"]
        )
    ]
}

private extension C2CQuote {
    static func mock(
        id: String,
        exchange: C2CExchange,
        asset: Stablecoin,
        side: UserTradeSide,
        price: String,
        minFiat: String,
        maxFiat: String,
        merchant: String,
        completedOrders: Int,
        completionRate: String,
        payments: [String]
    ) -> C2CQuote {
        C2CQuote(
            id: id,
            exchange: exchange,
            asset: asset,
            fiat: .cny,
            side: side,
            price: Decimal(string: price)!,
            availableAssetAmount: Decimal(string: "10000"),
            minFiatAmount: Decimal(string: minFiat),
            maxFiatAmount: Decimal(string: maxFiat),
            merchantName: merchant,
            completedOrders: completedOrders,
            completionRate: Decimal(string: completionRate),
            paymentMethods: payments,
            updatedAt: refreshedDate(for: id)
        )
    }

    static func refreshedDate(for id: String) -> Date {
        Date(timeIntervalSince1970: 1_783_205_600 + TimeInterval(abs(id.hashValue % 240)))
    }
}
