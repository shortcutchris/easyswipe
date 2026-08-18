import XCTest

@testable import EasySwipe

final class ScrollDeltaNormalizerTests: XCTestCase {
    func testPreservesDeviceDeltasWhenAppKitDidNotInvertThem() {
        XCTAssertEqual(
            ScrollDeltaNormalizer.physical(
                deltaX: 12,
                deltaY: -8,
                isDirectionInvertedFromDevice: false
            ),
            PhysicalScrollDelta(x: 12, y: -8)
        )
    }

    func testReversesAppKitDeltasWhenNaturalScrollingWasApplied() {
        XCTAssertEqual(
            ScrollDeltaNormalizer.physical(
                deltaX: -12,
                deltaY: 8,
                isDirectionInvertedFromDevice: true
            ),
            PhysicalScrollDelta(x: 12, y: -8)
        )
    }
}
