import Combine
import Foundation

@MainActor
final class AppPreferences: ObservableObject {
    private enum Key {
        static let enabled = "app.enabled"
        static let hudAnimationsEnabled = "hud.animationsEnabled"
        static let onboardingCompleted = "onboarding.completed"
        static let language = "interface.language"
        static let appearance = "interface.appearance"
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

    var onInterfaceChanged: (() -> Void)?
    @Published var language: InterfaceLanguage {
        didSet {
            defaults.set(language.rawValue, forKey: Key.language)
            onInterfaceChanged?()
        }
    }
    @Published var appearance: InterfaceAppearance {
        didSet {
            defaults.set(appearance.rawValue, forKey: Key.appearance)
            onInterfaceChanged?()
        }
    }
    @Published private(set) var systemRevision = 0

    func refreshSystemPreferences() {
        onInterfaceChanged?()
        systemRevision &+= 1
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        language = InterfaceLanguage(rawValue: defaults.string(forKey: Key.language) ?? "") ?? .system
        appearance = InterfaceAppearance(rawValue: defaults.string(forKey: Key.appearance) ?? "") ?? .system
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
