import XCTest
@testable import C2CBarCore

final class MenuPanelContentPolicyTests: XCTestCase {
    func testCompactDoesNotReserveHiddenPlatformRows() {
        XCTAssertTrue(MenuPanelContentPolicy(displayMode: .standard).reservesPlatformRows)
        XCTAssertFalse(MenuPanelContentPolicy(displayMode: .compact).reservesPlatformRows)
    }

    func testMinimalOmitsPlatformTableButKeepsReferenceAndFooter() {
        let policy = MenuPanelContentPolicy(displayMode: .minimal)

        XCTAssertTrue(policy.showsReferenceRate)
        XCTAssertFalse(policy.showsPlatformTable)
        XCTAssertFalse(policy.showsAlertPreview)
        XCTAssertTrue(policy.showsFooter)
    }
}
