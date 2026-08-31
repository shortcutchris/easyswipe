import AppKit
import ApplicationServices
import Foundation

@MainActor
protocol WindowResolving {
    func resolveTarget(at appKitPoint: CGPoint) -> AXWindowTarget?
}

struct WindowCompatibilityProfile: Equatable, Sendable {
    let allowedTopRegionRoles: Set<String>
    let allowedTopRegionIdentifiers: Set<String>
    let allowedTopRegionActionsByRole: [String: Set<String>]
    let minimumTitlebarHeight: CGFloat
    let maximumAncestorDepth: Int
    let usesMeasuredTopToolbarFrame: Bool
    let allowsInteractiveMeasuredTopToolbar: Bool
    let measuredTopRegionIdentifiers: Set<String>

    init(bundleIdentifier: String?) {
        let isWarp = bundleIdentifier?.hasPrefix("dev.warp.Warp") == true
        let isWhatsApp = bundleIdentifier?.hasPrefix("net.whatsapp.WhatsApp") == true
        allowedTopRegionRoles =
            isWarp
            ? [
                kAXTextAreaRole as String
            ]
            : []
        allowedTopRegionIdentifiers =
            isWhatsApp
            ? [
                "NavigationBar_HeaderViewButton"
            ]
            : []
        allowedTopRegionActionsByRole =
            isWhatsApp
            ? [
                kAXGroupRole as String: [
                    kAXCancelAction as String,
                    "AXScrollToVisible",
                    kAXShowMenuAction as String,
                ]
            ]
            : [:]
        minimumTitlebarHeight = isWarp || isWhatsApp ? 64 : 38
        maximumAncestorDepth = 48
        // AXToolbar is a system accessibility role shared by AppKit and
        // SwiftUI windows. Geometry below ensures that only a toolbar which
        // macOS actually places at the top of this window can extend the
        // gesture surface or admit one of its interactive descendants.
        usesMeasuredTopToolbarFrame = true
        allowsInteractiveMeasuredTopToolbar = true
        // WhatsApp's split Catalyst chrome exposes the chat-list and active-chat
        // headers as two AXGroup elements rather than native AXToolbar roles.
        // Measuring both exact "Toolbar" regions keeps gestures available over
        // the active chat header without widening the surface into message content.
        measuredTopRegionIdentifiers = isWhatsApp ? ["Toolbar"] : []
    }
}

struct WindowMeasuredTopRegion: Equatable, Sendable {
    let frame: CGRect
    let allowsInteractiveHits: Bool

    init?(
        role: String?,
        identifier: String?,
        frame: CGRect,
        compatibility: WindowCompatibilityProfile
    ) {
        let isNativeToolbar = role == kAXToolbarRole as String
        let isCompatibilityTopRegion = identifier.map {
            compatibility.measuredTopRegionIdentifiers.contains($0)
        } == true
        guard isNativeToolbar || isCompatibilityTopRegion else { return nil }

        self.frame = frame
        // Compatibility regions such as WhatsApp's AXGroup header admit their
        // explicitly allow-listed drag surface, but never generic controls.
        allowsInteractiveHits = isNativeToolbar
    }
}

struct WindowToolbarRegionPolicy: Sendable {
    private let maximumTopToolbarHeight: CGFloat = 96
    private let frameTolerance: CGFloat = 2

    func accepts(
        point: CGPoint,
        toolbarFrame: CGRect,
        windowFrame: CGRect,
        compatibility: WindowCompatibilityProfile
    ) -> Bool {
        guard compatibility.usesMeasuredTopToolbarFrame,
            toolbarFrame.width > 0,
            toolbarFrame.height > 0,
            toolbarFrame.minY >= windowFrame.minY - frameTolerance,
            toolbarFrame.maxY <= windowFrame.minY + maximumTopToolbarHeight + frameTolerance,
            windowFrame.contains(point)
        else {
            return false
        }

        return toolbarFrame.intersection(windowFrame).contains(point)
    }

