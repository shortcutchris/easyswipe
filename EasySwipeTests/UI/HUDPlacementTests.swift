import XCTest

@testable import EasySwipe

final class HUDPlacementTests: XCTestCase {
    private let screen = CGRect(x: 0, y: 0, width: 1000, height: 800)
    private let panelSize = CGSize(width: 56, height: 56)

    func testPlacesHUDRightAndBelowPointerByDefault() {
        XCTAssertEqual(
            HUDPlacement.origin(
                near: CGPoint(x: 500, y: 500),
                panelSize: panelSize,
                visibleFrame: screen
            ),
            CGPoint(x: 512, y: 432)
        )
    }

    func testFlipsLeftAndAboveNearBottomRightCorner() {
        XCTAssertEqual(
            HUDPlacement.origin(
                near: CGPoint(x: 990, y: 10),
                panelSize: panelSize,
                visibleFrame: screen
            ),
            CGPoint(x: 922, y: 22)
        )
    }

    func testClampsHUDToOffsetVisibleFrame() {
        let visibleFrame = CGRect(x: -800, y: 40, width: 800, height: 600)

        XCTAssertEqual(
            HUDPlacement.origin(
                near: CGPoint(x: -2, y: 638),
                panelSize: panelSize,
                visibleFrame: visibleFrame
            ),
            CGPoint(x: -70, y: 570)
        )
    }
}
