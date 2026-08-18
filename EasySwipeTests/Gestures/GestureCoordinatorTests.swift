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

        harness.coordinator.handle(sample(phase: .ended))

        XCTAssertEqual(harness.actions.performed, [.snapLeft])
        XCTAssertEqual(harness.hud.presented, [.snapLeft])
    }

    func testMomentumNeverCommitsTrackedGesture() {
        let harness = Harness()

        harness.coordinator.handle(sample(deltaX: 60, phase: .began))
        harness.coordinator.handle(
            sample(deltaX: 10, phase: .changed, isMomentum: true)
        )
        harness.coordinator.handle(sample(phase: .ended))

        XCTAssertTrue(harness.actions.performed.isEmpty)
        XCTAssertTrue(harness.hud.presented.isEmpty)
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
        return WindowActionResult(action: action, hudFrame: target.initialAppKitFrame)
    }
}

@MainActor
private final class HUDSpy: HUDPresenting {
    private(set) var presented: [WindowGestureAction] = []

    func show(action: WindowGestureAction, over targetFrame: CGRect) {
        presented.append(action)
    }
}
