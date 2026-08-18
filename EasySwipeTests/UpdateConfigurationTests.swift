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

    func testAppMetadataContainsProductionUpdateConfiguration() {
        XCTAssertEqual(
            (Bundle.main.object(forInfoDictionaryKey: "LSUIElement") as? NSNumber)?.boolValue,
            true
        )
        XCTAssertEqual(
            Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
            "0.1.1"
        )
        XCTAssertEqual(
            Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String,
            "9"
        )
        let configuration = UpdateConfiguration.from(bundle: .main)
        XCTAssertEqual(
            configuration.feedURL?.absoluteString,
            "https://raw.githubusercontent.com/shortcutchris/easyswipe-releases/main/appcast.xml"
        )
        XCTAssertEqual(
            configuration.publicKey,
            "a5+ZLh811liNfhGI69w0MTTkEr1OfVJOGer3M8FhMGA="
        )
        XCTAssertTrue(configuration.isConfigured)
    }

    func testUpdateDiagnosticsIncludeUnderlyingErrors() {
        let underlying = NSError(
            domain: NSPOSIXErrorDomain,
            code: 13,
            userInfo: [NSLocalizedDescriptionKey: "Permission denied"]
        )
        let error = NSError(
            domain: "SUSparkleErrorDomain",
            code: 4005,
            userInfo: [
                NSLocalizedDescriptionKey: "The update failed",
                NSUnderlyingErrorKey: underlying,
            ]
        )

        let diagnostic = UpdateController.diagnosticDescription(for: error)

        XCTAssertTrue(diagnostic.contains("domain=SUSparkleErrorDomain code=4005"))
        XCTAssertTrue(diagnostic.contains("domain=NSPOSIXErrorDomain code=13"))
        XCTAssertTrue(diagnostic.contains("Permission denied"))
    }
}
