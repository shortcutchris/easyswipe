import Combine
import Foundation

@MainActor
final class AppPreferences: ObservableObject {
    private enum Key {
        static let enabled = "app.enabled"
        static let hudAnimationsEnabled = "hud.animationsEnabled"
        static let onboardingCompleted = "onboarding.completed"
    }

    @Published var isEnabled: Bool {
        didSet { defaults.set(isEnabled, forKey: Key.enabled) }
    }

    @Published var hasCompletedOnboarding: Bool {
        didSet { defaults.set(hasCompletedOnboarding, forKey: Key.onboardingCompleted) }
    }

    @Published var areHUDAnimationsEnabled: Bool {
        didSet { defaults.set(areHUDAnimationsEnabled, forKey: Key.hudAnimationsEnabled) }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if defaults.object(forKey: Key.enabled) == nil {
            isEnabled = true
        } else {
            isEnabled = defaults.bool(forKey: Key.enabled)
        }
        if defaults.object(forKey: Key.hudAnimationsEnabled) == nil {
            areHUDAnimationsEnabled = true
        } else {
            areHUDAnimationsEnabled = defaults.bool(forKey: Key.hudAnimationsEnabled)
        }
        hasCompletedOnboarding = defaults.bool(forKey: Key.onboardingCompleted)
    }
}
