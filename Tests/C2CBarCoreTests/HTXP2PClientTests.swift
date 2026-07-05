import XCTest
@testable import C2CBarCore

final class HTXP2PClientTests: XCTestCase {
    func testDecodeMapsHTXBuyMarketToUserBuyQuote() throws {
        let json = """
        {
          "code": 200,
          "message": "Success",
          "success": true,
          "totalCount": 1,
          "pageSize": 10,
          "totalPage": 1,
          "currPage": 1,
          "data": [
            {
              "id": 1001,
              "userName": "Example HTX Seller",
              "coinId": 2,
              "currency": 172,
              "tradeType": 0,
              "payMethods": [
                { "payMethodId": 1, "name": "Bank Transfer" },
                { "payMethodId": 2, "name": "Alipay" }
              ],
              "minTradeLimit": "5000.00",
              "maxTradeLimit": "400000.00",
              "price": "6.71",
              "tradeCount": "50000.000000",
              "tradeMonthTimes": 25,
              "orderCompleteRate": "98",
              "totalTradeOrderCount": 302
            }
          ],
          "extend": []
        }
        """.data(using: .utf8)!

        let quotes = try HTXP2PClient.decodeQuotes(
            from: json,
            asset: .usdt,
            fiat: .cny,
            side: .buyStablecoin,
            receivedAt: Date(timeIntervalSince1970: 789)
        )

        XCTAssertEqual(quotes.count, 1)
        XCTAssertEqual(quotes[0].id, "htx-usdt-buyStablecoin-1001")
        XCTAssertEqual(quotes[0].exchange, .htx)
        XCTAssertEqual(quotes[0].asset, .usdt)
        XCTAssertEqual(quotes[0].fiat, .cny)
        XCTAssertEqual(quotes[0].side, .buyStablecoin)
        XCTAssertEqual(quotes[0].price, Decimal(string: "6.71"))
        XCTAssertEqual(quotes[0].availableAssetAmount, Decimal(string: "50000.000000"))
        XCTAssertEqual(quotes[0].minFiatAmount, Decimal(string: "5000.00"))
        XCTAssertEqual(quotes[0].maxFiatAmount, Decimal(string: "400000.00"))
        XCTAssertEqual(quotes[0].merchantName, "Example HTX Seller")
        XCTAssertEqual(quotes[0].completedOrders, 302)
        XCTAssertEqual(quotes[0].completionRate, Decimal(string: "98"))
        XCTAssertEqual(quotes[0].paymentMethods, ["Bank Transfer", "Alipay"])
        XCTAssertEqual(quotes[0].updatedAt, Date(timeIntervalSince1970: 789))
    }

    func testDecodeSkipsInvalidPrice() throws {
        let json = """
        {
          "code": 200,
          "message": "Success",
          "success": true,
          "data": [
            {
              "id": 1002,
              "userName": "Example HTX Merchant",
              "price": "",
              "payMethods": []
            }
          ],
          "extend": []
        }
        """.data(using: .utf8)!

        let quotes = try HTXP2PClient.decodeQuotes(
            from: json,
            asset: .usdt,
            fiat: .cny,
            side: .sellStablecoin,
            receivedAt: Date(timeIntervalSince1970: 790)
        )

        XCTAssertTrue(quotes.isEmpty)
    }
}
