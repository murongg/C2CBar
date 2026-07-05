import XCTest
@testable import C2CBarCore

final class OKXP2PClientTests: XCTestCase {
    func testDecodeMapsOKXSellBookToUserBuyQuote() throws {
        let json = """
        {
          "code": 0,
          "data": {
            "buy": [],
            "sell": [
              {
                "id": "okx-ad-1",
                "availableAmount": "15277.40",
                "baseCurrency": "usdt",
                "completedOrderQuantity": 184985,
                "completedRate": "0.9999",
                "nickName": "Example OKX Merchant",
                "paymentMethods": ["aliPay", "bank"],
                "price": "7.261",
                "quoteCurrency": "cny",
                "quoteMaxAmountPerOrder": "19999.00",
                "quoteMinAmountPerOrder": "2999.00",
                "side": "sell"
              }
            ]
          }
        }
        """.data(using: .utf8)!

        let quotes = try OKXP2PClient.decodeQuotes(
            from: json,
            asset: .usdt,
            fiat: .cny,
            side: .buyStablecoin,
            receivedAt: Date(timeIntervalSince1970: 456)
        )

        XCTAssertEqual(quotes.count, 1)
        XCTAssertEqual(quotes[0].id, "okx-usdt-buyStablecoin-okx-ad-1")
        XCTAssertEqual(quotes[0].exchange, .okx)
        XCTAssertEqual(quotes[0].asset, .usdt)
        XCTAssertEqual(quotes[0].fiat, .cny)
        XCTAssertEqual(quotes[0].side, .buyStablecoin)
        XCTAssertEqual(quotes[0].price, Decimal(string: "7.261"))
        XCTAssertEqual(quotes[0].availableAssetAmount, Decimal(string: "15277.40"))
        XCTAssertEqual(quotes[0].minFiatAmount, Decimal(string: "2999.00"))
        XCTAssertEqual(quotes[0].maxFiatAmount, Decimal(string: "19999.00"))
        XCTAssertEqual(quotes[0].merchantName, "Example OKX Merchant")
        XCTAssertEqual(quotes[0].completedOrders, 184985)
        XCTAssertEqual(quotes[0].completionRate, Decimal(string: "0.9999"))
        XCTAssertEqual(quotes[0].paymentMethods, ["aliPay", "bank"])
        XCTAssertEqual(quotes[0].updatedAt, Date(timeIntervalSince1970: 456))
    }

    func testDecodeUsesBuyBookForUserSellQuote() throws {
        let json = """
        {
          "code": 0,
          "data": {
            "buy": [
              {
                "id": "okx-ad-2",
                "availableAmount": "10000.00",
                "baseCurrency": "usdc",
                "completedOrderQuantity": 10,
                "completedRate": "0.9500",
                "nickName": "Example Buyer",
                "paymentMethods": ["bank"],
                "price": "7.330",
                "quoteCurrency": "cny",
                "quoteMaxAmountPerOrder": "30000.00",
                "quoteMinAmountPerOrder": "1000.00",
                "side": "buy"
              }
            ],
            "sell": []
          }
        }
        """.data(using: .utf8)!

        let quotes = try OKXP2PClient.decodeQuotes(
            from: json,
            asset: .usdc,
            fiat: .cny,
            side: .sellStablecoin,
            receivedAt: Date(timeIntervalSince1970: 457)
        )

        XCTAssertEqual(quotes.count, 1)
        XCTAssertEqual(quotes[0].id, "okx-usdc-sellStablecoin-okx-ad-2")
        XCTAssertEqual(quotes[0].side, .sellStablecoin)
        XCTAssertEqual(quotes[0].price, Decimal(string: "7.330"))
    }
}
