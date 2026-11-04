import Combine
import Foundation
import ServiceManagement

@MainActor
final class LoginItemController: ObservableObject {
    @Published private(set) var isEnabled = false
    private enum Failure { case requiresApproval, registration }
    @Published private var failure: Failure?
    var lastError: String? {
        switch failure {
        case .requiresApproval: L10n.loginItemRequiresApproval
        case .registration: L10n.text("login.error.message")
        case nil: nil
        }
    }

    init() {
        refresh()
    }

    func refresh() {
        let status = SMAppService.mainApp.status
        isEnabled = status == .enabled
        if status == .requiresApproval {
            failure = .requiresApproval
        } else if status == .enabled {
            failure = nil
        } else if failure == .requiresApproval {
            failure = nil
        }
    }

    func setEnabled(_ enabled: Bool) {
        failure = nil

        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            failure = .registration
        }

        refresh()
    }
}
