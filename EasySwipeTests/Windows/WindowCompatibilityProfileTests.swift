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

    func testWhatsAppAllowsItsHeaderDragSurfaceButStillRejectsCallControls() {
        let profile = WindowCompatibilityProfile(bundleIdentifier: "net.whatsapp.WhatsApp")

        XCTAssertEqual(profile.minimumTitlebarHeight, 64)
        XCTAssertTrue(
            profile.allowedTopRegionIdentifiers.contains("NavigationBar_HeaderViewButton")
        )
        XCTAssertFalse(
            policy.rejects(
                role: "AXButton",
                identifier: "NavigationBar_HeaderViewButton",
                actionNames: ["AXPress", "AXCancel", "AXShowMenu"],
                compatibility: profile
            )
        )
        XCTAssertFalse(
            policy.rejects(
                role: "AXGroup",
                identifier: "Toolbar",
                actionNames: ["AXScrollToVisible", "AXCancel", "AXShowMenu"],
                compatibility: profile
            )
        )
        XCTAssertTrue(
            policy.rejects(
                role: "AXButton",
                identifier: nil,
                actionNames: ["AXPress", "AXCancel", "AXShowMenu"],
                compatibility: profile
            )
        )
    }

    func testWhatsAppVariantBundleIdentifiersUseCompatibilityProfile() {
        for bundleIdentifier in [
            "net.whatsapp.WhatsApp",
            "net.whatsapp.WhatsApp.Beta",
        ] {
            let profile = WindowCompatibilityProfile(bundleIdentifier: bundleIdentifier)
            XCTAssertEqual(profile.minimumTitlebarHeight, 64)
            XCTAssertTrue(
                profile.allowedTopRegionIdentifiers.contains("NavigationBar_HeaderViewButton")
            )
        }
    }

    func testApplicationsUseMeasuredTopToolbarsAsTitlebarRegions() {
        let policy = WindowToolbarRegionPolicy()
        let windowFrame = CGRect(x: 100, y: 80, width: 1_000, height: 700)
        let toolbarFrame = CGRect(x: 100, y: 80, width: 1_000, height: 58)

        for bundleIdentifier in [
            "com.apple.finder",
            "com.apple.Safari",
            "com.apple.systempreferences",
            "com.example.SwiftUIApp",
        ] {
            let profile = WindowCompatibilityProfile(bundleIdentifier: bundleIdentifier)

            XCTAssertTrue(profile.usesMeasuredTopToolbarFrame)
            XCTAssertTrue(profile.allowsInteractiveMeasuredTopToolbar)
            XCTAssertEqual(profile.minimumTitlebarHeight, 38)
            XCTAssertTrue(
                self.policy.rejects(
                    role: "AXButton",
                    actionNames: ["AXPress"],
                    compatibility: profile
                )
            )
            XCTAssertTrue(
                policy.accepts(
                    point: CGPoint(x: 600, y: 136),
                    toolbarFrame: toolbarFrame,
                    windowFrame: windowFrame,
                    compatibility: profile
                )
            )
            XCTAssertFalse(
                policy.accepts(
                    point: CGPoint(x: 600, y: 150),
                    toolbarFrame: toolbarFrame,
                    windowFrame: windowFrame,
                    compatibility: profile
                )
            )
        }
    }

    func testApplicationsAllowInteractiveHitsOnlyInsideMeasuredTopToolbar() {
        let policy = WindowToolbarRegionPolicy()

        for bundleIdentifier in [
            "com.apple.finder",
            "com.apple.Safari",
            "com.apple.systempreferences",
            "com.example.AppKitApp",
        ] {
            let profile = WindowCompatibilityProfile(bundleIdentifier: bundleIdentifier)

            XCTAssertTrue(
                policy.acceptsInteractiveHit(
                    isInsideMeasuredTopToolbar: true,
                    compatibility: profile
                )
            )
            XCTAssertFalse(
                policy.acceptsInteractiveHit(
                    isInsideMeasuredTopToolbar: false,
                    compatibility: profile
                )
            )
        }
    }

    func testMeasuredToolbarCompatibilityCannotAdmitContentToolbars() {
        let policy = WindowToolbarRegionPolicy()
        let windowFrame = CGRect(x: 0, y: 0, width: 1_000, height: 700)
        let contentToolbarFrame = CGRect(x: 0, y: 140, width: 1_000, height: 48)
        let point = CGPoint(x: 500, y: 160)

        for bundleIdentifier in [
            "com.apple.finder",
            "com.apple.Safari",
            "com.example.CustomApp",
        ] {
            XCTAssertFalse(
                policy.accepts(
                    point: point,
                    toolbarFrame: contentToolbarFrame,
                    windowFrame: windowFrame,
                    compatibility: WindowCompatibilityProfile(
                        bundleIdentifier: bundleIdentifier
                    )
                )
            )
        }
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
        XCTAssertTrue(
            policy.rejects(
                role: "AXGroup",
                actionNames: ["AXCancel", "AXShowMenu", "AXScrollToVisible"],
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
