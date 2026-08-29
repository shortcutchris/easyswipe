import XCTest

@testable import EasySwipe

final class AppPreferencesTests: XCTestCase {
    @MainActor
    func testHUDAnimationsAreEnabledByDefault() throws {
        let (defaults, suiteName) = try makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        XCTAssertTrue(AppPreferences(defaults: defaults).areHUDAnimationsEnabled)
    }

    @MainActor
    func testHUDAnimationPreferencePersists() throws {
        let (defaults, suiteName) = try makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let preferences = AppPreferences(defaults: defaults)
        preferences.areHUDAnimationsEnabled = false

        XCTAssertFalse(AppPreferences(defaults: defaults).areHUDAnimationsEnabled)
    }

    private func makeDefaults() throws -> (UserDefaults, String) {
        let suiteName = "AppPreferencesTests.\(UUID().uuidString)"
        return (try XCTUnwrap(UserDefaults(suiteName: suiteName)), suiteName)
    }
}
