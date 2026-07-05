import XCTest
@testable import C2CBarCore

final class SettingsPanelLayoutTests: XCTestCase {
    func testControlColumnCanRightAlignAllSettingControls() {
        XCTAssertEqual(SettingsPanelLayout.labelWidth, 92)
        XCTAssertEqual(SettingsPanelLayout.menuControlWidth, 178)
        XCTAssertEqual(SettingsPanelLayout.controlColumnWidth, 206)
        XCTAssertGreaterThan(SettingsPanelLayout.controlColumnWidth, SettingsPanelLayout.menuControlWidth)
    }
}
