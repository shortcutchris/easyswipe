import XCTest

@testable import EasySwipe

final class SwipeGestureRecognizerTests: XCTestCase {
    func testRecognizesPhysicalSwipeLeft() {
        var recognizer = SwipeGestureRecognizer()
        recognizer.begin()
        recognizer.update(deltaX: 30, deltaY: 2)
        recognizer.update(deltaX: 20, deltaY: 1)

        XCTAssertEqual(recognizer.finish(), .snapLeft)
    }

    func testRecognizesPhysicalSwipeRight() {
        var recognizer = SwipeGestureRecognizer()
        recognizer.begin()
        recognizer.update(deltaX: -50, deltaY: 3)

        XCTAssertEqual(recognizer.finish(), .snapRight)
    }

    func testRecognizesPhysicalSwipeDown() {
        var recognizer = SwipeGestureRecognizer()
        recognizer.begin()
        recognizer.update(deltaX: 2, deltaY: -48)

        XCTAssertEqual(recognizer.finish(), .minimize)
    }

    func testRecognizesPhysicalSwipeUp() {
        var recognizer = SwipeGestureRecognizer()
        recognizer.begin()
        recognizer.update(deltaX: 0, deltaY: 80)

        XCTAssertEqual(recognizer.finish(), .maximize)
    }

    func testRejectsShortGesture() {
        var recognizer = SwipeGestureRecognizer()
        recognizer.begin()
        recognizer.update(deltaX: 30, deltaY: 0)

        XCTAssertNil(recognizer.finish())
    }

    func testRejectsDiagonalGesture() {
        var recognizer = SwipeGestureRecognizer()
        recognizer.begin()
        recognizer.update(deltaX: 50, deltaY: 45)

        XCTAssertNil(recognizer.finish())
    }

    func testUsesNetTravelWhenDirectionReverses() {
        var recognizer = SwipeGestureRecognizer()
        recognizer.begin()
        recognizer.update(deltaX: 70, deltaY: 0)
        recognizer.update(deltaX: -125, deltaY: 0)

        XCTAssertEqual(recognizer.finish(), .snapRight)
    }

    func testFinishResetsRecognizer() {
        var recognizer = SwipeGestureRecognizer()
        recognizer.begin()
        recognizer.update(deltaX: 60, deltaY: 0)
        _ = recognizer.finish()

        XCTAssertFalse(recognizer.isTracking)
        XCTAssertNil(recognizer.finish())
    }

    func testPreviewAppearsInsideCommitThreshold() {
        var recognizer = SwipeGestureRecognizer()
        recognizer.begin()
        recognizer.update(deltaX: 14, deltaY: 0)

        XCTAssertEqual(recognizer.previewAction, .snapLeft)
        XCTAssertNil(recognizer.finish())
    }

    func testPreviewTracksDirectionReversal() {
        var recognizer = SwipeGestureRecognizer()
        recognizer.begin()
        recognizer.update(deltaX: 20, deltaY: 0)
        XCTAssertEqual(recognizer.previewAction, .snapLeft)

        recognizer.update(deltaX: -42, deltaY: 0)
        XCTAssertEqual(recognizer.previewAction, .snapRight)
    }
}
