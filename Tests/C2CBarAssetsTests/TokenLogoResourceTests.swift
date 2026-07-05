import C2CBarAssets
import C2CBarCore
import XCTest

final class TokenLogoResourceTests: XCTestCase {
    func testBundledLogoExistsForEverySupportedStablecoin() throws {
        for stablecoin in Stablecoin.allCases {
            let url = try XCTUnwrap(
                TokenLogoResource.url(for: stablecoin),
                "\(stablecoin.rawValue) logo should be bundled"
            )

            XCTAssertEqual(url.pathExtension.lowercased(), "png")
            XCTAssertGreaterThan(try Data(contentsOf: url).count, 0)
        }
    }

    func testBundledLogoLoadsAsImageForEverySupportedStablecoin() {
        for stablecoin in Stablecoin.allCases {
            XCTAssertNotNil(
                TokenLogoResource.image(for: stablecoin),
                "\(stablecoin.rawValue) logo should decode as an image"
            )
        }
    }
}