    func acceptsInteractiveHit(
        isInsideMeasuredTopToolbar: Bool,
        compatibility: WindowCompatibilityProfile
    ) -> Bool {
        compatibility.allowsInteractiveMeasuredTopToolbar && isInsideMeasuredTopToolbar
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
        identifier: String? = nil,
        actionNames: Set<String>,
        compatibility: WindowCompatibilityProfile
    ) -> Bool {
        if let identifier, compatibility.allowedTopRegionIdentifiers.contains(identifier) {
            return false
        }
        if let role, compatibility.allowedTopRegionRoles.contains(role) {
            return false
        }
        if let role,
            let allowedActions = compatibility.allowedTopRegionActionsByRole[role],
            actionNames.isSubset(of: allowedActions)
        {
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
    private struct HitResolution {
        let window: AXUIElement
        let encounteredInteractiveElement: Bool
    }

    private let systemWideElement = AXUIElementCreateSystemWide()
    private let geometry: ScreenGeometryService
    private let ownProcessIdentifier: pid_t
    private let hitRegionPolicy = WindowHitRegionPolicy()
    private let windowEligibilityPolicy = WindowEligibilityPolicy()
    private let toolbarRegionPolicy = WindowToolbarRegionPolicy()

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
            let hitResolution = enclosingWindow(
                for: hitElement,
                compatibility: compatibility
            )
        else { return nil }
        let window = hitResolution.window

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
        let isInsideTitlebar = titlebarFrame.contains(axPoint)

        // The ordinary titlebar path remains cheap. Accessibility descendants
        // are scanned only when the hit is interactive or lies below that
        // standard titlebar estimate and therefore needs toolbar evidence.
        let needsMeasuredTopToolbar =
            hitResolution.encounteredInteractiveElement || !isInsideTitlebar
        let containingMeasuredTopRegions =
            needsMeasuredTopToolbar
            ? measuredTopRegions(
                in: window,
                windowFrame: axFrame,
                compatibility: compatibility
            ).filter { region in
                toolbarRegionPolicy.accepts(
                    point: axPoint,
                    toolbarFrame: region.frame,
                    windowFrame: axFrame,
                    compatibility: compatibility
                )
            }
            : []
        let isInsideMeasuredTopToolbar = !containingMeasuredTopRegions.isEmpty
        let isInsideInteractiveMeasuredTopToolbar = containingMeasuredTopRegions.contains {
            $0.allowsInteractiveHits
        }

        if hitResolution.encounteredInteractiveElement,
            !toolbarRegionPolicy.acceptsInteractiveHit(
                isInsideMeasuredTopToolbar: isInsideInteractiveMeasuredTopToolbar,
                compatibility: compatibility
            )
        {
            return nil
        }

        guard isInsideTitlebar || isInsideMeasuredTopToolbar else { return nil }

        return AXWindowTarget(
            element: window,
            processIdentifier: processIdentifier,
            visibleScreenFrame: visibleFrame,
            initialAppKitFrame: geometry.appKitRect(fromAX: axFrame)
        )
    }

    private func enclosingWindow(
        for element: AXUIElement,
        compatibility: WindowCompatibilityProfile
    ) -> HitResolution? {
        var current: AXUIElement? = element
        var encounteredInteractiveElement = false
        let directWindow = AXBridge.element(element, attribute: kAXWindowAttribute as CFString)

        for _ in 0..<compatibility.maximumAncestorDepth {
            guard let candidate = current else { return nil }
            let role = AXBridge.string(candidate, attribute: kAXRoleAttribute as CFString)

            if hitRegionPolicy.rejects(
                role: role,
                identifier: AXBridge.string(
                    candidate,
                    attribute: kAXIdentifierAttribute as CFString
                ),
                actionNames: AXBridge.actionNames(candidate),
                compatibility: compatibility
            ) {
                guard compatibility.allowsInteractiveMeasuredTopToolbar else { return nil }
                encounteredInteractiveElement = true
            }

            if role == kAXWindowRole as String {
                return isEligibleWindow(candidate)
                    ? HitResolution(
                        window: candidate,
                        encounteredInteractiveElement: encounteredInteractiveElement
                    )
                    : nil
            }

            if let parent = AXBridge.element(candidate, attribute: kAXParentAttribute as CFString) {
                current = parent
                continue
            }

            // Some third-party accessibility trees omit parents but still
            // expose their containing window directly.
            return directWindow.flatMap {
                isEligibleWindow($0)
                    ? HitResolution(
                        window: $0,
                        encounteredInteractiveElement: encounteredInteractiveElement
                    )
                    : nil
            }
        }

        // Deep custom accessibility trees can exceed the conservative ancestor
        // walk even though the hit element exposes its window directly.
        return directWindow.flatMap {
            isEligibleWindow($0)
                ? HitResolution(
                    window: $0,
                    encounteredInteractiveElement: encounteredInteractiveElement
                )
                : nil
        }
    }

    private func measuredTopRegions(
        in window: AXUIElement,
        windowFrame: CGRect,
        compatibility: WindowCompatibilityProfile
    ) -> [WindowMeasuredTopRegion] {
        guard compatibility.usesMeasuredTopToolbarFrame else { return [] }

        let maximumDepth = 4
        let maximumElements = 64
        var pending = AXBridge.elements(
            window,
            attribute: kAXChildrenAttribute as CFString
        ).map { (element: $0, depth: 1) }
        var regions: [WindowMeasuredTopRegion] = []
        var inspectedElements = 0

        while !pending.isEmpty, inspectedElements < maximumElements {
            let candidate = pending.removeFirst()
            inspectedElements += 1

            let role = AXBridge.string(candidate.element, attribute: kAXRoleAttribute as CFString)
            let identifier = AXBridge.string(
                candidate.element,
                attribute: kAXIdentifierAttribute as CFString
            )
            if let frame = AXBridge.frame(candidate.element),
                let region = WindowMeasuredTopRegion(
                    role: role,
                    identifier: identifier,
                    frame: frame,
                    compatibility: compatibility
                )
            {
                if toolbarRegionPolicy.accepts(
                    point: CGPoint(x: frame.midX, y: frame.midY),
                    toolbarFrame: frame,
                    windowFrame: windowFrame,
                    compatibility: compatibility
                ) {
                    regions.append(region)
                }
                continue
            }

            guard candidate.depth < maximumDepth else { continue }
            if let frame = AXBridge.frame(candidate.element),
                frame.minY > windowFrame.minY + 98
            {
                continue
            }

            pending.append(
                contentsOf: AXBridge.elements(
                    candidate.element,
                    attribute: kAXChildrenAttribute as CFString
                ).map { (element: $0, depth: candidate.depth + 1) }
            )
        }

        return regions
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
