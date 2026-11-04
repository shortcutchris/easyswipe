import XCTest

@MainActor
final class UpdateRoundtripTests: XCTestCase {
    func testPreviousSignedReleaseUpdatesThroughSparkle() throws {
        continueAfterFailure = false
        let root = URL(fileURLWithPath: "/Users/chris/Developer/EasySwipeUpdateQA")
        let appURL = root.appendingPathComponent("installed/EasySwipe.app")
        let infoURL = appURL.appendingPathComponent("Contents/Info.plist")
        let originalInfo = try NSDictionary(contentsOf: infoURL, error: ())
        let configuration = try JSONSerialization.jsonObject(with: Data(contentsOf: root.appendingPathComponent("test-config.json"))) as! [String: String]
        XCTAssertEqual(originalInfo["CFBundleVersion"] as? String, configuration["previousBuild"])
        let app = XCUIApplication(url: appURL)
        defer { app.terminate() }
        // The runner prepares/restores the real test-host preferences. A UI-test
        // runner's UserDefaults suite is not the launched app's preferences domain.
        app.launch()
        app.statusItems["Swindoo"].click()
        let check = app.menuItems.matching(NSPredicate(format: "title == %@ OR title == %@", "Nach Updates suchen…", "Check for Updates…")).firstMatch
        XCTAssertTrue(check.waitForExistence(timeout: 10), app.debugDescription)
        check.click()
        let install = app.buttons.matching(NSPredicate(format: "title == %@ OR title == %@", "Installieren", "Install Update")).firstMatch
        XCTAssertTrue(install.waitForExistence(timeout: 30), app.debugDescription)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "update-offered"
        attachment.lifetime = .keepAlways
        add(attachment)
        install.click()
        let relaunch = app.buttons.matching(NSPredicate(format: "title == %@ OR title == %@", "Installieren und App neu starten", "Install and Relaunch")).firstMatch
        XCTAssertTrue(relaunch.waitForExistence(timeout: 60), app.debugDescription)
        relaunch.click()
        let installed = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            (try? NSDictionary(contentsOf: infoURL, error: ()))?["CFBundleVersion"] as? String == configuration["installedBuild"]
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [installed], timeout: 60), .completed)
        XCTAssertTrue(app.statusItems["Swindoo"].waitForExistence(timeout: 30), app.debugDescription)
        app.statusItems["Swindoo"].click()
        app.menuItems["Einstellungen …"].click()
        XCTAssertTrue(app.windows["Einstellungen"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.popUpButtons["settings.language"].value as? String, "Deutsch")
        XCTAssertEqual(app.popUpButtons["settings.appearance"].value as? String, "Dunkel")
        XCTAssertEqual(app.checkBoxes["Swindoo aktiv"].value as? String, "0")
        XCTAssertEqual(app.checkBoxes["Animationen anzeigen"].value as? String, "0")
        let after = XCTAttachment(screenshot: app.windows["Einstellungen"].screenshot())
        after.name = "updated-settings-preserved"
        after.lifetime = .keepAlways
        add(after)
    }
}
