import CoreGraphics
import Foundation

struct HUDIconTransform: Equatable, Sendable {
    let translationX: CGFloat
    let translationY: CGFloat
    let scaleX: CGFloat
    let scaleY: CGFloat

    static let identity = HUDIconTransform(
        translationX: 0,
        translationY: 0,
        scaleX: 1,
        scaleY: 1
    )
}

enum SwindooMotion {
    static let appearanceDuration: TimeInterval = 0.09
    static let feedbackDuration: TimeInterval = 0.13
    static let dismissalDuration: TimeInterval = 0.14
    static let appearanceScale: CGFloat = 0.94

    static func shouldAnimate(preferenceEnabled: Bool, reduceMotion: Bool) -> Bool {
        preferenceEnabled && !reduceMotion
    }

    static func previewStartTransform(for action: WindowGestureAction) -> HUDIconTransform {
        switch action {
        case .snapLeft:
            HUDIconTransform(translationX: 2, translationY: 0, scaleX: 1, scaleY: 1)
        case .snapRight:
            HUDIconTransform(translationX: -2, translationY: 0, scaleX: 1, scaleY: 1)
        case .minimize:
            HUDIconTransform(translationX: 0, translationY: 2, scaleX: 1, scaleY: 1)
        case .maximize:
            HUDIconTransform(translationX: 0, translationY: -2, scaleX: 1, scaleY: 1)
        }
    }

    static func confirmationTransforms(for action: WindowGestureAction) -> [HUDIconTransform] {
        let emphasis: HUDIconTransform
        switch action {
        case .snapLeft:
            emphasis = HUDIconTransform(
                translationX: -4,
                translationY: 0,
                scaleX: 1.08,
                scaleY: 1.08
            )
        case .snapRight:
            emphasis = HUDIconTransform(
                translationX: 4,
                translationY: 0,
                scaleX: 1.08,
                scaleY: 1.08
            )
        case .minimize:
            emphasis = HUDIconTransform(
                translationX: 0,
                translationY: -4,
                scaleX: 0.92,
                scaleY: 0.62
            )
        case .maximize:
            emphasis = HUDIconTransform(
                translationX: 0,
                translationY: 0,
                scaleX: 1.14,
                scaleY: 1.14
            )
        }
        return [.identity, emphasis, .identity]
    }
}
