import XCTest
@testable import C2CBarCore

final class PriceAlertAuthorizationPolicyTests: XCTestCase {
    func testDoesNotPromptForAuthorizationDuringLaunchOrAutomaticDelivery() {
        XCTAssertFalse(
            PriceAlertAuthorizationPolicy.shouldPromptForAuthorization(
                context: .appLaunch,
                priceAlertsEnabled: true,
                wasPriceAlertsEnabled: true
            )
        )
        XCTAssertFalse(
            PriceAlertAuthorizationPolicy.shouldPromptForAuthorization(
                context: .automaticAlertDelivery,
                priceAlertsEnabled: true,
                wasPriceAlertsEnabled: true
            )
        )
    }

    func testPromptsOnlyWhenUserEnablesAlerts() {
        XCTAssertTrue(
            PriceAlertAuthorizationPolicy.shouldPromptForAuthorization(
                context: .userChangedSetting,
                priceAlertsEnabled: true,
                wasPriceAlertsEnabled: false
            )
        )
        XCTAssertFalse(
            PriceAlertAuthorizationPolicy.shouldPromptForAuthorization(
                context: .userChangedSetting,
                priceAlertsEnabled: true,
                wasPriceAlertsEnabled: true
            )
        )
        XCTAssertFalse(
            PriceAlertAuthorizationPolicy.shouldPromptForAuthorization(
                context: .userChangedSetting,
                priceAlertsEnabled: false,
                wasPriceAlertsEnabled: true
            )
        )
    }
}
