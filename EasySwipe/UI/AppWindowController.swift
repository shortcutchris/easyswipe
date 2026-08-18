import AppKit
import SwiftUI

@MainActor
final class AppWindowController {
    private var onboardingWindow: NSWindow?
    private var guideWindow: NSWindow?

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
            rootView: OnboardingView(
                permissions: permissions,
                loginItem: loginItem,
                finish: { [weak self, weak window] in
                    finish()
                    window?.close()
                    self?.onboardingWindow = nil
                }
            )
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
            rootView: GestureGuideView { [weak self, weak window] in
                window?.close()
                self?.guideWindow = nil
            }
        )
        window.center()
        guideWindow = window
        present(window)
    }

    private func present(_ window: NSWindow) {
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }
}
