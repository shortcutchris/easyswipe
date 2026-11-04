import AppKit
import Combine
import Foundation
import Sparkle

struct UpdateConfiguration: Equatable, Sendable {
    let feedURL: URL?
    let publicKey: String?

    var isConfigured: Bool {
        guard let feedURL,
            feedURL.scheme?.lowercased() == "https",
            feedURL.host != nil, feedURL.user == nil, feedURL.password == nil,
            let publicKey,
            Data(base64Encoded: publicKey)?.count == 32
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
final class UpdateController: NSObject, ObservableObject, SPUUpdaterDelegate {
    let configuration: UpdateConfiguration
    private var updaterController: SPUStandardUpdaterController?
    @Published private(set) var state: UpdateStatus = .unChecked
    @Published private(set) var availableVersion: String?
    @Published private(set) var lastSuccessfulCheck: Date?
    @Published private(set) var failureMessageKey: String?
    var isBusy: () -> Bool = { false }
    private var deferredInstallation: (() -> Void)?
    private var retryTask: Task<Void, Never>?
    private let defaults: UserDefaults
    private var started = false
    private var canCheckObservation: NSKeyValueObservation?

    init(bundle: Bundle = .main, defaults: UserDefaults = .standard) {
        configuration = .from(bundle: bundle)
        self.defaults = defaults
        lastSuccessfulCheck = defaults.object(forKey: "updates.lastSuccessfulCheck") as? Date
        super.init()
        if configuration.isConfigured {
            updaterController = SPUStandardUpdaterController(
                startingUpdater: false,
                updaterDelegate: self,
                userDriverDelegate: nil
            )
            canCheckObservation = updaterController?.updater.observe(\.canCheckForUpdates, options: [.new]) { [weak self] _, _ in
                Task { @MainActor [weak self] in self?.objectWillChange.send() }
            }
        } else {
            state = .unconfigured
        }
    }

    func start() {
        guard !started, let updaterController else { return }
        started = true
        updaterController.startUpdater()
    }

    func stop() { retryTask?.cancel(); retryTask = nil; deferredInstallation = nil }

    var automaticallyChecks: Bool {
        get { updaterController?.updater.automaticallyChecksForUpdates ?? false }
        set { objectWillChange.send(); updaterController?.updater.automaticallyChecksForUpdates = newValue }
    }

    var automaticallyDownloads: Bool {
        get { updaterController?.updater.automaticallyDownloadsUpdates ?? false }
        set { objectWillChange.send(); updaterController?.updater.automaticallyDownloadsUpdates = newValue }
    }

    var allowsAutomaticDownloads: Bool { updaterController?.updater.allowsAutomaticUpdates ?? false }

    var canCheckForUpdates: Bool {
        updaterController?.updater.canCheckForUpdates ?? false
    }

    func checkForUpdates() {
        guard let updaterController else {
            state = .unconfigured
            return
        }
        guard canCheckForUpdates else { return }
        state = .checking
        updaterController.checkForUpdates(nil)
    }

    func updater(_ updater: SPUUpdater, mayPerform updateCheck: SPUUpdateCheck) throws {
        failureMessageKey = nil
        state = .checking
    }

    func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
        availableVersion = item.displayVersionString
        markSuccessfulCheck()
        state = .available
    }

    func updaterDidNotFindUpdate(_ updater: SPUUpdater, error: Error) {
        markSuccessfulCheck()
        availableVersion = nil
        let reason = (error as NSError).userInfo[SPUNoUpdateFoundReasonKey] as? NSNumber
        let isCurrent = reason.map {
            [SPUNoUpdateFoundReason.onLatestVersion.rawValue, SPUNoUpdateFoundReason.onNewerThanLatestVersion.rawValue].contains(OSStatus($0.intValue))
        } ?? false
        state = isCurrent ? .current : .noCompatibleUpdate
    }

    private func markSuccessfulCheck() {
        lastSuccessfulCheck = Date()
        defaults.set(lastSuccessfulCheck, forKey: "updates.lastSuccessfulCheck")
    }

    func updater(_ updater: SPUUpdater, willDownloadUpdate item: SUAppcastItem, with request: NSMutableURLRequest) { state = .downloading }
    func updater(_ updater: SPUUpdater, didDownloadUpdate item: SUAppcastItem) { state = .verifying }
    func updater(_ updater: SPUUpdater, willExtractUpdate item: SUAppcastItem) { state = .verifying }
    func updater(_ updater: SPUUpdater, didExtractUpdate item: SUAppcastItem) { state = .ready }
    func updater(_ updater: SPUUpdater, willInstallUpdate item: SUAppcastItem) { state = .installing }
    func userDidCancelDownload(_ updater: SPUUpdater) { state = .cancelled }
    func updater(_ updater: SPUUpdater, didAbortWithError error: Error) {
        receiveFailure(error)
    }

    func receiveFailure(_ error: Error) {
        let error = error as NSError
        if error.domain == SUSparkleErrorDomain && error.code == SUError.noUpdateError.rawValue { return }
        let underlying = error.userInfo[NSUnderlyingErrorKey] as? NSError ?? error
        if (underlying.domain == NSURLErrorDomain && underlying.code == NSURLErrorCancelled)
            || (error.domain == SUSparkleErrorDomain && error.code == SUError.installationCanceledError.rawValue) {
            state = .cancelled
            failureMessageKey = nil
            return
        }
        failureMessageKey = underlying.domain == NSURLErrorDomain ? "updates.failure.network" : "updates.failure.general"
        state = .failed
    }
    func updater(_ updater: SPUUpdater, didFinishUpdateCycleFor updateCheck: SPUUpdateCheck, error: Error?) { objectWillChange.send() }

    func postponeInstallation(_ install: @escaping () -> Void) -> Bool {
        guard isBusy() else { return false }
        deferredInstallation = install
        state = .waiting
        retryTask?.cancel()
        retryTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(150))
                guard !Task.isCancelled, let self else { return }
                if resumeInstallationIfSafe() { return }
            }
        }
        return true
    }

    @discardableResult
    func resumeInstallationIfSafe() -> Bool {
        guard !isBusy(), let install = deferredInstallation else { return false }
        deferredInstallation = nil
        state = .installing
        install()
        return true
    }

    func updater(_ updater: SPUUpdater, shouldPostponeRelaunchForUpdate item: SUAppcastItem,
                 untilInvokingBlock installHandler: @escaping () -> Void) -> Bool { postponeInstallation(installHandler) }
    func updaterShouldRelaunchApplication(_ updater: SPUUpdater) -> Bool { !isBusy() }
}

enum UpdateStatus: String, CaseIterable {
    case unChecked, unconfigured, checking, current, noCompatibleUpdate, available
    case downloading, verifying, ready, waiting, installing, cancelled, failed
    var localizationKey: String { "updates.status.\(rawValue)" }
    var isProgressing: Bool { [.checking, .downloading, .verifying, .installing].contains(self) }
}
