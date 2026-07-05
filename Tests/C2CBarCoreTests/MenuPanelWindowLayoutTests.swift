import XCTest
@testable import C2CBarCore

final class MenuPanelWindowLayoutTests: XCTestCase {
    func testWindowSizeUsesMeasuredContentHeight() {
        let size = MenuPanelWindowLayout.windowSize(measuredContentHeight: 371.2)

        XCTAssertEqual(size.width, 392)
        XCTAssertEqual(size.height, 372)
    }

    func testResizeRequestTracksDisplayModeSizeChanges() {
        let standardMarketSize = MenuPanelWindowLayout.windowSize(measuredContentHeight: 488)
        let compactMarketSize = MenuPanelWindowLayout.windowSize(measuredContentHeight: 371.2)
        let minimalMarketSize = MenuPanelWindowLayout.windowSize(measuredContentHeight: 278)

        XCTAssertEqual(
            MenuPanelWindowResizeRequest.request(
                current: standardMarketSize,
                target: compactMarketSize
            )?.targetSize,
            compactMarketSize
        )
        XCTAssertEqual(
            MenuPanelWindowResizeRequest.request(
                current: compactMarketSize,
                target: minimalMarketSize
            )?.targetSize,
            minimalMarketSize
        )
        XCTAssertNil(
            MenuPanelWindowResizeRequest.request(
                current: minimalMarketSize,
                target: minimalMarketSize
            )
        )
    }
}
