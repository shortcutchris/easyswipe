import XCTest

@testable import EasySwipe

final class SwindooMotionTests: XCTestCase {
    func testUserPreferenceAndReduceMotionControlSpatialAnimation() {
        XCTAssertTrue(SwindooMotion.shouldAnimate(preferenceEnabled: true, reduceMotion: false))
        XCTAssertFalse(SwindooMotion.shouldAnimate(preferenceEnabled: false, reduceMotion: false))
        XCTAssertFalse(SwindooMotion.shouldAnimate(preferenceEnabled: true, reduceMotion: true))
    }

    func testConfirmationMotionMatchesEveryCommandDirection() throws {
        let left = try XCTUnwrap(SwindooMotion.confirmationTransforms(for: .snapLeft).dropFirst().first)
        let right = try XCTUnwrap(SwindooMotion.confirmationTransforms(for: .snapRight).dropFirst().first)
        let minimize = try XCTUnwrap(SwindooMotion.confirmationTransforms(for: .minimize).dropFirst().first)
        let maximize = try XCTUnwrap(SwindooMotion.confirmationTransforms(for: .maximize).dropFirst().first)

        XCTAssertLessThan(left.translationX, 0)
        XCTAssertGreaterThan(right.translationX, 0)
        XCTAssertLessThan(minimize.translationY, 0)
        XCTAssertLessThan(minimize.scaleY, minimize.scaleX)
        XCTAssertGreaterThan(maximize.scaleX, 1)
        XCTAssertEqual(maximize.scaleX, maximize.scaleY)
    }

    func testMotionDurationsStayWithinTheFeedbackBudget() {
        XCTAssertLessThanOrEqual(SwindooMotion.appearanceDuration, 0.13)
        XCTAssertEqual(SwindooMotion.feedbackDuration, 0.13)
        XCTAssertLessThanOrEqual(SwindooMotion.dismissalDuration, 0.14)
    }
}
