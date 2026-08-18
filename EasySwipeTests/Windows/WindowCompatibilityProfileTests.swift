import XCTest

@testable import EasySwipe

final class WindowCompatibilityProfileTests: XCTestCase {
    private let policy = WindowHitRegionPolicy()

    func testWarpAllowsItsCustomTitlebarTextAreaButStillRejectsControls() {
        let profile = WindowCompatibilityProfile(bundleIdentifier: "dev.warp.Warp-Stable")

        XCTAssertEqual(profile.minimumTitlebarHeight, 64)
        XCTAssertEqual(profile.maximumAncestorDepth, 48)
        XCTAssertFalse(
            policy.rejects(role: "AXTextArea", actionNames: [], compatibility: profile)
        )
        XCTAssertTrue(policy.rejects(role: "AXButton", actionNames: [], compatibility: profile))
        XCTAssertTrue(policy.rejects(role: "AXTab", actionNames: [], compatibility: profile))
        XCTAssertTrue(
            policy.rejects(role: "AXTextField", actionNames: [], compatibility: profile)
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
                    policy.rejects(role: role, actionNames: [], compatibility: profile),
                    "\(bundleIdentifier) must allow the \(role) titlebar container"
                )
            }
        }
    }

    func testOtherApplicationsStillRejectDirectControls() {
        let profile = WindowCompatibilityProfile(bundleIdentifier: "notion.id")

        XCTAssertTrue(profile.allowedTopRegionRoles.isEmpty)
        XCTAssertEqual(profile.minimumTitlebarHeight, 38)
        XCTAssertEqual(profile.maximumAncestorDepth, 48)
        XCTAssertTrue(policy.rejects(role: "AXButton", actionNames: [], compatibility: profile))
        XCTAssertTrue(policy.rejects(role: "AXTab", actionNames: [], compatibility: profile))
        XCTAssertTrue(
            policy.rejects(role: "AXTextArea", actionNames: [], compatibility: profile)
        )
        XCTAssertTrue(
            policy.rejects(role: "AXTextField", actionNames: [], compatibility: profile)
        )
        XCTAssertTrue(policy.rejects(role: "AXLink", actionNames: [], compatibility: profile))
    }

    func testTransientSurfacesAndSelectableContentRemainBlocked() {
        let profile = WindowCompatibilityProfile(bundleIdentifier: "com.example.NativeApp")

        for role in ["AXSheet", "AXPopover", "AXMenu", "AXHelpTag", "AXRow", "AXCell"] {
            XCTAssertTrue(
                policy.rejects(role: role, actionNames: [], compatibility: profile),
                "\(role) must not start a window gesture"
            )
        }
    }

    func testCustomInteractiveElementsAreBlockedByActivationActions() {
        let profile = WindowCompatibilityProfile(bundleIdentifier: "com.example.CustomChrome")

        for action in ["AXPress", "AXPick", "AXIncrement", "AXConfirm"] {
            XCTAssertTrue(
                policy.rejects(role: "AXGroup", actionNames: [action], compatibility: profile),
                "Custom element exposing \(action) must not start a window gesture"
            )
        }

        XCTAssertFalse(
            policy.rejects(
                role: "AXGroup",
                actionNames: ["AXShowMenu", "AXScrollToVisible"],
                compatibility: profile
            )
        )
    }

    func testWindowEligibilitySeparatesTitlebarWindowsFromOverlays() {
        let policy = WindowEligibilityPolicy()

        XCTAssertTrue(
            policy.accepts(
                subrole: "AXStandardWindow",
                isModal: false,
                hasTitlebarEvidence: false
            )
        )
        XCTAssertTrue(
            policy.accepts(
                subrole: "AXFloatingWindow",
                isModal: false,
                hasTitlebarEvidence: true
            )
        )
        XCTAssertTrue(
            policy.accepts(
                subrole: "AXDialog",
                isModal: false,
                hasTitlebarEvidence: true
            )
        )
        XCTAssertFalse(
            policy.accepts(
                subrole: "AXDialog",
                isModal: true,
                hasTitlebarEvidence: true
            )
        )
        XCTAssertFalse(
            policy.accepts(
                subrole: "AXSystemDialog",
                isModal: false,
                hasTitlebarEvidence: true
            )
        )
        XCTAssertFalse(
            policy.accepts(
                subrole: nil,
                isModal: false,
                hasTitlebarEvidence: false
            )
        )
    }
}
