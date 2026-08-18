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
        maximumAncestorDepth = 48
    }
}

struct WindowHitRegionPolicy: Sendable {
    private let blockingRoles: Set<String> = [
        kAXButtonRole as String,
        kAXCheckBoxRole as String,
        kAXColorWellRole as String,
        kAXComboBoxRole as String,
        kAXDateFieldRole as String,
        kAXDockItemRole as String,
        kAXDrawerRole as String,
        kAXGrowAreaRole as String,
        kAXHelpTagRole as String,
        kAXIncrementorRole as String,
        kAXMenuBarItemRole as String,
        kAXMenuBarRole as String,
        kAXMenuButtonRole as String,
        kAXMenuItemRole as String,
        kAXMenuRole as String,
        kAXPopUpButtonRole as String,
        kAXRadioButtonRole as String,
        kAXRowRole as String,
        kAXScrollBarRole as String,
        kAXSheetRole as String,
        kAXSliderRole as String,
        kAXSplitterRole as String,
        kAXTextAreaRole as String,
        kAXTextFieldRole as String,
        kAXTimeFieldRole as String,
        "AXCell",
        "AXColumn",
        "AXDisclosureTriangle",
        "AXLink",
        "AXPopover",
        "AXTab",
        "AXTooltip",
    ]

    private let blockingActions: Set<String> = [
        kAXCancelAction as String,
        kAXConfirmAction as String,
        kAXDecrementAction as String,
        kAXIncrementAction as String,
        kAXPickAction as String,
        kAXPressAction as String,
        kAXShowAlternateUIAction as String,
        kAXShowDefaultUIAction as String,
    ]

    func rejects(
        role: String?,
        actionNames: Set<String>,
        compatibility: WindowCompatibilityProfile
    ) -> Bool {
        if let role, compatibility.allowedTopRegionRoles.contains(role) {
            return false
        }
        if let role, blockingRoles.contains(role) {
            return true
        }
        return !blockingActions.isDisjoint(with: actionNames)
    }
}

struct WindowEligibilityPolicy: Sendable {
    func accepts(subrole: String?, isModal: Bool, hasTitlebarEvidence: Bool) -> Bool {
        guard !isModal else { return false }

        switch subrole {
        case kAXStandardWindowSubrole:
            return true
        case kAXSystemDialogSubrole, kAXSystemFloatingWindowSubrole:
            return false
        default:
            // Dialogs, utility windows, and third-party windows with missing or
            // custom subroles remain eligible only when they expose a native
            // title or at least one standard titlebar control. This excludes
            // borderless overlays while preserving legitimate secondary windows.
            return hasTitlebarEvidence
        }
    }
}

@MainActor
final class WindowResolver: WindowResolving {
    private let systemWideElement = AXUIElementCreateSystemWide()
    private let geometry: ScreenGeometryService
    private let ownProcessIdentifier: pid_t
    private let hitRegionPolicy = WindowHitRegionPolicy()
    private let windowEligibilityPolicy = WindowEligibilityPolicy()

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
        guard AXUIElementGetPid(hitElement, &hitProcessIdentifier) == .success,
            hitProcessIdentifier != ownProcessIdentifier
        else {
            return nil
        }

        // Bound all subsequent AX reads for an unresponsive target app,
        // including the ancestor walk used to classify custom title bars.
        let application = AXUIElementCreateApplication(hitProcessIdentifier)
        _ = AXUIElementSetMessagingTimeout(application, 0.2)

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

            if hitRegionPolicy.rejects(
                role: role,
                actionNames: AXBridge.actionNames(candidate),
                compatibility: compatibility
            ) {
                return nil
            }

            if role == kAXWindowRole as String {
                return isEligibleWindow(candidate) ? candidate : nil
            }

            if let parent = AXBridge.element(candidate, attribute: kAXParentAttribute as CFString) {
                current = parent
                continue
            }

            // Some third-party accessibility trees omit parents but still
            // expose their containing window directly.
            return directWindow.flatMap { isEligibleWindow($0) ? $0 : nil }
        }

        // Deep custom accessibility trees can exceed the conservative ancestor
        // walk even though the hit element exposes its window directly.
        return directWindow.flatMap { isEligibleWindow($0) ? $0 : nil }
    }

    private func isEligibleWindow(_ window: AXUIElement) -> Bool {
        let subrole = AXBridge.string(window, attribute: kAXSubroleAttribute as CFString)
        let isModal = AXBridge.bool(window, attribute: kAXModalAttribute as CFString) == true
        let hasTitlebarEvidence =
            AXBridge.element(window, attribute: kAXCloseButtonAttribute as CFString) != nil
            || AXBridge.element(window, attribute: kAXMinimizeButtonAttribute as CFString) != nil
            || AXBridge.element(window, attribute: kAXZoomButtonAttribute as CFString) != nil
            || AXBridge.element(window, attribute: kAXTitleUIElementAttribute as CFString) != nil

        return windowEligibilityPolicy.accepts(
            subrole: subrole,
            isModal: isModal,
            hasTitlebarEvidence: hasTitlebarEvidence
        )
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
