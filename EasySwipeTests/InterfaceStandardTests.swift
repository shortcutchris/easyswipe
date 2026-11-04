import AppKit
import Sparkle
import XCTest
@testable import EasySwipe

@MainActor
final class InterfaceStandardTests: XCTestCase {
    func testSystemAndExplicitLanguageResolution() {
        XCTAssertEqual(InterfaceLanguage.system.resolved(preferredLanguages: ["fr-FR", "de-AT", "en-US"]), "de")
        XCTAssertEqual(InterfaceLanguage.system.resolved(preferredLanguages: ["en-GB", "de"]), "en")
        XCTAssertEqual(InterfaceLanguage.system.resolved(preferredLanguages: ["ja"]), "en")
        XCTAssertEqual(InterfaceLanguage.de.resolved(preferredLanguages: ["en"]), "de")
        XCTAssertEqual(InterfaceLanguage.en.resolved(preferredLanguages: ["de"]), "en")
    }

    func testPreferencesMigrateWithoutChangingExistingBehavior() throws {
        let suite = "Swindoo.QA.Unit.\(UUID())"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(false, forKey: "app.enabled")
        defaults.set(false, forKey: "hud.animationsEnabled")
        defaults.set(true, forKey: "onboarding.completed")
        let model = AppPreferences(defaults: defaults)
        XCTAssertEqual(model.language, .system)
        XCTAssertEqual(model.appearance, .system)
        model.language = .de
        model.appearance = .dark
        let restored = AppPreferences(defaults: defaults)
        XCTAssertEqual(restored.language, .de)
        XCTAssertEqual(restored.appearance, .dark)
        XCTAssertFalse(restored.isEnabled)
        XCTAssertFalse(restored.areHUDAnimationsEnabled)
        XCTAssertTrue(restored.hasCompletedOnboarding)
        restored.language = .system
        XCTAssertEqual(AppPreferences(defaults: defaults).language, .system)
        defaults.set("future-value", forKey: "interface.appearance")
        XCTAssertEqual(AppPreferences(defaults: defaults).appearance, .system)
        XCTAssertTrue(AppPreferences(defaults: defaults).hasCompletedOnboarding)
    }

    func testAppearanceClearsOverrideForSystem() {
        XCTAssertNil(InterfaceAppearance.system.nsAppearance)
        XCTAssertEqual(InterfaceAppearance.light.nsAppearance?.name, .aqua)
        XCTAssertEqual(InterfaceAppearance.dark.nsAppearance?.name, .darkAqua)
    }

    func testLanguageChangesResolvedTextImmediately() {
        let previous = L10n.language
        defer { L10n.language = previous }
        L10n.language = .de
        XCTAssertEqual(L10n.text("settings.general"), "Allgemein")
        L10n.language = .en
        XCTAssertEqual(L10n.text("settings.general"), "General")
    }

    func testUpdateWaitsForGestureAndInvokesInstallOnlyOnce() throws {
        let suite = "Swindoo.QA.Unit.\(UUID())"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let updater = UpdateController(defaults: defaults)
        defer { updater.stop() }
        var busy = true
        var installs = 0
        updater.isBusy = { busy }
        XCTAssertTrue(updater.postponeInstallation { installs += 1 })
        XCTAssertEqual(updater.state, .waiting)
        XCTAssertFalse(updater.resumeInstallationIfSafe())
        XCTAssertEqual(installs, 0)
        busy = false
        XCTAssertTrue(updater.resumeInstallationIfSafe())
        XCTAssertEqual(installs, 1)
        XCTAssertFalse(updater.resumeInstallationIfSafe())
        XCTAssertEqual(installs, 1)
        XCTAssertFalse(updater.postponeInstallation { installs += 1 })
    }

    func testStoppingUpdaterDiscardsDeferredInstall() {
        let updater = UpdateController()
        var busy = true
        var installed = false
        updater.isBusy = { busy }
        XCTAssertTrue(updater.postponeInstallation { installed = true })
        updater.stop()
        busy = false
        XCTAssertFalse(updater.resumeInstallationIfSafe())
        XCTAssertFalse(installed)
    }

    func testRejectsMalformedUpdateConfiguration() {
        let key = Data(repeating: 1, count: 32).base64EncodedString()
        XCTAssertFalse(UpdateConfiguration(feedURL: URL(string: "https://name:password@example.org/feed"), publicKey: key).isConfigured)
        XCTAssertFalse(UpdateConfiguration(feedURL: URL(string: "https://example.org/feed"), publicKey: "not-a-key").isConfigured)
    }

    func testNetworkFailureAndCancellationDoNotPretendToBeCurrent() throws {
        let suite = "Swindoo.QA.Unit.\(UUID())"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let updater = UpdateController(defaults: defaults)
        updater.receiveFailure(URLError(.notConnectedToInternet))
        XCTAssertEqual(updater.state, .failed)
        XCTAssertEqual(updater.failureMessageKey, "updates.failure.network")
        XCTAssertNil(updater.lastSuccessfulCheck)
        updater.receiveFailure(URLError(.cancelled))
        XCTAssertEqual(updater.state, .cancelled)
        XCTAssertNil(updater.failureMessageKey)
        updater.receiveFailure(NSError(domain: "QA.Integrity", code: 1))
        XCTAssertEqual(updater.failureMessageKey, "updates.failure.general")
    }
}
