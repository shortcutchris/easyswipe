import AppKit
import Foundation
import OSLog
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
final class UpdateController: NSObject, SPUUpdaterDelegate {
    let configuration: UpdateConfiguration
    private var updaterController: SPUStandardUpdaterController?
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.shortcutchris.EasySwipe",
        category: "updates"
    )

    init(bundle: Bundle = .main) {
        configuration = .from(bundle: bundle)
        super.init()

        if configuration.isConfigured {
            updaterController = SPUStandardUpdaterController(
                startingUpdater: true,
                updaterDelegate: self,
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

    func updater(_ updater: SPUUpdater, didAbortWithError error: any Error) {
        let diagnostic = Self.diagnosticDescription(for: error)
        logger.error("Sparkle update aborted. \(diagnostic, privacy: .public)")

        guard let outputPath = ProcessInfo.processInfo.environment[
            "EASYSWIPE_UPDATE_DIAGNOSTICS_PATH"
        ], !outputPath.isEmpty else {
            return
        }

        do {
            try diagnostic.write(
                toFile: outputPath,
                atomically: true,
                encoding: .utf8
            )
        } catch {
            logger.error(
                "Could not write update diagnostics. \(error.localizedDescription, privacy: .public)"
            )
        }
    }

    nonisolated static func diagnosticDescription(for error: any Error) -> String {
        var entries: [String] = []
        var currentError: NSError? = error as NSError
        var visited: Set<ObjectIdentifier> = []

        while let errorToDescribe = currentError {
            let identifier = ObjectIdentifier(errorToDescribe)
            guard visited.insert(identifier).inserted else { break }

            var entry = "domain=\(errorToDescribe.domain) code=\(errorToDescribe.code)"
            if !errorToDescribe.localizedDescription.isEmpty {
                entry += " description=\(errorToDescribe.localizedDescription)"
            }
            if let failureReason = errorToDescribe.localizedFailureReason, !failureReason.isEmpty {
                entry += " failureReason=\(failureReason)"
            }
            if let recoverySuggestion = errorToDescribe.localizedRecoverySuggestion,
                !recoverySuggestion.isEmpty
            {
                entry += " recoverySuggestion=\(recoverySuggestion)"
            }
            entries.append(entry)

            currentError = errorToDescribe.userInfo[NSUnderlyingErrorKey] as? NSError
        }

        return entries.joined(separator: " | underlying: ")
    }
}
