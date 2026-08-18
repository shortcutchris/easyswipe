import Combine
import Foundation

@MainActor
final class AppPreferences: ObservableObject {
    private enum Key {
        static let enabled = "app.enabled"
        static let onboardingCompleted = "onboarding.completed"
    }

    @Published var isEnabled: Bool {
        didSet { defaults.set(isEnabled, forKey: Key.enabled) }
    }

    @Published var hasCompletedOnboarding: Bool {
        didSet { defaults.set(hasCompletedOnboarding, forKey: Key.onboardingCompleted) }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if defaults.object(forKey: Key.enabled) == nil {
            isEnabled = true
        } else {
            isEnabled = defaults.bool(forKey: Key.enabled)
        }
        hasCompletedOnboarding = defaults.bool(forKey: Key.onboardingCompleted)
    }
}
