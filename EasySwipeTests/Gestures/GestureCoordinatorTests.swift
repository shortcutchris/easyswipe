import ApplicationServices
import XCTest

@testable import EasySwipe

@MainActor
final class GestureCoordinatorTests: XCTestCase {
    func testCommitsExactlyOnceAtPhysicalEnd() {
        let harness = Harness()

        harness.coordinator.handle(sample(deltaX: 30, phase: .began))
        harness.coordinator.handle(sample(deltaX: 20, phase: .changed))
        XCTAssertTrue(harness.actions.performed.isEmpty)
        XCTAssertEqual(harness.hud.previews, [.snapLeft])
        XCTAssertEqual(harness.hud.previewLocations, [CGPoint(x: 100, y: 100)])

        harness.coordinator.handle(sample(phase: .ended))

        XCTAssertEqual(harness.actions.performed, [.snapLeft])
        XCTAssertEqual(harness.hud.confirmations, [.snapLeft])
        XCTAssertEqual(harness.hud.confirmationLocations, [CGPoint(x: 100, y: 100)])
    }

    func testMomentumNeverCommitsTrackedGesture() {
        let harness = Harness()

        harness.coordinator.handle(sample(deltaX: 60, phase: .began))
        harness.coordinator.handle(
            sample(deltaX: 10, phase: .changed, isMomentum: true)
        )
        harness.coordinator.handle(sample(phase: .ended))

        XCTAssertTrue(harness.actions.performed.isEmpty)
        XCTAssertTrue(harness.hud.confirmations.isEmpty)
    }

    func testImpreciseWheelInputNeverStartsGesture() {
        let harness = Harness()

        harness.coordinator.handle(
            sample(deltaX: 100, phase: .began, isPrecise: false)
        )
        harness.coordinator.handle(
            sample(deltaX: 100, phase: .ended, isPrecise: false)
        )

        XCTAssertEqual(harness.resolver.resolveCount, 0)
        XCTAssertTrue(harness.actions.performed.isEmpty)
        XCTAssertTrue(harness.hud.previews.isEmpty)
    }

    func testDownSwipePreviewsAndMinimizes() {
        let harness = Harness()

        harness.coordinator.handle(sample(deltaY: -18, phase: .began))
        XCTAssertEqual(harness.hud.previews, [.minimize])
        XCTAssertTrue(harness.actions.performed.isEmpty)

        harness.coordinator.handle(sample(deltaY: -30, phase: .ended))

        XCTAssertEqual(harness.actions.performed, [.minimize])
        XCTAssertEqual(harness.hud.confirmations, [.minimize])
    }

    func testUpSwipePreviewsAndMaximizes() {
        let harness = Harness()

        harness.coordinator.handle(sample(deltaY: 18, phase: .began))
        XCTAssertEqual(harness.hud.previews, [.maximize])
        XCTAssertTrue(harness.actions.performed.isEmpty)

        harness.coordinator.handle(sample(deltaY: 30, phase: .ended))

        XCTAssertEqual(harness.actions.performed, [.maximize])
        XCTAssertEqual(harness.hud.confirmations, [.maximize])
    }

    func testShortGestureDismissesPreviewWithoutPerformingAction() {
        let harness = Harness()

        harness.coordinator.handle(sample(deltaX: 14, phase: .began))
        XCTAssertEqual(harness.hud.previews, [.snapLeft])

        harness.coordinator.handle(sample(phase: .ended))

        XCTAssertTrue(harness.actions.performed.isEmpty)
        XCTAssertTrue(harness.hud.confirmations.isEmpty)
        XCTAssertGreaterThan(harness.hud.dismissCount, 0)
    }

    func testPreviewChangesWhenGestureDirectionReverses() {
        let harness = Harness()

        harness.coordinator.handle(sample(deltaX: 20, phase: .began))
        harness.coordinator.handle(sample(deltaX: -42, phase: .changed))

        XCTAssertEqual(harness.hud.previews, [.snapLeft, .snapRight])
    }

    private func sample(
        deltaX: Double = 0,
        deltaY: Double = 0,
        phase: PhysicalScrollPhase,
        isMomentum: Bool = false,
        isPrecise: Bool = true
    ) -> ScrollSample {
        ScrollSample(
            physicalDeltaX: deltaX,
            physicalDeltaY: deltaY,
            phase: phase,
            isMomentum: isMomentum,
            isPrecise: isPrecise,
            locationX: 100,
            locationY: 100
        )
    }
}

@MainActor
private final class Harness {
    let resolver: ResolverSpy
    let actions: ActionSpy
    let hud: HUDSpy
    let coordinator: GestureCoordinator

    init() {
        let target = AXWindowTarget(
            element: AXUIElementCreateSystemWide(),
            processIdentifier: 42,
            visibleScreenFrame: CGRect(x: 0, y: 0, width: 1200, height: 800),
            initialAppKitFrame: CGRect(x: 0, y: 0, width: 600, height: 800)
        )
        let resolver = ResolverSpy(target: target)
        let actions = ActionSpy()
        let hud = HUDSpy()

        self.resolver = resolver
        self.actions = actions
        self.hud = hud
        coordinator = GestureCoordinator(
            resolver: resolver,
            actionService: actions,
            hudPresenter: hud
        )
    }
}

@MainActor
private final class ResolverSpy: WindowResolving {
    let target: AXWindowTarget
    private(set) var resolveCount = 0

    init(target: AXWindowTarget) {
        self.target = target
    }

    func resolveTarget(at appKitPoint: CGPoint) -> AXWindowTarget? {
        resolveCount += 1
        return target
    }
}

@MainActor
private final class ActionSpy: WindowActionPerforming {
    private(set) var performed: [WindowGestureAction] = []

    func perform(_ action: WindowGestureAction, on target: AXWindowTarget) -> WindowActionResult? {
        performed.append(action)
        return WindowActionResult(action: action)
    }
}

@MainActor
private final class HUDSpy: HUDPresenting {
    private(set) var previews: [WindowGestureAction] = []
    private(set) var confirmations: [WindowGestureAction] = []
    private(set) var previewLocations: [CGPoint] = []
    private(set) var confirmationLocations: [CGPoint] = []
    private(set) var dismissCount = 0

    func showPreview(action: WindowGestureAction, near pointerLocation: CGPoint) {
        previews.append(action)
        previewLocations.append(pointerLocation)
    }

    func confirm(action: WindowGestureAction, near pointerLocation: CGPoint) {
        confirmations.append(action)
        confirmationLocations.append(pointerLocation)
    }

    func dismiss() {
        dismissCount += 1
    }
}
