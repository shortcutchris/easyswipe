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
    private var localeObserver: NSObjectProtocol?
    private var settingsShortcutMonitor: Any?
    private let isIsolatedQA = ProcessInfo.processInfo.environment["SWINDOO_QA_SUITE"]?.hasPrefix("Swindoo.QA.") == true

    init() {
        let qaSuite = ProcessInfo.processInfo.environment["SWINDOO_QA_SUITE"]
        let defaults = qaSuite.flatMap { $0.hasPrefix("Swindoo.QA.") ? UserDefaults(suiteName: $0) : nil } ?? .standard
        let preferences = AppPreferences(defaults: defaults)
        L10n.language = preferences.language
        let permissions = AccessibilityPermissionController()
        let loginItem = LoginItemController()
        let updateController = UpdateController(defaults: defaults)
        let statusMenu = StatusMenuController()
        let windowController = AppWindowController(preferences: preferences)
        let geometry = ScreenGeometryService()
        let resolver = WindowResolver(geometry: geometry)
        let actionService = WindowActionService(geometry: geometry)
        let hudPresenter = HUDPresenter {
            preferences.areHUDAnimationsEnabled
        }
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
        updateController.isBusy = { [weak gestureCoordinator] in gestureCoordinator?.isBusyForUpdate ?? false }
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

        settingsShortcutMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.modifierFlags.intersection(.deviceIndependentFlagsMask) == .command,
               event.charactersIgnoringModifiers == "," {
                MainActor.assumeIsolated { self?.showSettings() }
                return nil
            }
            return event
        }

        if ProcessInfo.processInfo.environment["SWINDOO_QA_SUITE"]?.hasPrefix("Swindoo.QA.") == true {
            windowController.refreshInterface()
            updateStatusMenu()
            showSettings()
            return // Explicit isolated UI QA: no gesture monitoring, login writes or update polling.
        }

        permissions.refresh()
        windowController.refreshInterface()
        updateController.start()
        localeObserver = NotificationCenter.default.addObserver(forName: NSLocale.currentLocaleDidChangeNotification,
                                                                object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.preferences.refreshSystemPreferences() }
        }
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
        updateController.stop()
        if let localeObserver { NotificationCenter.default.removeObserver(localeObserver) }
        if let settingsShortcutMonitor { NSEvent.removeMonitor(settingsShortcutMonitor) }
    }

    private func configureCallbacks() {
        preferences.onInterfaceChanged = { [weak self] in
            guard let self else { return }
            L10n.language = preferences.language
            windowController.refreshInterface()
            statusMenu.refreshLanguage()
            loginItem.refresh()
        }
        statusMenu.onShowSettings = { [weak self] in self?.showSettings() }
        statusMenu.onShowAbout = { [weak self] in
            self?.windowController.showAbout { [weak self] in
                guard let self else { return }
                showSettings(page: .updates)
                if !isIsolatedQA { updateController.checkForUpdates() }
            }
        }
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
            guard let self, !isIsolatedQA else { return }
            loginItem.setEnabled(enabled)
            updateStatusMenu()
            showLoginItemErrorIfNeeded()
        }

        statusMenu.onAnimationsEnabledChanged = { [weak self] enabled in
            guard let self else { return }
            preferences.areHUDAnimationsEnabled = enabled
            updateStatusMenu()
        }

        statusMenu.onShowGuide = { [weak self] in
            self?.windowController.showGuide()
        }

        statusMenu.onShowPermissions = { [weak self] in
            self?.showOnboarding()
        }

        statusMenu.onCheckForUpdates = { [weak self] in
            guard let self else { return }
            showSettings(page: .updates)
            if !isIsolatedQA { updateController.checkForUpdates() }
        }

        statusMenu.onWillOpen = { [weak self] in
            guard let self else { return }
            permissions.refresh()
            loginItem.refresh()
            updateStatusMenu()
        }
    }

    private func showSettings(page: SettingsNavigation.Page? = nil) {
        windowController.showSettings(updates: updateController, loginItem: loginItem, page: page, onBehaviorChanged: { [weak self] in
            self?.reconcileMonitoring()
            self?.updateStatusMenu()
        }, showGuide: { [weak self] in self?.windowController.showGuide() })
    }

    private func reconcileMonitoring() {
        guard !isIsolatedQA else { return }
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
            animationsEnabled: preferences.areHUDAnimationsEnabled,
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
