import XCTest

@testable import EasySwipe

final class LocalizationTests: XCTestCase {
    private let keys = [
        "updates.status.verifying",
        "login.error.message",
        "updates.failure.network",
        "updates.failure.general",
        "menu.settings",
        "settings.title",
        "settings.general",
        "settings.updates",
        "settings.interface",
        "settings.language",
        "settings.appearance",
        "settings.system",
        "settings.light",
        "settings.dark",
        "settings.interface.hint",
        "settings.behavior",
        "settings.help",
        "updates.version",
        "updates.availableVersion",
        "updates.lastCheck",
        "updates.automatic",
        "updates.autoCheck",
        "updates.autoDownload",
        "updates.safety",
        "updates.languageHint",
        "updates.status.unChecked",
        "updates.status.unconfigured",
        "updates.status.checking",
        "updates.status.current",
        "updates.status.noCompatibleUpdate",
        "updates.status.available",
        "updates.status.downloading",
        "updates.status.ready",
        "updates.status.waiting",
        "updates.status.installing",
        "updates.status.cancelled",
        "updates.status.failed",
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
        "menu.animations",
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
