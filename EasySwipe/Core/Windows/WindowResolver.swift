import AppKit
import ApplicationServices
import Foundation

@MainActor
protocol WindowResolving {
    func resolveTarget(at appKitPoint: CGPoint) -> AXWindowTarget?
}

struct WindowCompatibilityProfile: Equatable, Sendable {
    let allowedTopRegionRoles: Set<String>
    let minimumTitlebarHeight: CGFloat
    let maximumAncestorDepth: Int

    init(bundleIdentifier: String?) {
        let isWarp = bundleIdentifier?.hasPrefix("dev.warp.Warp") == true
        allowedTopRegionRoles =
            isWarp
            ? [
                kAXTextAreaRole as String,
            ]
            : []
        minimumTitlebarHeight = isWarp ? 64 : 38
        maximumAncestorDepth = isWarp ? 40 : 20
    }

    func rejects(role: String, blockingControlRoles: Set<String>) -> Bool {
        guard blockingControlRoles.contains(role) else { return false }
        return !allowedTopRegionRoles.contains(role)
    }
}

@MainActor
final class WindowResolver: WindowResolving {
    private let systemWideElement = AXUIElementCreateSystemWide()
    private let geometry: ScreenGeometryService
    private let ownProcessIdentifier: pid_t

    // Only direct controls block a gesture. Container roles such as AXToolbar,
    // AXScrollArea, AXTabGroup, and AXWebArea are frequently used as the
    // accessibility surface for custom title bars in Electron, Chromium,
    // Catalyst, and unified-toolbar AppKit windows. Rejecting those ancestors
    // prevents the resolver from ever reaching their containing AXWindow.
    private let blockingControlRoles: Set<String> = [
        kAXButtonRole as String,
        kAXCheckBoxRole as String,
        kAXComboBoxRole as String,
        "AXDisclosureTriangle",
        "AXIncrementor",
        "AXLink",
        "AXMenuButton",
        kAXPopUpButtonRole as String,
        kAXRadioButtonRole as String,
        kAXSliderRole as String,
        "AXTab",
        kAXTextAreaRole as String,
        kAXTextFieldRole as String,
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

        var hitProcessIdentifier: pid_t = 0
        _ = AXUIElementGetPid(hitElement, &hitProcessIdentifier)
        let bundleIdentifier =
            NSRunningApplication(processIdentifier: hitProcessIdentifier)?.bundleIdentifier
        let compatibility = WindowCompatibilityProfile(bundleIdentifier: bundleIdentifier)

        guard
            let window = enclosingNonInteractiveWindow(
                for: hitElement,
                compatibility: compatibility
            )
        else { return nil }

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

        let titlebarHeight = estimatedTitlebarHeight(
            for: window,
            windowFrame: axFrame,
            minimumHeight: compatibility.minimumTitlebarHeight
        )
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

    private func enclosingNonInteractiveWindow(
        for element: AXUIElement,
        compatibility: WindowCompatibilityProfile
    ) -> AXUIElement? {
        var current: AXUIElement? = element
        let directWindow = AXBridge.element(element, attribute: kAXWindowAttribute as CFString)

        for _ in 0..<compatibility.maximumAncestorDepth {
            guard let candidate = current else { return nil }
            let role = AXBridge.string(candidate, attribute: kAXRoleAttribute as CFString)

            if let role,
                compatibility.rejects(role: role, blockingControlRoles: blockingControlRoles)
            {
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
            return directWindow
        }

        // Deep custom accessibility trees can exceed the conservative ancestor
        // walk even though the hit element exposes its window directly.
        return directWindow
    }

    private func estimatedTitlebarHeight(
        for window: AXUIElement,
        windowFrame: CGRect,
        minimumHeight: CGFloat
    ) -> CGFloat {
        var height = minimumHeight

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
