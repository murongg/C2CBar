import XCTest
@testable import C2CBarCore

final class FormattingTests: XCTestCase {
    func testPremiumIndicatorMarksPricesAboveAndBelowReference() {
        let above = StableFormat.premiumIndicator(
            price: Decimal(string: "7.20")!,
            referenceRate: Decimal(string: "7.10")!
        )
        let below = StableFormat.premiumIndicator(
            price: Decimal(string: "7.00")!,
            referenceRate: Decimal(string: "7.10")!
        )
        let even = StableFormat.premiumIndicator(
            price: Decimal(string: "7.10")!,
            referenceRate: Decimal(string: "7.10")!
        )

        XCTAssertEqual(above.direction, .aboveReference)
        XCTAssertEqual(above.systemImageName, "arrow.up.right")
        XCTAssertEqual(above.shortText, "高 +1.41%")
        XCTAssertEqual(below.direction, .belowReference)
        XCTAssertEqual(below.systemImageName, "arrow.down.right")
        XCTAssertEqual(below.shortText, "低 -1.41%")
        XCTAssertEqual(even.direction, .atReference)
        XCTAssertEqual(even.systemImageName, "minus")
        XCTAssertEqual(even.shortText, "平 0.00%")
    }
}
