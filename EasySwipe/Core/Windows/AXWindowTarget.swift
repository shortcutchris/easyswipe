import ApplicationServices
import CoreGraphics
import Foundation

@MainActor
final class AXWindowTarget {
    let element: AXUIElement
    let processIdentifier: pid_t
    let visibleScreenFrame: CGRect
    let initialAppKitFrame: CGRect

    init(
        element: AXUIElement,
        processIdentifier: pid_t,
        visibleScreenFrame: CGRect,
        initialAppKitFrame: CGRect
    ) {
        self.element = element
        self.processIdentifier = processIdentifier
        self.visibleScreenFrame = visibleScreenFrame
        self.initialAppKitFrame = initialAppKitFrame
    }
}
