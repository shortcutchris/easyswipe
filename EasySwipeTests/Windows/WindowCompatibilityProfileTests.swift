import XCTest

@testable import EasySwipe

final class WindowCompatibilityProfileTests: XCTestCase {
    private let blockingControlRoles: Set<String> = [
        "AXButton", "AXCheckBox", "AXComboBox", "AXLink", "AXPopUpButton", "AXRadioButton",
        "AXSlider", "AXTab", "AXTextArea", "AXTextField",
    ]

    func testWarpAllowsItsCustomTitlebarTextAreaButStillRejectsControls() {
        let profile = WindowCompatibilityProfile(bundleIdentifier: "dev.warp.Warp-Stable")

        XCTAssertEqual(profile.minimumTitlebarHeight, 64)
        XCTAssertEqual(profile.maximumAncestorDepth, 40)
        XCTAssertFalse(
            profile.rejects(role: "AXTextArea", blockingControlRoles: blockingControlRoles)
        )
        XCTAssertTrue(profile.rejects(role: "AXButton", blockingControlRoles: blockingControlRoles))
        XCTAssertTrue(profile.rejects(role: "AXTab", blockingControlRoles: blockingControlRoles))
        XCTAssertTrue(
            profile.rejects(role: "AXTextField", blockingControlRoles: blockingControlRoles)
        )
    }

    func testWarpUpdateAndPreviewBundleIdentifiersUseCompatibilityProfile() {
        XCTAssertTrue(
            WindowCompatibilityProfile(bundleIdentifier: "dev.warp.Warp-Stable.ShipIt")
                .allowedTopRegionRoles.contains("AXTextArea")
        )
        XCTAssertTrue(
            WindowCompatibilityProfile(bundleIdentifier: "dev.warp.Warp-Preview")
                .allowedTopRegionRoles.contains("AXTextArea")
        )
    }

    func testCommonCustomTitlebarContainersRemainEligibleAcrossAppFrameworks() {
        let containerRoles: Set<String> = [
            "AXBrowser", "AXGroup", "AXList", "AXOutline", "AXScrollArea", "AXTabGroup",
            "AXTable", "AXToolbar", "AXWebArea",
        ]
        let representativeBundleIdentifiers = [
            "notion.id",
            "com.tinyspeck.slackmacgap",
            "com.microsoft.teams2",
            "com.google.Chrome",
            "com.microsoft.VSCode",
            "com.spotify.client",
            "com.apple.Safari",
        ]

        for bundleIdentifier in representativeBundleIdentifiers {
            let profile = WindowCompatibilityProfile(bundleIdentifier: bundleIdentifier)
            for role in containerRoles {
                XCTAssertFalse(
                    profile.rejects(role: role, blockingControlRoles: blockingControlRoles),
                    "\(bundleIdentifier) must allow the \(role) titlebar container"
                )
            }
        }
    }

    func testOtherApplicationsStillRejectDirectControls() {
        let profile = WindowCompatibilityProfile(bundleIdentifier: "notion.id")

        XCTAssertTrue(profile.allowedTopRegionRoles.isEmpty)
        XCTAssertEqual(profile.minimumTitlebarHeight, 38)
        XCTAssertEqual(profile.maximumAncestorDepth, 20)
        XCTAssertTrue(profile.rejects(role: "AXButton", blockingControlRoles: blockingControlRoles))
        XCTAssertTrue(profile.rejects(role: "AXTab", blockingControlRoles: blockingControlRoles))
        XCTAssertTrue(
            profile.rejects(role: "AXTextArea", blockingControlRoles: blockingControlRoles)
        )
        XCTAssertTrue(
            profile.rejects(role: "AXTextField", blockingControlRoles: blockingControlRoles)
        )
        XCTAssertTrue(profile.rejects(role: "AXLink", blockingControlRoles: blockingControlRoles))
    }
}
