import XCTest

@testable import EasySwipe

final class WindowCompatibilityProfileTests: XCTestCase {
    private let interactiveRoles: Set<String> = ["AXButton", "AXTextField", "AXToolbar"]

    func testWarpAllowsToolbarContainerButStillRejectsControls() {
        let profile = WindowCompatibilityProfile(bundleIdentifier: "dev.warp.Warp-Stable")

        XCTAssertTrue(profile.allowsToolbarContainer)
        XCTAssertEqual(profile.minimumTitlebarHeight, 56)
        XCTAssertFalse(profile.rejects(role: "AXToolbar", interactiveRoles: interactiveRoles))
        XCTAssertTrue(profile.rejects(role: "AXButton", interactiveRoles: interactiveRoles))
        XCTAssertTrue(profile.rejects(role: "AXTextField", interactiveRoles: interactiveRoles))
    }

    func testWarpUpdateAndPreviewBundleIdentifiersUseCompatibilityProfile() {
        XCTAssertTrue(
            WindowCompatibilityProfile(bundleIdentifier: "dev.warp.Warp-Stable.ShipIt")
                .allowsToolbarContainer
        )
        XCTAssertTrue(
            WindowCompatibilityProfile(bundleIdentifier: "dev.warp.Warp-Preview")
                .allowsToolbarContainer
        )
    }

    func testOtherApplicationsKeepStrictToolbarFiltering() {
        let profile = WindowCompatibilityProfile(bundleIdentifier: "com.apple.Safari")

        XCTAssertFalse(profile.allowsToolbarContainer)
        XCTAssertEqual(profile.minimumTitlebarHeight, 38)
        XCTAssertTrue(profile.rejects(role: "AXToolbar", interactiveRoles: interactiveRoles))
    }
}
