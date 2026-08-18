import XCTest

@testable import EasySwipe

final class ScreenGeometryTests: XCTestCase {
    func testHalvesFillVisibleFrameWithoutGapForOddWidth() {
        let frame = CGRect(x: 10, y: 20, width: 1001, height: 700)
        let halves = ScreenFrameCalculator.halves(of: frame)

        XCTAssertEqual(halves.left, CGRect(x: 10, y: 20, width: 500, height: 700))
        XCTAssertEqual(halves.right, CGRect(x: 510, y: 20, width: 501, height: 700))
        XCTAssertEqual(halves.left.maxX, halves.right.minX)
        XCTAssertEqual(halves.left.width + halves.right.width, frame.width)
    }

    func testConvertsAppKitRectToAXAndBack() {
        let appKitFrame = CGRect(x: -1200, y: 100, width: 800, height: 600)
        let axFrame = ScreenCoordinateConverter.axRect(
            fromAppKit: appKitFrame,
            primaryScreenHeight: 1080
        )

        XCTAssertEqual(axFrame, CGRect(x: -1200, y: 380, width: 800, height: 600))
        XCTAssertEqual(
            ScreenCoordinateConverter.appKitRect(fromAX: axFrame, primaryScreenHeight: 1080),
            appKitFrame
        )
    }

    func testConvertsPointAcrossCoordinateSystems() {
        let appKitPoint = CGPoint(x: 40, y: 100)
        let axPoint = ScreenCoordinateConverter.axPoint(
            fromAppKit: appKitPoint,
            primaryScreenHeight: 1080
        )

        XCTAssertEqual(axPoint, CGPoint(x: 40, y: 980))
        XCTAssertEqual(
            ScreenCoordinateConverter.appKitPoint(fromAX: axPoint, primaryScreenHeight: 1080),
            appKitPoint
        )
    }
}
