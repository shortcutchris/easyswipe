import AppKit
import Foundation

enum PhysicalScrollPhase: Equatable, Sendable {
    case mayBegin
    case began
    case changed
    case ended
    case cancelled
    case unspecified
}

struct PhysicalScrollDelta: Equatable, Sendable {
    let x: Double
    let y: Double
}

enum ScrollDeltaNormalizer {
    static func physical(
        deltaX: Double,
        deltaY: Double,
        isDirectionInvertedFromDevice: Bool
    ) -> PhysicalScrollDelta {
        let inversion = isDirectionInvertedFromDevice ? -1.0 : 1.0
        return PhysicalScrollDelta(x: deltaX * inversion, y: deltaY * inversion)
    }
}

struct ScrollSample: Equatable, Sendable {
    var physicalDeltaX: Double
    var physicalDeltaY: Double
    var phase: PhysicalScrollPhase
    var isMomentum: Bool
    var isPrecise: Bool
    var locationX: Double
    var locationY: Double
    var timestamp: TimeInterval

    var location: CGPoint {
        CGPoint(x: locationX, y: locationY)
    }

    init(
        physicalDeltaX: Double,
        physicalDeltaY: Double,
        phase: PhysicalScrollPhase,
        isMomentum: Bool = false,
        isPrecise: Bool = true,
        locationX: Double = 0,
        locationY: Double = 0,
        timestamp: TimeInterval = 0
    ) {
        self.physicalDeltaX = physicalDeltaX
        self.physicalDeltaY = physicalDeltaY
        self.phase = phase
        self.isMomentum = isMomentum
        self.isPrecise = isPrecise
        self.locationX = locationX
        self.locationY = locationY
        self.timestamp = timestamp
    }

    init(event: NSEvent) {
        // AppKit pre-applies the user's natural-scrolling preference. Undo that
        // preference so the values consistently describe physical finger motion.
        // In AppKit's device-relative convention left is positive X and down
        // is negative Y.
        let delta = ScrollDeltaNormalizer.physical(
            deltaX: Double(event.scrollingDeltaX),
            deltaY: Double(event.scrollingDeltaY),
            isDirectionInvertedFromDevice: event.isDirectionInvertedFromDevice
        )

        physicalDeltaX = delta.x
        physicalDeltaY = delta.y
        phase = Self.phase(from: event.phase)
        isMomentum = !event.momentumPhase.isEmpty
        isPrecise = event.hasPreciseScrollingDeltas

        let pointer = NSEvent.mouseLocation
        locationX = pointer.x
        locationY = pointer.y
        timestamp = event.timestamp
    }

    private static func phase(from phase: NSEvent.Phase) -> PhysicalScrollPhase {
        if phase.contains(.cancelled) { return .cancelled }
        if phase.contains(.ended) { return .ended }
        if phase.contains(.began) { return .began }
        if phase.contains(.changed) { return .changed }
        if phase.contains(.mayBegin) { return .mayBegin }
        return .unspecified
    }
}
