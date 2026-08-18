import AppKit
import Foundation

@MainActor
final class AppCoordinator {
    private let preferences: AppPreferences
    private let permissions: AccessibilityPermissionController
    private let loginItem: LoginItemController
    private let updateController: UpdateController
    private let statusMenu: StatusMenuController
    private let windowController: AppWindowController
    private let scrollMonitor: GlobalScrollMonitor
    private let gestureCoordinator: GestureCoordinator

    init() {
        let preferences = AppPreferences()
        let permissions = AccessibilityPermissionController()
        let loginItem = LoginItemController()
        let updateController = UpdateController()
        let statusMenu = StatusMenuController()
        let windowController = AppWindowController()
        let geometry = ScreenGeometryService()
        let resolver = WindowResolver(geometry: geometry)
        let actionService = WindowActionService(geometry: geometry)
        let hudPresenter = HUDPresenter()
        let gestureCoordinator = GestureCoordinator(
            resolver: resolver,
            actionService: actionService,
            hudPresenter: hudPresenter
        )
        let scrollMonitor = GlobalScrollMonitor { sample in
            gestureCoordinator.handle(sample)
        }

        self.preferences = preferences
        self.permissions = permissions
        self.loginItem = loginItem
        self.updateController = updateController
        self.statusMenu = statusMenu
        self.windowController = windowController
        self.gestureCoordinator = gestureCoordinator
        self.scrollMonitor = scrollMonitor

        configureCallbacks()
    }

    func start() {
        NSApp.setActivationPolicy(.accessory)

        // The release runner uses this short-lived path to prove that dyld can
        // load every embedded framework under the staged code signature.
        if ProcessInfo.processInfo.environment["EASYSWIPE_STARTUP_PROBE"] == "1" {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                NSApp.terminate(nil)
            }
            return
        }

        permissions.refresh()
        permissions.startPolling()
        loginItem.refresh()
        reconcileMonitoring()
        updateStatusMenu()

        if !preferences.hasCompletedOnboarding || !permissions.isTrusted {
            showOnboarding()
        }
    }

    func stop() {
        scrollMonitor.stop()
        gestureCoordinator.cancel()
        permissions.stopPolling()
    }

    private func configureCallbacks() {
        permissions.onTrustChanged = { [weak self] _ in
            self?.reconcileMonitoring()
            self?.updateStatusMenu()
        }

        statusMenu.onEnabledChanged = { [weak self] enabled in
            guard let self else { return }
            preferences.isEnabled = enabled
            reconcileMonitoring()
            updateStatusMenu()
        }

        statusMenu.onLaunchAtLoginChanged = { [weak self] enabled in
            guard let self else { return }
            loginItem.setEnabled(enabled)
            updateStatusMenu()
            showLoginItemErrorIfNeeded()
        }

        statusMenu.onShowGuide = { [weak self] in
            self?.windowController.showGuide()
        }

        statusMenu.onShowPermissions = { [weak self] in
            self?.showOnboarding()
        }

        statusMenu.onCheckForUpdates = { [weak self] in
            self?.updateController.checkForUpdates()
        }

        statusMenu.onWillOpen = { [weak self] in
            guard let self else { return }
            permissions.refresh()
            loginItem.refresh()
            updateStatusMenu()
        }
    }

    private func reconcileMonitoring() {
        if preferences.isEnabled && permissions.isTrusted {
            scrollMonitor.start()
        } else {
            scrollMonitor.stop()
            gestureCoordinator.cancel()
        }
    }

    private func updateStatusMenu() {
        statusMenu.update(
            enabled: preferences.isEnabled,
            launchAtLogin: loginItem.isEnabled,
            hasPermission: permissions.isTrusted
        )
    }

    private func showOnboarding() {
        permissions.startPolling()
        windowController.showOnboarding(
            permissions: permissions,
            loginItem: loginItem
        ) { [weak self] in
            guard let self else { return }
            preferences.hasCompletedOnboarding = true
            permissions.refresh()
            reconcileMonitoring()
            updateStatusMenu()
        }
    }

    private func showLoginItemErrorIfNeeded() {
        guard let error = loginItem.lastError else { return }
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = L10n.loginItemErrorTitle
        alert.informativeText = error
        alert.addButton(withTitle: L10n.ok)
        alert.runModal()
    }
}
