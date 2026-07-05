import XCTest
@testable import C2CBarCore

final class MarketPreferencesTests: XCTestCase {
    func testDefaultsUseFifteenMinuteRefreshAndSupportedExchanges() {
        let preferences = MarketPreferences.default

        XCTAssertEqual(preferences.refreshIntervalSeconds, 900)
        XCTAssertEqual(preferences.visibleExchanges, [.binance, .okx, .htx])
    }

    func testCodableRoundTripPreservesUserSettings() throws {
        let preferences = MarketPreferences(
            selectedAsset: .usdc,
            displayMode: .compact,
            transactionAmount: Decimal(2_000),
            refreshIntervalSeconds: 1_800,
            showUSDT: true,
            showUSDC: false,
            startAtLogin: false,
            priceAlertsEnabled: true,
            referenceSource: .wise,
            fiat: .cny,
            visibleExchanges: [.okx]
        )

        let data = try JSONEncoder().encode(preferences)
        let decoded = try JSONDecoder().decode(MarketPreferences.self, from: data)

        XCTAssertEqual(decoded, preferences)
    }
}
