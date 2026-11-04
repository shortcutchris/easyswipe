import XCTest

@MainActor
final class InterfaceUITests: XCTestCase {
    func testLiveLanguageThemeAndPersistence() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        let suite = "Swindoo.QA.UI.\(UUID().uuidString)"
        app.launchEnvironment["SWINDOO_QA_SUITE"] = suite
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "de_DE"]
        app.launch()
        defer { app.terminate(); UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite) }
        XCTAssertTrue(app.popUpButtons["settings.language"].waitForExistence(timeout: 10), app.debugDescription)
        select(app, "settings.language", "Deutsch")
        XCTAssertTrue(app.windows["Einstellungen"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Sprache"].exists)
        select(app, "settings.appearance", "Dunkel")
        snapshot(app, "settings-de-dark")
        select(app, "settings.appearance", "Hell")
        snapshot(app, "settings-de-light")
        select(app, "settings.language", "English")
        XCTAssertTrue(app.windows["Settings"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Language"].exists)
        snapshot(app, "settings-en-light")
        select(app, "settings.appearance", "Dark")
        snapshot(app, "settings-en-dark")
        app.buttons["Gesture Guide…"].click()
        XCTAssertTrue(app.windows["Swindoo Gestures"].waitForExistence(timeout: 3))
        app.typeKey(",", modifierFlags: .command)
        select(app, "settings.language", "Deutsch")
        XCTAssertTrue(app.windows["Swindoo-Gesten"].waitForExistence(timeout: 3))
        select(app, "settings.language", "English")
        app.terminate()
        app.launch()
        XCTAssertTrue(app.windows["Settings"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.popUpButtons["settings.appearance"].value as? String, "Dark")
        XCTAssertEqual(app.popUpButtons["settings.language"].value as? String, "English")
        select(app, "settings.appearance", "System")
        app.radioButtons["Updates"].click()
        XCTAssertTrue(app.staticTexts["updates.status"].waitForExistence(timeout: 3))
        snapshot(app, "updates-en-system")
    }

    private func select(_ app: XCUIApplication, _ identifier: String, _ title: String) {
        app.popUpButtons[identifier].click()
        app.menuItems[title].click()
    }

    private func snapshot(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.windows.firstMatch.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
