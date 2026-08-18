import ApplicationServices
import XCTest

@testable import EasySwipe

@MainActor
final class WindowFrameApplierTests: XCTestCase {
    func testDisablesEnhancedUIAndAppliesSizePositionSize() {
        let requested = CGRect(x: 1200, y: 24, width: 800, height: 1076)
        let accessibility = AccessibilitySpy(
            enhancedUI: true,
            observedFrames: [requested]
        )
        let applier = AccessibilityWindowFrameApplier(accessibility: accessibility)

        let result = applier.apply(requested, to: makeTarget())

        XCTAssertEqual(result, requested)
        XCTAssertEqual(
            accessibility.operations,
            [
                .setEnhancedUI(false),
                .setSize(requested.size),
                .setPosition(requested.origin),
                .setSize(requested.size),
                .readFrame,
                .setEnhancedUI(true),
            ]
        )
    }

    func testRetriesWhenFirstObservedFrameIsIncomplete() {
        let requested = CGRect(x: 0, y: 24, width: 800, height: 1076)
        let partial = CGRect(x: 0, y: 250, width: 800, height: 850)
        let accessibility = AccessibilitySpy(
            enhancedUI: false,
            observedFrames: [partial, requested]
        )
        let applier = AccessibilityWindowFrameApplier(accessibility: accessibility)

        let result = applier.apply(requested, to: makeTarget())

        XCTAssertEqual(result, requested)
        XCTAssertEqual(
            accessibility.operations.filter(\.isSize),
            [
                .setSize(requested.size),
                .setSize(requested.size),
                .setSize(requested.size),
                .setSize(requested.size),
            ])
        XCTAssertEqual(accessibility.operations.filter(\.isPosition).count, 2)
        XCTAssertEqual(accessibility.operations.filter(\.isFrameRead).count, 2)
    }

    func testRejectsPartialResultAfterBoundedRetries() {
        let requested = CGRect(x: 0, y: 24, width: 800, height: 1076)
        let partial = CGRect(x: 0, y: 250, width: 800, height: 850)
        let accessibility = AccessibilitySpy(
            enhancedUI: false,
            observedFrames: [partial, partial]
        )
        let applier = AccessibilityWindowFrameApplier(accessibility: accessibility)

        XCTAssertNil(applier.apply(requested, to: makeTarget()))
        XCTAssertEqual(accessibility.operations.filter(\.isFrameRead).count, 2)
    }

    func testAcceptsOnePointAccessibilityRounding() {
        let requested = CGRect(x: 100, y: 24, width: 801, height: 1076)
        let rounded = CGRect(x: 101, y: 25, width: 800, height: 1075)
        let accessibility = AccessibilitySpy(
            enhancedUI: false,
            observedFrames: [rounded]
        )
        let applier = AccessibilityWindowFrameApplier(accessibility: accessibility)

        XCTAssertEqual(applier.apply(requested, to: makeTarget()), rounded)
        XCTAssertEqual(accessibility.operations.filter(\.isFrameRead).count, 1)
    }

    private func makeTarget() -> AXWindowTarget {
        AXWindowTarget(
            element: AXUIElementCreateSystemWide(),
            processIdentifier: 42,
            visibleScreenFrame: CGRect(x: 0, y: 0, width: 1600, height: 1100),
            initialAppKitFrame: CGRect(x: 100, y: 100, width: 600, height: 600)
        )
    }
}

@MainActor
private final class AccessibilitySpy: WindowFrameAccessibilityAccessing {
    enum Operation: Equatable {
        case setEnhancedUI(Bool)
        case setPosition(CGPoint)
        case setSize(CGSize)
        case readFrame

        var isSize: Bool {
            if case .setSize = self { return true }
            return false
        }

        var isPosition: Bool {
            if case .setPosition = self { return true }
            return false
        }

        var isFrameRead: Bool {
            self == .readFrame
        }
    }

    private let applicationElement = AXUIElementCreateSystemWide()
    private let enhancedUI: Bool?
    private var observedFrames: [CGRect]
    private(set) var operations: [Operation] = []

    init(enhancedUI: Bool?, observedFrames: [CGRect]) {
        self.enhancedUI = enhancedUI
        self.observedFrames = observedFrames
    }

    func application(processIdentifier: pid_t) -> AXUIElement {
        applicationElement
    }

    func isSettable(_ element: AXUIElement, attribute: CFString) -> Bool {
        true
    }

    func bool(_ element: AXUIElement, attribute: CFString) -> Bool? {
        enhancedUI
    }

    func frame(_ element: AXUIElement) -> CGRect? {
        operations.append(.readFrame)
        guard !observedFrames.isEmpty else { return nil }
        return observedFrames.removeFirst()
    }

    func setBool(_ value: Bool, on element: AXUIElement, attribute: CFString) -> AXError {
        operations.append(.setEnhancedUI(value))
        return .success
    }

    func setPoint(_ point: CGPoint, on element: AXUIElement, attribute: CFString) -> AXError {
        operations.append(.setPosition(point))
        return .success
    }

    func setSize(_ size: CGSize, on element: AXUIElement, attribute: CFString) -> AXError {
        operations.append(.setSize(size))
        return .success
    }
}
