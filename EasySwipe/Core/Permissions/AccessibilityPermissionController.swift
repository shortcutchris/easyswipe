import AppKit
import ApplicationServices
import Combine
import Foundation

@MainActor
final class AccessibilityPermissionController: ObservableObject {
    @Published private(set) var isTrusted: Bool

    var onTrustChanged: (@MainActor (Bool) -> Void)?

    private var pollingTimer: Timer?

    init() {
        isTrusted = AXIsProcessTrusted()
    }

    func refresh() {
        let currentValue = AXIsProcessTrusted()
        guard currentValue != isTrusted else { return }
        isTrusted = currentValue
        onTrustChanged?(currentValue)
    }

    func requestAccess() {
        // The exported C global is not concurrency-annotated in current SDKs.
        // Its documented dictionary key has a stable string representation.
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        startPolling()
    }

    func openSystemSettings() {
        guard
            let url = URL(
                string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
            )
        else { return }
        NSWorkspace.shared.open(url)
        startPolling()
    }

    func startPolling() {
        guard pollingTimer == nil else { return }
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.refresh()
            }
        }
    }

    func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
    }
}
