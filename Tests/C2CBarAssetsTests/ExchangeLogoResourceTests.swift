import C2CBarAssets
import C2CBarCore
import XCTest

final class ExchangeLogoResourceTests: XCTestCase {
    func testBundledLogoExistsForEverySupportedExchange() throws {
        for exchange in C2CExchange.allCases {
            let url = try XCTUnwrap(
                ExchangeLogoResource.url(for: exchange),
                "\(exchange.rawValue) logo should be bundled"
            )

            XCTAssertEqual(url.pathExtension.lowercased(), "png")
            XCTAssertGreaterThan(try Data(contentsOf: url).count, 0)
        }
    }

    func testBundledLogoLoadsAsImageForEverySupportedExchange() {
        for exchange in C2CExchange.allCases {
            XCTAssertNotNil(
                ExchangeLogoResource.image(for: exchange),
                "\(exchange.rawValue) logo should decode as an image"
            )
        }
    }
}
