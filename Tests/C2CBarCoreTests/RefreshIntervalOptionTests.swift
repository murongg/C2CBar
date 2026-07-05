import XCTest
@testable import C2CBarCore

final class RefreshIntervalOptionTests: XCTestCase {
    func testSupportedOptionsUseLowFrequencyRefreshCadence() {
        XCTAssertEqual(
            RefreshIntervalOption.allCases.map(\.seconds),
            [60, 900, 1_800, 3_600]
        )
    }

    func testDisplayNamesMatchSettingsMenuLabels() {
        XCTAssertEqual(
            RefreshIntervalOption.allCases.map(\.displayName),
            ["1 分钟", "15 分钟", "30 分钟", "1 小时"]
        )
    }
}
