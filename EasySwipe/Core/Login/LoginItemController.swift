import Combine
import Foundation
import ServiceManagement

@MainActor
final class LoginItemController: ObservableObject {
    @Published private(set) var isEnabled = false
    @Published private(set) var lastError: String?

    init() {
        refresh()
    }

    func refresh() {
        let status = SMAppService.mainApp.status
        isEnabled = status == .enabled
        if status == .requiresApproval {
            lastError = L10n.loginItemRequiresApproval
        } else if status == .enabled {
            lastError = nil
        }
    }

    func setEnabled(_ enabled: Bool) {
        lastError = nil

        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            lastError = error.localizedDescription
        }

        refresh()
    }
}
