import ApplicationServices
import CoreGraphics
import Foundation

struct WindowActionResult: Equatable, Sendable {
    let action: WindowGestureAction
}

@MainActor
protocol WindowActionPerforming {
    func perform(_ action: WindowGestureAction, on target: AXWindowTarget) -> WindowActionResult?
}

@MainActor
final class WindowActionService: WindowActionPerforming {
    private let geometry: ScreenGeometryService
    private let frameApplier: any WindowFrameApplying

    init(
        geometry: ScreenGeometryService,
        frameApplier: (any WindowFrameApplying)? = nil
    ) {
        self.geometry = geometry
        self.frameApplier = frameApplier ?? AccessibilityWindowFrameApplier()
    }

    func perform(_ action: WindowGestureAction, on target: AXWindowTarget) -> WindowActionResult? {
        switch action {
        case .snapLeft, .snapRight:
            let halves = ScreenFrameCalculator.halves(of: target.visibleScreenFrame)
            let requestedFrame = action == .snapLeft ? halves.left : halves.right
            return resize(action, target: target, to: requestedFrame)
        case .minimize:
            return minimize(target)
        case .maximize:
            return resize(action, target: target, to: target.visibleScreenFrame)
        }
    }

    private func resize(
        _ action: WindowGestureAction,
        target: AXWindowTarget,
        to requestedFrame: CGRect
    ) -> WindowActionResult? {
        let requestedAXFrame = geometry.axRect(fromAppKit: requestedFrame)
        guard frameApplier.apply(requestedAXFrame, to: target) != nil else {
            return nil
        }

        return WindowActionResult(action: action)
    }

    private func minimize(_ target: AXWindowTarget) -> WindowActionResult? {
        guard AXBridge.isSettable(target.element, attribute: kAXMinimizedAttribute as CFString),
            AXBridge.setBool(
                true,
                on: target.element,
                attribute: kAXMinimizedAttribute as CFString
            ) == .success
        else {
            return nil
        }

        return WindowActionResult(action: .minimize)
    }
}
