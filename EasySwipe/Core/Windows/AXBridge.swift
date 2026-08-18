import ApplicationServices
import CoreGraphics
import Foundation

@MainActor
enum AXBridge {
    static func value(_ element: AXUIElement, attribute: CFString) -> CFTypeRef? {
        var value: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(element, attribute, &value)
        return error == .success ? value : nil
    }

    static func element(_ element: AXUIElement, attribute: CFString) -> AXUIElement? {
        guard let value = value(element, attribute: attribute),
            CFGetTypeID(value) == AXUIElementGetTypeID()
        else {
            return nil
        }
        return unsafeDowncast(value, to: AXUIElement.self)
    }

    static func string(_ element: AXUIElement, attribute: CFString) -> String? {
        value(element, attribute: attribute) as? String
    }

    static func bool(_ element: AXUIElement, attribute: CFString) -> Bool? {
        guard let value = value(element, attribute: attribute) else { return nil }
        if CFGetTypeID(value) == CFBooleanGetTypeID() {
            return CFBooleanGetValue(unsafeDowncast(value, to: CFBoolean.self))
        }
        return (value as? NSNumber)?.boolValue
    }

    static func point(_ element: AXUIElement, attribute: CFString) -> CGPoint? {
        guard let value = value(element, attribute: attribute),
            CFGetTypeID(value) == AXValueGetTypeID()
        else {
            return nil
        }

        let axValue = unsafeDowncast(value, to: AXValue.self)
        guard AXValueGetType(axValue) == .cgPoint else { return nil }
        var point = CGPoint.zero
        return AXValueGetValue(axValue, .cgPoint, &point) ? point : nil
    }

    static func size(_ element: AXUIElement, attribute: CFString) -> CGSize? {
        guard let value = value(element, attribute: attribute),
            CFGetTypeID(value) == AXValueGetTypeID()
        else {
            return nil
        }

        let axValue = unsafeDowncast(value, to: AXValue.self)
        guard AXValueGetType(axValue) == .cgSize else { return nil }
        var size = CGSize.zero
        return AXValueGetValue(axValue, .cgSize, &size) ? size : nil
    }

    static func frame(_ element: AXUIElement) -> CGRect? {
        guard let point = point(element, attribute: kAXPositionAttribute as CFString),
            let size = size(element, attribute: kAXSizeAttribute as CFString),
            size.width > 0,
            size.height > 0
        else {
            return nil
        }
        return CGRect(origin: point, size: size)
    }

    static func isSettable(_ element: AXUIElement, attribute: CFString) -> Bool {
        var settable = DarwinBoolean(false)
        let error = AXUIElementIsAttributeSettable(element, attribute, &settable)
        return error == .success && settable.boolValue
    }

    static func setPoint(_ point: CGPoint, on element: AXUIElement, attribute: CFString) -> AXError {
        var point = point
        guard let value = AXValueCreate(.cgPoint, &point) else { return .illegalArgument }
        return AXUIElementSetAttributeValue(element, attribute, value)
    }

    static func setSize(_ size: CGSize, on element: AXUIElement, attribute: CFString) -> AXError {
        var size = size
        guard let value = AXValueCreate(.cgSize, &size) else { return .illegalArgument }
        return AXUIElementSetAttributeValue(element, attribute, value)
    }

    static func setBool(_ value: Bool, on element: AXUIElement, attribute: CFString) -> AXError {
        AXUIElementSetAttributeValue(
            element,
            attribute,
            value ? kCFBooleanTrue : kCFBooleanFalse
        )
    }
}
