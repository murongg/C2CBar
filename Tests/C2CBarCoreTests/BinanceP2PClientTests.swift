import XCTest
@testable import C2CBarCore

final class BinanceP2PClientTests: XCTestCase {
    func testDecodeMapsBinanceAdvertisementToUserBuyQuote() throws {
        let json = """
        {
          "code": "000000",
          "data": [
            {
              "adv": {
                "advNo": "adv-1",
                "asset": "USDT",
                "fiatUnit": "CNY",
                "price": "7.259",
                "tradableQuantity": "1000.5",
                "minSingleTransAmount": "500",
                "maxSingleTransAmount": "50000",
                "tradeMethods": [
                  { "tradeMethodName": "Bank Transfer" },
                  { "tradeMethodName": "Alipay" }
                ]
              },
              "advertiser": {
                "nickName": "Example Merchant"
              }
            }
          ]
        }
        """.data(using: .utf8)!

        let quotes = try BinanceP2PClient.decodeQuotes(
            from: json,
            asset: .usdt,
            fiat: .cny,
            side: .buyStablecoin,
            receivedAt: Date(timeIntervalSince1970: 123)
        )

        XCTAssertEqual(quotes.count, 1)
        XCTAssertEqual(quotes[0].id, "binance-usdt-buyStablecoin-adv-1")
        XCTAssertEqual(quotes[0].exchange, .binance)
        XCTAssertEqual(quotes[0].asset, .usdt)
        XCTAssertEqual(quotes[0].fiat, .cny)
        XCTAssertEqual(quotes[0].side, .buyStablecoin)
        XCTAssertEqual(quotes[0].price, Decimal(string: "7.259"))
        XCTAssertEqual(quotes[0].availableAssetAmount, Decimal(string: "1000.5"))
        XCTAssertEqual(quotes[0].minFiatAmount, Decimal(string: "500"))
        XCTAssertEqual(quotes[0].maxFiatAmount, Decimal(string: "50000"))
        XCTAssertEqual(quotes[0].merchantName, "Example Merchant")
        XCTAssertEqual(quotes[0].paymentMethods, ["Bank Transfer", "Alipay"])
        XCTAssertEqual(quotes[0].updatedAt, Date(timeIntervalSince1970: 123))
    }

    func testDecodeSkipsAdvertisementsWithInvalidPrice() throws {
        let json = """
        {
          "code": "000000",
          "data": [
            {
              "adv": {
                "advNo": "bad-price",
                "asset": "USDT",
                "fiatUnit": "CNY",
                "price": "",
                "tradableQuantity": "1000",
                "minSingleTransAmount": "500",
                "maxSingleTransAmount": "50000",
                "tradeMethods": []
              },
              "advertiser": { "nickName": "Example Merchant" }
            }
          ]
        }
        """.data(using: .utf8)!

        let quotes = try BinanceP2PClient.decodeQuotes(
            from: json,
            asset: .usdt,
            fiat: .cny,
            side: .buyStablecoin,
            receivedAt: Date(timeIntervalSince1970: 123)
        )

        XCTAssertTrue(quotes.isEmpty)
    }
}
