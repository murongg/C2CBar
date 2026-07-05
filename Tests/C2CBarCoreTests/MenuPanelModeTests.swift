import XCTest
@testable import C2CBarCore

final class MenuPanelModeTests: XCTestCase {
    func testToggleSettingsSwitchesBetweenMarketAndSettings() {
        var mode = MenuPanelMode.market

        mode.toggleSettings()
        XCTAssertEqual(mode, .settings)

        mode.toggleSettings()
        XCTAssertEqual(mode, .market)
    }

    func testPanelChromeMatchesMode() {
        XCTAssertTrue(MenuPanelMode.market.showsMarketControls)
        XCTAssertNil(MenuPanelMode.market.title)
        XCTAssertEqual(MenuPanelMode.market.trailingSystemImageName, "gearshape")

        XCTAssertFalse(MenuPanelMode.settings.showsMarketControls)
        XCTAssertEqual(MenuPanelMode.settings.title, "设置")
        XCTAssertEqual(MenuPanelMode.settings.trailingSystemImageName, "xmark")
    }
}
