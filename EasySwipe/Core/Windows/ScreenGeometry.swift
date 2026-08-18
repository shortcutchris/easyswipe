import AppKit
import CoreGraphics

enum ScreenCoordinateConverter {
    static func axPoint(fromAppKit point: CGPoint, primaryScreenHeight: CGFloat) -> CGPoint {
        CGPoint(x: point.x, y: primaryScreenHeight - point.y)
    }

    static func appKitPoint(fromAX point: CGPoint, primaryScreenHeight: CGFloat) -> CGPoint {
        CGPoint(x: point.x, y: primaryScreenHeight - point.y)
    }

    static func axRect(fromAppKit rect: CGRect, primaryScreenHeight: CGFloat) -> CGRect {
        CGRect(
            x: rect.minX,
            y: primaryScreenHeight - rect.maxY,
            width: rect.width,
            height: rect.height
        )
    }

    static func appKitRect(fromAX rect: CGRect, primaryScreenHeight: CGFloat) -> CGRect {
        CGRect(
            x: rect.minX,
            y: primaryScreenHeight - rect.maxY,
            width: rect.width,
            height: rect.height
        )
    }
}

struct ScreenHalves: Equatable, Sendable {
    let left: CGRect
    let right: CGRect
}

enum ScreenFrameCalculator {
    static func halves(of visibleFrame: CGRect) -> ScreenHalves {
        let leftWidth = floor(visibleFrame.width / 2)
        let rightWidth = visibleFrame.width - leftWidth

        return ScreenHalves(
            left: CGRect(
                x: visibleFrame.minX,
                y: visibleFrame.minY,
                width: leftWidth,
                height: visibleFrame.height
            ),
            right: CGRect(
                x: visibleFrame.minX + leftWidth,
                y: visibleFrame.minY,
                width: rightWidth,
                height: visibleFrame.height
            )
        )
    }
}

@MainActor
final class ScreenGeometryService {
    var primaryScreenHeight: CGFloat {
        CGDisplayBounds(CGMainDisplayID()).height
    }

    func screen(at appKitPoint: CGPoint) -> NSScreen? {
        NSScreen.screens.first { screen in
            NSMouseInRect(appKitPoint, screen.frame, false)
        }
    }

    func visibleFrame(at appKitPoint: CGPoint) -> CGRect? {
        screen(at: appKitPoint)?.visibleFrame
    }

    func axPoint(fromAppKit point: CGPoint) -> CGPoint {
        ScreenCoordinateConverter.axPoint(
            fromAppKit: point,
            primaryScreenHeight: primaryScreenHeight
        )
    }

    func appKitRect(fromAX rect: CGRect) -> CGRect {
        ScreenCoordinateConverter.appKitRect(
            fromAX: rect,
            primaryScreenHeight: primaryScreenHeight
        )
    }

    func axRect(fromAppKit rect: CGRect) -> CGRect {
        ScreenCoordinateConverter.axRect(
            fromAppKit: rect,
            primaryScreenHeight: primaryScreenHeight
        )
    }
}
