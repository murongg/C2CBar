import XCTest
@testable import C2CBarCore

final class MarketPreferencesStorageTests: XCTestCase {
    func testLoadReturnsDefaultsWhenNoPreferencesWereSaved() {
        let userDefaults = makeUserDefaults()
        let storage = UserDefaultsMarketPreferencesStorage(userDefaults: userDefaults)

        XCTAssertEqual(storage.load(), .default)
    }

    func testSaveAndLoadRoundTripsPreferences() {
        let userDefaults = makeUserDefaults()
        let storage = UserDefaultsMarketPreferencesStorage(userDefaults: userDefaults)
        let preferences = MarketPreferences(
            selectedAsset: .usdc,
            displayMode: .minimal,
            transactionAmount: Decimal(5_000),
            refreshIntervalSeconds: 900,
            showUSDT: false,
            showUSDC: true,
            referenceSource: .ecb,
            fiat: .cny,
            visibleExchanges: [.binance, .htx]
        )

        storage.save(preferences)

        XCTAssertEqual(storage.load(), preferences)
    }

    private func makeUserDefaults() -> UserDefaults {
        let suiteName = "C2CBarTests.\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        userDefaults.removePersistentDomain(forName: suiteName)
        return userDefaults
    }
}
