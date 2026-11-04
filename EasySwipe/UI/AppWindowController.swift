import AppKit
import SwiftUI

@MainActor
final class AppWindowController {
    private let preferences: AppPreferences
    private var onboardingWindow: NSWindow?
    private var guideWindow: NSWindow?
    private var settingsWindow: NSWindow?
    private var aboutWindow: NSWindow?
    private let settingsNavigation = SettingsNavigation()

    init(preferences: AppPreferences) { self.preferences = preferences }

    func refreshInterface() {
        NSApp.appearance = preferences.appearance.nsAppearance
        for window in NSApp.windows { window.appearance = preferences.appearance.nsAppearance }
        onboardingWindow?.title = L10n.onboardingTitle
        guideWindow?.title = L10n.guideTitle
        settingsWindow?.title = L10n.text("settings.title")
        aboutWindow?.title = L10n.menuAbout
    }

    func showAbout(checkForUpdates: @escaping () -> Void) {
        if let aboutWindow { present(aboutWindow); return }
        let window = NSWindow(contentRect: .zero, styleMask: [.titled, .closable], backing: .buffered, defer: false)
        window.title = L10n.menuAbout
        window.isReleasedWhenClosed = false
        window.contentViewController = NSHostingController(rootView: LocalizedRoot(preferences: preferences) {
            VStack(spacing: 16) {
                Image(nsImage: NSApp.applicationIconImage).resizable().frame(width: 80, height: 80)
                Text("Swindoo").font(.title.bold())
                Text("\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "–") (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "–"))")
                    .foregroundStyle(.secondary)
                Text("Copyright © 2026 shortcutchris").font(.caption).foregroundStyle(.secondary)
                Button(L10n.menuCheckForUpdates, action: checkForUpdates)
            }.padding(28).frame(width: 340)
        })
        window.center()
        aboutWindow = window
        present(window)
    }

    func showSettings(updates: UpdateController, loginItem: LoginItemController,
                      page: SettingsNavigation.Page? = nil,
                      onBehaviorChanged: @escaping () -> Void, showGuide: @escaping () -> Void) {
        if let page { settingsNavigation.page = page }
        if let settingsWindow { present(settingsWindow); return }
        let window = NSWindow(contentRect: .zero, styleMask: [.titled, .closable], backing: .buffered, defer: false)
        window.title = L10n.text("settings.title")
        window.isReleasedWhenClosed = false
        window.contentViewController = NSHostingController(rootView: LocalizedRoot(preferences: preferences) {
            AppSettingsView(navigation: self.settingsNavigation, preferences: self.preferences, updates: updates, loginItem: loginItem,
                            onBehaviorChanged: onBehaviorChanged, showGuide: showGuide)
        })
        window.center()
        settingsWindow = window
        present(window)
    }

    func showOnboarding(
        permissions: AccessibilityPermissionController,
        loginItem: LoginItemController,
        finish: @escaping () -> Void
    ) {
        if let onboardingWindow {
            present(onboardingWindow)
            return
        }

        let window = NSWindow(
            contentRect: .zero,
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = L10n.onboardingTitle
        window.isReleasedWhenClosed = false
        window.titlebarAppearsTransparent = true
        window.contentViewController = NSHostingController(
            rootView: LocalizedRoot(preferences: preferences) { OnboardingView(
                permissions: permissions,
                loginItem: loginItem,
                finish: { [weak self, weak window] in
                    finish()
                    window?.close()
                    self?.onboardingWindow = nil
                }
            ) }
        )
        window.center()
        onboardingWindow = window
        present(window)
    }

    func showGuide() {
        if let guideWindow {
            present(guideWindow)
            return
        }

        let window = NSWindow(
            contentRect: .zero,
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = L10n.guideTitle
        window.isReleasedWhenClosed = false
        window.contentViewController = NSHostingController(
            rootView: LocalizedRoot(preferences: preferences) { GestureGuideView { [weak self, weak window] in
                window?.close()
                self?.guideWindow = nil
            } }
        )
        window.center()
        guideWindow = window
        present(window)
    }

    private func present(_ window: NSWindow) {
        window.appearance = preferences.appearance.nsAppearance
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }
}
