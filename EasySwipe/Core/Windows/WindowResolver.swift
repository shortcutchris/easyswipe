import AppKit
import ApplicationServices
import Foundation

@MainActor
protocol WindowResolving {
    func resolveTarget(at appKitPoint: CGPoint) -> AXWindowTarget?
}

@MainActor
final class WindowResolver: WindowResolving {
    private let systemWideElement = AXUIElementCreateSystemWide()
    private let geometry: ScreenGeometryService
    private let ownProcessIdentifier: pid_t

    private let interactiveRoles: Set<String> = [
        kAXButtonRole as String,
        kAXCheckBoxRole as String,
        kAXComboBoxRole as String,
        "AXBrowser",
        "AXDisclosureTriangle",
        "AXIncrementor",
        "AXLink",
        "AXList",
        "AXMenuButton",
        "AXOutline",
        kAXPopUpButtonRole as String,
        kAXRadioButtonRole as String,
        kAXScrollAreaRole as String,
        kAXSliderRole as String,
        kAXTabGroupRole as String,
        "AXTable",
        kAXTextAreaRole as String,
        kAXTextFieldRole as String,
        "AXToolbar",
    ]

    init(
        geometry: ScreenGeometryService,
        ownProcessIdentifier: pid_t = ProcessInfo.processInfo.processIdentifier
    ) {
        self.geometry = geometry
        self.ownProcessIdentifier = ownProcessIdentifier
    }

    func resolveTarget(at appKitPoint: CGPoint) -> AXWindowTarget? {
        guard let visibleFrame = geometry.visibleFrame(at: appKitPoint) else { return nil }

        let axPoint = geometry.axPoint(fromAppKit: appKitPoint)
        var hitElement: AXUIElement?
        let error = AXUIElementCopyElementAtPosition(
            systemWideElement,
            Float(axPoint.x),
            Float(axPoint.y),
            &hitElement
        )

        guard error == .success, let hitElement else { return nil }
        guard let window = enclosingNonInteractiveWindow(for: hitElement) else { return nil }

        var processIdentifier: pid_t = 0
        guard AXUIElementGetPid(window, &processIdentifier) == .success,
            processIdentifier != ownProcessIdentifier
        else {
            return nil
        }

        // Bound subsequent AX reads and writes for an unresponsive target app.
        // The timeout set on the application element applies to its descendants.
        let application = AXUIElementCreateApplication(processIdentifier)
        _ = AXUIElementSetMessagingTimeout(application, 0.2)

        guard AXBridge.bool(window, attribute: "AXFullScreen" as CFString) != true,
            let axFrame = AXBridge.frame(window)
        else {
            return nil
        }

        let titlebarHeight = estimatedTitlebarHeight(for: window, windowFrame: axFrame)
        let titlebarFrame = CGRect(
            x: axFrame.minX,
            y: axFrame.minY,
            width: axFrame.width,
            height: min(titlebarHeight, axFrame.height)
        )

        guard titlebarFrame.contains(axPoint) else { return nil }

        return AXWindowTarget(
            element: window,
            processIdentifier: processIdentifier,
            visibleScreenFrame: visibleFrame,
            initialAppKitFrame: geometry.appKitRect(fromAX: axFrame)
        )
    }

    private func enclosingNonInteractiveWindow(for element: AXUIElement) -> AXUIElement? {
        var current: AXUIElement? = element

        for _ in 0..<20 {
            guard let candidate = current else { return nil }
            let role = AXBridge.string(candidate, attribute: kAXRoleAttribute as CFString)

            if let role, interactiveRoles.contains(role) {
                return nil
            }

            if role == kAXWindowRole as String {
                return candidate
            }

            if let parent = AXBridge.element(candidate, attribute: kAXParentAttribute as CFString) {
                current = parent
                continue
            }

            // Some third-party accessibility trees omit parents but still
            // expose their containing window directly.
            return AXBridge.element(candidate, attribute: kAXWindowAttribute as CFString)
        }

        return nil
    }

    private func estimatedTitlebarHeight(for window: AXUIElement, windowFrame: CGRect) -> CGFloat {
        var height: CGFloat = 38

        if let closeButton = AXBridge.element(window, attribute: kAXCloseButtonAttribute as CFString),
            let buttonFrame = AXBridge.frame(closeButton)
        {
            height = max(height, buttonFrame.maxY - windowFrame.minY + 8)
        }

        if let title = AXBridge.element(window, attribute: kAXTitleUIElementAttribute as CFString),
            let titleFrame = AXBridge.frame(title)
        {
            height = max(height, titleFrame.maxY - windowFrame.minY + 8)
        }

        return min(max(height, 28), 64)
    }
}
