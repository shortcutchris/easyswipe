import AppKit
import Foundation
import Sparkle

struct UpdateConfiguration: Equatable, Sendable {
    let feedURL: URL?
    let publicKey: String?

    var isConfigured: Bool {
        guard let feedURL,
            feedURL.scheme?.lowercased() == "https",
            let publicKey,
            !publicKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            return false
        }
        return true
    }

    static func from(bundle: Bundle) -> UpdateConfiguration {
        let rawURL = bundle.object(forInfoDictionaryKey: "SUFeedURL") as? String
        let rawKey = bundle.object(forInfoDictionaryKey: "SUPublicEDKey") as? String

        let cleanURL = rawURL?.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanKey = rawKey?.trimmingCharacters(in: .whitespacesAndNewlines)

        return UpdateConfiguration(
            feedURL: cleanURL.flatMap { value in
                guard !value.isEmpty, !value.contains("$(") else { return nil }
                return URL(string: value)
            },
            publicKey: cleanKey.flatMap { value in
                guard !value.isEmpty, !value.contains("$(") else { return nil }
                return value
            }
        )
    }
}

@MainActor
final class UpdateController {
    let configuration: UpdateConfiguration
    private let updaterController: SPUStandardUpdaterController?

    init(bundle: Bundle = .main) {
        configuration = .from(bundle: bundle)
        if configuration.isConfigured {
            updaterController = SPUStandardUpdaterController(
                startingUpdater: true,
                updaterDelegate: nil,
                userDriverDelegate: nil
            )
        } else {
            updaterController = nil
        }
    }

    var canCheckForUpdates: Bool {
        updaterController?.updater.canCheckForUpdates ?? false
    }

    func checkForUpdates() {
        guard let updaterController else {
            let alert = NSAlert()
            alert.alertStyle = .informational
            alert.messageText = L10n.updateUnavailableTitle
            alert.informativeText = L10n.updateUnavailableMessage
            alert.addButton(withTitle: L10n.ok)
            alert.runModal()
            return
        }

        updaterController.checkForUpdates(nil)
    }
}
