import ApplicationServices
import CoreGraphics
import Foundation
import OSLog

@MainActor
protocol WindowFrameApplying {
    func apply(_ requestedFrame: CGRect, to target: AXWindowTarget) -> CGRect?
}

@MainActor
protocol WindowFrameAccessibilityAccessing {
    func application(processIdentifier: pid_t) -> AXUIElement
    func isSettable(_ element: AXUIElement, attribute: CFString) -> Bool
    func bool(_ element: AXUIElement, attribute: CFString) -> Bool?
    func frame(_ element: AXUIElement) -> CGRect?
    func setBool(_ value: Bool, on element: AXUIElement, attribute: CFString) -> AXError
    func setPoint(_ point: CGPoint, on element: AXUIElement, attribute: CFString) -> AXError
    func setSize(_ size: CGSize, on element: AXUIElement, attribute: CFString) -> AXError
}

@MainActor
struct SystemWindowFrameAccessibilityAccessor: WindowFrameAccessibilityAccessing {
    func application(processIdentifier: pid_t) -> AXUIElement {
        AXUIElementCreateApplication(processIdentifier)
    }

    func isSettable(_ element: AXUIElement, attribute: CFString) -> Bool {
        AXBridge.isSettable(element, attribute: attribute)
    }

    func bool(_ element: AXUIElement, attribute: CFString) -> Bool? {
        AXBridge.bool(element, attribute: attribute)
    }

    func frame(_ element: AXUIElement) -> CGRect? {
        AXBridge.frame(element)
    }

    func setBool(_ value: Bool, on element: AXUIElement, attribute: CFString) -> AXError {
        AXBridge.setBool(value, on: element, attribute: attribute)
    }

    func setPoint(_ point: CGPoint, on element: AXUIElement, attribute: CFString) -> AXError {
        AXBridge.setPoint(point, on: element, attribute: attribute)
    }

    func setSize(_ size: CGSize, on element: AXUIElement, attribute: CFString) -> AXError {
        AXBridge.setSize(size, on: element, attribute: attribute)
    }
}

@MainActor
final class AccessibilityWindowFrameApplier: WindowFrameApplying {
    private static let enhancedUserInterfaceAttribute = "AXEnhancedUserInterface" as CFString

    private let accessibility: any WindowFrameAccessibilityAccessing
    private let maximumAttempts: Int
    private let tolerance: CGFloat
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.shortcutchris.EasySwipe",
        category: "WindowFrame"
    )

    init(
        accessibility: any WindowFrameAccessibilityAccessing =
            SystemWindowFrameAccessibilityAccessor(),
        maximumAttempts: Int = 2,
        tolerance: CGFloat = 1
    ) {
        self.accessibility = accessibility
        self.maximumAttempts = max(1, maximumAttempts)
        self.tolerance = max(0, tolerance)
    }

    func apply(_ requestedFrame: CGRect, to target: AXWindowTarget) -> CGRect? {
        guard
            accessibility.isSettable(
                target.element,
                attribute: kAXPositionAttribute as CFString
            ),
            accessibility.isSettable(
                target.element,
                attribute: kAXSizeAttribute as CFString
            )
        else {
            return nil
        }

        let application = accessibility.application(processIdentifier: target.processIdentifier)
        let enhancedUIWasEnabled =
            accessibility.bool(
                application,
                attribute: Self.enhancedUserInterfaceAttribute
            ) == true

        if enhancedUIWasEnabled {
            _ = accessibility.setBool(
                false,
                on: application,
                attribute: Self.enhancedUserInterfaceAttribute
            )
        }

        defer {
            if enhancedUIWasEnabled {
                _ = accessibility.setBool(
                    true,
                    on: application,
                    attribute: Self.enhancedUserInterfaceAttribute
                )
            }
        }

        var observedFrame: CGRect?

        for attempt in 1...maximumAttempts {
            // macOS can constrain the first size operation to the window's current display.
            // Applying size again after positioning makes the requested frame authoritative.
            let initialSizeResult = accessibility.setSize(
                requestedFrame.size,
                on: target.element,
                attribute: kAXSizeAttribute as CFString
            )
            let positionResult = accessibility.setPoint(
                requestedFrame.origin,
                on: target.element,
                attribute: kAXPositionAttribute as CFString
            )
            let finalSizeResult = accessibility.setSize(
                requestedFrame.size,
                on: target.element,
                attribute: kAXSizeAttribute as CFString
            )

            guard positionResult == .success,
                initialSizeResult == .success || finalSizeResult == .success
            else {
                return nil
            }

            observedFrame = accessibility.frame(target.element)
            if let observedFrame, matches(observedFrame, requestedFrame) {
                return observedFrame
            }

            logger.debug(
                "Window frame correction \(attempt, privacy: .public)/\(self.maximumAttempts, privacy: .public); requested=\(String(describing: requestedFrame), privacy: .public), observed=\(String(describing: observedFrame), privacy: .public)"
            )
        }

        logger.error(
            "Window did not reach requested frame; requested=\(String(describing: requestedFrame), privacy: .public), observed=\(String(describing: observedFrame), privacy: .public)"
        )
        return nil
    }

    private func matches(_ actual: CGRect, _ requested: CGRect) -> Bool {
        abs(actual.minX - requested.minX) <= tolerance
            && abs(actual.minY - requested.minY) <= tolerance
            && abs(actual.width - requested.width) <= tolerance
            && abs(actual.height - requested.height) <= tolerance
    }
}
