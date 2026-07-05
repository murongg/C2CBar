import XCTest
@testable import C2CBarCore

final class ReferenceRateClientTests: XCTestCase {
    func testDecodeMapsWiseLiveRate() throws {
        let json = """
        {
          "source": "USD",
          "target": "CNY",
          "value": 7.1234,
          "time": 1700000000000
        }
        """.data(using: .utf8)!

        let rate = try ReferenceRateClient.decodeWiseRate(
            from: json,
            fiat: .cny,
            fetchedAt: Date(timeIntervalSince1970: 1700000001)
        )

        XCTAssertEqual(rate.baseCurrencyCode, "USD")
        XCTAssertEqual(rate.fiat, .cny)
        XCTAssertEqual(rate.rate, Decimal(string: "7.1234"))
        XCTAssertEqual(rate.source, .wise)
        XCTAssertEqual(rate.sourceDateText, "2023-11-14")
        XCTAssertEqual(rate.fetchedAt, Date(timeIntervalSince1970: 1700000001))
    }

    func testDecodeMapsECBReferenceRate() throws {
        let json = """
        {
          "date": "2026-01-02",
          "base": "USD",
          "quote": "CNY",
          "rate": 7.2345
        }
        """.data(using: .utf8)!

        let rate = try ReferenceRateClient.decodeFrankfurterRate(
            from: json,
            fiat: .cny,
            fetchedAt: Date(timeIntervalSince1970: 1700000002)
        )

        XCTAssertEqual(rate.baseCurrencyCode, "USD")
        XCTAssertEqual(rate.fiat, .cny)
        XCTAssertEqual(rate.rate, Decimal(string: "7.2345"))
        XCTAssertEqual(rate.source, .ecb)
        XCTAssertEqual(rate.sourceDateText, "2026-01-02")
        XCTAssertEqual(rate.fetchedAt, Date(timeIntervalSince1970: 1700000002))
    }

    func testDecodeRejectsUnexpectedCurrencyPair() throws {
        let json = """
        {
          "source": "EUR",
          "target": "CNY",
          "value": 7.1234,
          "time": 1700000000000
        }
        """.data(using: .utf8)!

        XCTAssertThrowsError(
            try ReferenceRateClient.decodeWiseRate(
                from: json,
                fiat: .cny,
                fetchedAt: Date(timeIntervalSince1970: 1700000001)
            )
        ) { error in
            XCTAssertEqual(error as? ReferenceRateClient.Error, .unexpectedCurrencyPair)
        }
    }
}
