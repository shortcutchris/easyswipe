import XCTest

@testable import EasySwipe

final class LocalizationTests: XCTestCase {
    private let keys = [
        "common.close",
        "common.ok",
        "gesture.down",
        "gesture.left",
        "gesture.right",
        "gesture.up",
        "guide.footer",
        "guide.title",
        "hud.left",
        "hud.maximize",
        "hud.minimize",
        "hud.right",
        "login.error.title",
        "login.requiresApproval",
        "menu.about",
        "menu.checkForUpdates",
        "menu.enabled",
        "menu.gestureGuide",
        "menu.launchAtLogin",
        "menu.permissions",
        "menu.quit",
        "onboarding.deviceHint",
        "onboarding.finish",
        "onboarding.subtitle",
        "onboarding.title",
        "permission.explanation",
        "permission.granted",
        "permission.missing",
        "permission.openSettings",
        "permission.request",
        "permission.title",
        "update.unavailable.message",
        "update.unavailable.title",
    ]

    func testEnglishAndGermanCatalogsContainEveryUserFacingKey() throws {
        for language in ["en", "de"] {
            let resourcePath = try XCTUnwrap(
                Bundle.main.path(forResource: language, ofType: "lproj"),
                "Missing compiled \(language) localization"
            )
            let bundle = try XCTUnwrap(Bundle(path: resourcePath))

            for key in keys {
                let value = bundle.localizedString(forKey: key, value: nil, table: nil)
                XCTAssertFalse(value.isEmpty, "Empty \(language) translation for \(key)")
                XCTAssertNotEqual(value, key, "Missing \(language) translation for \(key)")
            }
        }
    }
}
