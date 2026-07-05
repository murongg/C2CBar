import XCTest
@testable import C2CBarCore

final class AppRuntimePolicyTests: XCTestCase {
    func testSwiftRunBuildDirectoryDoesNotSupportUserNotifications() {
        let buildURL = URL(fileURLWithPath: "/example/project/.build/arm64-apple-macosx/debug/")

        XCTAssertFalse(AppRuntimePolicy.supportsUserNotifications(bundleURL: buildURL))
    }

    func testAppBundleSupportsUserNotifications() {
        let appURL = URL(fileURLWithPath: "/Applications/C2CBar.app")

        XCTAssertTrue(AppRuntimePolicy.supportsUserNotifications(bundleURL: appURL))
    }
}
