import Foundation

struct SwipeGestureRecognizer: Sendable {
    private(set) var isTracking = false
    private(set) var accumulatedX: Double = 0
    private(set) var accumulatedY: Double = 0

    let configuration: GestureConfiguration

    init(configuration: GestureConfiguration = .default) {
        self.configuration = configuration
    }

    mutating func begin() {
        isTracking = true
        accumulatedX = 0
        accumulatedY = 0
    }

    mutating func update(deltaX: Double, deltaY: Double) {
        guard isTracking else { return }
        accumulatedX += deltaX
        accumulatedY += deltaY
    }

    mutating func finish() -> WindowGestureAction? {
        guard isTracking else { return nil }
        defer { reset() }

        let absoluteX = abs(accumulatedX)
        let absoluteY = abs(accumulatedY)
        let longestAxis = max(absoluteX, absoluteY)

        guard longestAxis >= configuration.deadZone,
            longestAxis >= configuration.triggerDistance
        else {
            return nil
        }

        if absoluteX >= absoluteY * configuration.dominanceRatio {
            // Normalized physical scroll values use positive X for fingers-left.
            return accumulatedX > 0 ? .snapLeft : .snapRight
        }

        if absoluteY >= absoluteX * configuration.dominanceRatio,
            accumulatedY > 0
        {
            // Positive Y represents fingers-down. Up is intentionally unsupported.
            return .minimize
        }

        return nil
    }

    mutating func cancel() {
        reset()
    }

    private mutating func reset() {
        isTracking = false
        accumulatedX = 0
        accumulatedY = 0
    }
}
