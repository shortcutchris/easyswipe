import Foundation

enum WindowGestureAction: String, CaseIterable, Equatable, Sendable {
    case snapLeft
    case snapRight
    case minimize
    case maximize
}

struct GestureConfiguration: Equatable, Sendable {
    var deadZone: Double = 10
    var triggerDistance: Double = 44
    var dominanceRatio: Double = 1.35
    var fallbackEndDelay: TimeInterval = 0.14

    static let `default` = GestureConfiguration()
}
