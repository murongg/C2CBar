import XCTest
@testable import C2CBarCore

final class SegmentedHitTargetLayoutTests: XCTestCase {
    func testSegmentWidthFillsAvailableControlWidth() {
        let width = SegmentedHitTargetLayout.segmentWidth(
            containerWidth: 180,
            itemCount: 2,
            spacing: 3,
            horizontalPadding: 3
        )

        XCTAssertEqual(width, 85.5, accuracy: 0.001)
    }

    func testSegmentWidthHandlesEmptyItems() {
        let width = SegmentedHitTargetLayout.segmentWidth(
            containerWidth: 180,
            itemCount: 0,
            spacing: 3,
            horizontalPadding: 3
        )

        XCTAssertEqual(width, 0)
    }

    func testSegmentWidthRejectsUnboundedContainerWidth() {
        let width = SegmentedHitTargetLayout.segmentWidth(
            containerWidth: .infinity,
            itemCount: 2,
            spacing: 3,
            horizontalPadding: 3
        )

        XCTAssertEqual(width, 0)
    }
}
