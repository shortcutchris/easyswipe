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

    init(geometry: ScreenGeometryService) {
        self.geometry = geometry
    }

    func perform(_ action: WindowGestureAction, on target: AXWindowTarget) -> WindowActionResult? {
        switch action {
        case .snapLeft, .snapRight:
            return snap(action, target: target)
        case .minimize:
            return minimize(target)
        }
    }

    private func snap(_ action: WindowGestureAction, target: AXWindowTarget) -> WindowActionResult? {
        guard AXBridge.isSettable(target.element, attribute: kAXPositionAttribute as CFString),
            AXBridge.isSettable(target.element, attribute: kAXSizeAttribute as CFString)
        else {
            return nil
        }

        let halves = ScreenFrameCalculator.halves(of: target.visibleScreenFrame)
        let requestedFrame = action == .snapLeft ? halves.left : halves.right
        let requestedAXFrame = geometry.axRect(fromAppKit: requestedFrame)

        let positionResult = AXBridge.setPoint(
            requestedAXFrame.origin,
            on: target.element,
            attribute: kAXPositionAttribute as CFString
        )
        let sizeResult = AXBridge.setSize(
            requestedAXFrame.size,
            on: target.element,
            attribute: kAXSizeAttribute as CFString
        )
        // Some applications change their origin while applying size constraints.
        let finalPositionResult = AXBridge.setPoint(
            requestedAXFrame.origin,
            on: target.element,
            attribute: kAXPositionAttribute as CFString
        )

        guard positionResult == .success || finalPositionResult == .success,
            sizeResult == .success,
            let resultingAXFrame = AXBridge.frame(target.element)
        else {
            return nil
        }

        let resultingFrame = geometry.appKitRect(fromAX: resultingAXFrame)
        guard frameChanged(from: target.initialAppKitFrame, to: resultingFrame) else {
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

    private func frameChanged(from oldFrame: CGRect, to newFrame: CGRect) -> Bool {
        let tolerance: CGFloat = 1
        return abs(oldFrame.minX - newFrame.minX) > tolerance
            || abs(oldFrame.minY - newFrame.minY) > tolerance
            || abs(oldFrame.width - newFrame.width) > tolerance
            || abs(oldFrame.height - newFrame.height) > tolerance
    }
}
