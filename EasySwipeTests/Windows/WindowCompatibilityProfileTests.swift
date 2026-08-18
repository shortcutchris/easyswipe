import XCTest

@testable import EasySwipe

final class WindowCompatibilityProfileTests: XCTestCase {
    private let interactiveRoles: Set<String> = [
        "AXButton", "AXScrollArea", "AXTab", "AXTabGroup", "AXTextArea", "AXTextField",
        "AXToolbar",
    ]

    func testWarpAllowsCustomSurfaceContainersButStillRejectsControls() {
        let profile = WindowCompatibilityProfile(bundleIdentifier: "dev.warp.Warp-Stable")

        XCTAssertEqual(profile.minimumTitlebarHeight, 64)
        XCTAssertEqual(profile.maximumAncestorDepth, 40)
        XCTAssertFalse(profile.rejects(role: "AXToolbar", interactiveRoles: interactiveRoles))
        XCTAssertFalse(profile.rejects(role: "AXScrollArea", interactiveRoles: interactiveRoles))
        XCTAssertFalse(profile.rejects(role: "AXTabGroup", interactiveRoles: interactiveRoles))
        XCTAssertFalse(profile.rejects(role: "AXTextArea", interactiveRoles: interactiveRoles))
        XCTAssertTrue(profile.rejects(role: "AXButton", interactiveRoles: interactiveRoles))
        XCTAssertTrue(profile.rejects(role: "AXTab", interactiveRoles: interactiveRoles))
        XCTAssertTrue(profile.rejects(role: "AXTextField", interactiveRoles: interactiveRoles))
    }

    func testWarpUpdateAndPreviewBundleIdentifiersUseCompatibilityProfile() {
        XCTAssertTrue(
            WindowCompatibilityProfile(bundleIdentifier: "dev.warp.Warp-Stable.ShipIt")
                .allowedTopRegionRoles.contains("AXToolbar")
        )
        XCTAssertTrue(
            WindowCompatibilityProfile(bundleIdentifier: "dev.warp.Warp-Preview")
                .allowedTopRegionRoles.contains("AXToolbar")
        )
    }

    func testOtherApplicationsKeepStrictToolbarFiltering() {
        let profile = WindowCompatibilityProfile(bundleIdentifier: "com.apple.Safari")

        XCTAssertTrue(profile.allowedTopRegionRoles.isEmpty)
        XCTAssertEqual(profile.minimumTitlebarHeight, 38)
        XCTAssertEqual(profile.maximumAncestorDepth, 20)
        XCTAssertTrue(profile.rejects(role: "AXToolbar", interactiveRoles: interactiveRoles))
        XCTAssertTrue(profile.rejects(role: "AXScrollArea", interactiveRoles: interactiveRoles))
        XCTAssertTrue(profile.rejects(role: "AXTextArea", interactiveRoles: interactiveRoles))
    }
}
