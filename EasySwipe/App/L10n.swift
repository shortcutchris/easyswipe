import Foundation

enum L10n {
    static var menuEnabled: String { text("menu.enabled", "Swindoo Enabled") }
    static var menuLaunchAtLogin: String { text("menu.launchAtLogin", "Launch at Login") }
    static var menuGestureGuide: String { text("menu.gestureGuide", "Gesture Guide…") }
    static var menuPermissions: String { text("menu.permissions", "Permissions…") }
    static var menuCheckForUpdates: String { text("menu.checkForUpdates", "Check for Updates…") }
    static var menuAbout: String { text("menu.about", "About Swindoo") }
    static var menuQuit: String { text("menu.quit", "Quit Swindoo") }

    static var onboardingTitle: String { text("onboarding.title", "Welcome to Swindoo") }
    static var onboardingSubtitle: String {
        text("onboarding.subtitle", "Arrange windows directly from their title bars.")
    }
    static var gestureLeft: String { text("gesture.left", "Swipe left to fill the left half") }
    static var gestureRight: String { text("gesture.right", "Swipe right to fill the right half") }
    static var gestureDown: String { text("gesture.down", "Swipe down to minimize") }
    static var gestureUp: String { text("gesture.up", "Swipe up to maximize") }
    static var deviceHint: String {
        text(
            "onboarding.deviceHint",
            "Use two fingers on a trackpad, or swipe on the touch surface of your Magic Mouse."
        )
    }
    static var permissionTitle: String { text("permission.title", "Accessibility Permission") }
    static var permissionExplanation: String {
        text(
            "permission.explanation",
            "Swindoo uses Accessibility to identify and arrange the window below your pointer. It never reads window contents."
        )
    }
    static var permissionGranted: String { text("permission.granted", "Permission granted") }
    static var permissionMissing: String { text("permission.missing", "Permission required") }
    static var permissionRequest: String { text("permission.request", "Grant Permission…") }
    static var permissionOpenSettings: String { text("permission.openSettings", "Open System Settings") }
    static var finishSetup: String { text("onboarding.finish", "Finish Setup") }
    static var close: String { text("common.close", "Close") }
    static var ok: String { text("common.ok", "OK") }

    static var guideTitle: String { text("guide.title", "Swindoo Gestures") }
    static var guideFooter: String {
        text("guide.footer", "Place the pointer over a window title bar, swipe, then lift your fingers.")
    }

    static var updateUnavailableTitle: String {
        text("update.unavailable.title", "Updates Not Configured")
    }
    static var updateUnavailableMessage: String {
        text(
            "update.unavailable.message",
            "This development build has no signed update feed. Release builds can be configured with a Sparkle appcast and public key."
        )
    }

    static var loginItemErrorTitle: String {
        text("login.error.title", "Could Not Change Login Setting")
    }
    static var loginItemRequiresApproval: String {
        text(
            "login.requiresApproval",
            "Allow Swindoo in System Settings > General > Login Items to finish enabling launch at login."
        )
    }

    static var hudLeftAnnouncement: String { text("hud.left", "Window arranged left") }
    static var hudRightAnnouncement: String { text("hud.right", "Window arranged right") }
    static var hudMinimizeAnnouncement: String { text("hud.minimize", "Window minimized") }
    static var hudMaximizeAnnouncement: String { text("hud.maximize", "Window maximized") }

    private static func text(_ key: String, _ fallback: String) -> String {
        NSLocalizedString(key, tableName: nil, bundle: .main, value: fallback, comment: "")
    }
}
