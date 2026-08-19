import AppKit
import Foundation

@MainActor
final class StatusMenuController: NSObject, NSMenuDelegate {
    var onEnabledChanged: ((Bool) -> Void)?
    var onLaunchAtLoginChanged: ((Bool) -> Void)?
    var onShowGuide: (() -> Void)?
    var onShowPermissions: (() -> Void)?
    var onCheckForUpdates: (() -> Void)?
    var onWillOpen: (() -> Void)?

    private let statusItem: NSStatusItem
    private let menu = NSMenu()
    private let enabledItem: NSMenuItem
    private let loginItem: NSMenuItem
    private let permissionItem: NSMenuItem

    private(set) var enabled = true
    private(set) var launchAtLogin = false
    private(set) var hasPermission = false

    override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        enabledItem = NSMenuItem(title: L10n.menuEnabled, action: nil, keyEquivalent: "")
        loginItem = NSMenuItem(title: L10n.menuLaunchAtLogin, action: nil, keyEquivalent: "")
        permissionItem = NSMenuItem(title: L10n.menuPermissions, action: nil, keyEquivalent: "")
        super.init()

        configureStatusItem()
        configureMenu()
    }

    func update(enabled: Bool, launchAtLogin: Bool, hasPermission: Bool) {
        self.enabled = enabled
        self.launchAtLogin = launchAtLogin
        self.hasPermission = hasPermission
        refreshAppearance()
    }

    func menuWillOpen(_ menu: NSMenu) {
        onWillOpen?()
        refreshAppearance()
    }

    private func configureStatusItem() {
        statusItem.button?.toolTip = "Swindoo"
        statusItem.menu = menu
        refreshStatusImage()
    }

    private func configureMenu() {
        menu.delegate = self

        enabledItem.target = self
        enabledItem.action = #selector(toggleEnabled)
        menu.addItem(enabledItem)

        loginItem.target = self
        loginItem.action = #selector(toggleLaunchAtLogin)
        menu.addItem(loginItem)

        menu.addItem(.separator())

        let guideItem = NSMenuItem(
            title: L10n.menuGestureGuide,
            action: #selector(showGuide),
            keyEquivalent: ""
        )
        guideItem.target = self
        menu.addItem(guideItem)

        permissionItem.target = self
        permissionItem.action = #selector(showPermissions)
        menu.addItem(permissionItem)

        menu.addItem(.separator())

        let updateItem = NSMenuItem(
            title: L10n.menuCheckForUpdates,
            action: #selector(checkForUpdates),
            keyEquivalent: ""
        )
        updateItem.target = self
        menu.addItem(updateItem)

        let aboutItem = NSMenuItem(
            title: L10n.menuAbout,
            action: #selector(showAbout),
            keyEquivalent: ""
        )
        aboutItem.target = self
        menu.addItem(aboutItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: L10n.menuQuit,
            action: #selector(quit),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        refreshAppearance()
    }

    private func refreshAppearance() {
        enabledItem.state = enabled ? .on : .off
        loginItem.state = launchAtLogin ? .on : .off
        permissionItem.state = hasPermission ? .on : .off
        refreshStatusImage()
    }

    private func refreshStatusImage() {
        let symbolName = hasPermission ? "rectangle.split.2x1" : "exclamationmark.triangle.fill"
        let fallbackName = hasPermission ? "rectangle" : "exclamationmark.triangle"
        let image =
            NSImage(systemSymbolName: symbolName, accessibilityDescription: "Swindoo")
            ?? NSImage(systemSymbolName: fallbackName, accessibilityDescription: "Swindoo")
        image?.isTemplate = true
        statusItem.button?.image = image
        statusItem.button?.appearsDisabled = !enabled
    }

    @objc private func toggleEnabled() {
        onEnabledChanged?(!enabled)
    }

    @objc private func toggleLaunchAtLogin() {
        onLaunchAtLoginChanged?(!launchAtLogin)
    }

    @objc private func showGuide() {
        onShowGuide?()
    }

    @objc private func showPermissions() {
        onShowPermissions?()
    }

    @objc private func checkForUpdates() {
        onCheckForUpdates?()
    }

    @objc private func showAbout() {
        NSApp.orderFrontStandardAboutPanel(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
