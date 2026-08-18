import XCTest

@testable import EasySwipe

final class UpdateConfigurationTests: XCTestCase {
    func testRequiresHTTPSFeedAndPublicKey() {
        XCTAssertFalse(UpdateConfiguration(feedURL: nil, publicKey: nil).isConfigured)
        XCTAssertFalse(
            UpdateConfiguration(
                feedURL: URL(string: "http://example.com/appcast.xml"),
                publicKey: "public-key"
            ).isConfigured
        )
        XCTAssertFalse(
            UpdateConfiguration(
                feedURL: URL(string: "https://example.com/appcast.xml"),
                publicKey: ""
            ).isConfigured
        )
        XCTAssertTrue(
            UpdateConfiguration(
                feedURL: URL(string: "https://example.com/appcast.xml"),
                publicKey: "public-key"
            ).isConfigured
        )
    }

    func testDevelopmentAppMetadataIsMenuBarOnlyAndSafelyUnconfigured() {
        XCTAssertEqual(
            (Bundle.main.object(forInfoDictionaryKey: "LSUIElement") as? NSNumber)?.boolValue,
            true
        )
        XCTAssertEqual(
            Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
            "0.1.0"
        )
        XCTAssertFalse(UpdateConfiguration.from(bundle: .main).isConfigured)
    }
}
