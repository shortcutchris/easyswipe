import SwiftUI

@MainActor
final class SettingsNavigation: ObservableObject {
    enum Page { case general, updates }
    @Published var page: Page = .general
}

struct AppSettingsView: View {
    @ObservedObject var navigation: SettingsNavigation
    @ObservedObject var preferences: AppPreferences
    @ObservedObject var updates: UpdateController
    @ObservedObject var loginItem: LoginItemController
    let onBehaviorChanged: () -> Void
    let showGuide: () -> Void

    var body: some View {
        TabView(selection: $navigation.page) {
            general.tabItem { Label(L10n.text("settings.general"), systemImage: "gearshape") }.tag(SettingsNavigation.Page.general)
            updatePage.tabItem { Label(L10n.text("settings.updates"), systemImage: "arrow.triangle.2.circlepath") }.tag(SettingsNavigation.Page.updates)
        }
        .padding(20)
        .frame(width: 560, height: 480)
    }

    private var general: some View {
        Form {
            Section(L10n.text("settings.interface")) {
                Picker(L10n.text("settings.language"), selection: $preferences.language) {
                    Text(L10n.text("settings.system")).tag(InterfaceLanguage.system)
                    Text("Deutsch").tag(InterfaceLanguage.de)
                    Text("English").tag(InterfaceLanguage.en)
                }.accessibilityIdentifier("settings.language")
                Picker(L10n.text("settings.appearance"), selection: $preferences.appearance) {
                    Text(L10n.text("settings.system")).tag(InterfaceAppearance.system)
                    Text(L10n.text("settings.light")).tag(InterfaceAppearance.light)
                    Text(L10n.text("settings.dark")).tag(InterfaceAppearance.dark)
                }.accessibilityIdentifier("settings.appearance")
                Text(L10n.text("settings.interface.hint")).font(.caption).foregroundStyle(.secondary)
            }
            Section(L10n.text("settings.behavior")) {
                Toggle(L10n.menuEnabled, isOn: $preferences.isEnabled)
                    .onChange(of: preferences.isEnabled) { onBehaviorChanged() }
                Toggle(L10n.menuAnimations, isOn: $preferences.areHUDAnimationsEnabled)
                    .onChange(of: preferences.areHUDAnimationsEnabled) { onBehaviorChanged() }
                Toggle(L10n.menuLaunchAtLogin, isOn: Binding(get: { loginItem.isEnabled }, set: {
                    loginItem.setEnabled($0); onBehaviorChanged()
                })).disabled(ProcessInfo.processInfo.environment["SWINDOO_QA_SUITE"]?.hasPrefix("Swindoo.QA.") == true)
                if let error = loginItem.lastError { Text(error).foregroundStyle(.red).font(.caption) }
            }
            Section {
                Button(L10n.menuGestureGuide, action: showGuide)
                Text(L10n.text("settings.help")).font(.caption).foregroundStyle(.secondary)
            }
        }.formStyle(.grouped).toggleStyle(.checkbox).controlSize(.small)
    }

    private var updatePage: some View {
        Form {
            Section(L10n.text("updates.version")) {
                LabeledContent("Swindoo", value: versionLabel)
                HStack(spacing: 8) {
                    if updates.state.isProgressing { ProgressView().controlSize(.small) }
                    else { Image(systemName: updates.state == .failed || updates.state == .unconfigured ? "exclamationmark.triangle" : "arrow.triangle.2.circlepath") }
                    Text(L10n.text(updates.state.localizationKey)).accessibilityIdentifier("updates.status")
                }
                if let key = updates.failureMessageKey {
                    Text(L10n.text(key)).font(.caption).foregroundStyle(.secondary)
                }
                if let version = updates.availableVersion { LabeledContent(L10n.text("updates.availableVersion"), value: version) }
                if let date = updates.lastSuccessfulCheck {
                    LabeledContent(L10n.text("updates.lastCheck"), value: date.formatted(date: .abbreviated, time: .shortened))
                }
                Button(L10n.menuCheckForUpdates) { updates.checkForUpdates() }
                    .disabled(!updates.canCheckForUpdates).accessibilityIdentifier("updates.check")
            }
            Section(L10n.text("updates.automatic")) {
                Toggle(L10n.text("updates.autoCheck"), isOn: Binding(get: { updates.automaticallyChecks }, set: { updates.automaticallyChecks = $0 }))
                if updates.allowsAutomaticDownloads {
                    Toggle(L10n.text("updates.autoDownload"), isOn: Binding(get: { updates.automaticallyDownloads }, set: { updates.automaticallyDownloads = $0 }))
                }
            }.disabled(!updates.configuration.isConfigured || ProcessInfo.processInfo.environment["SWINDOO_QA_SUITE"]?.hasPrefix("Swindoo.QA.") == true)
            Section {
                Text(L10n.text("updates.safety")).font(.caption).foregroundStyle(.secondary)
                Text(L10n.text("updates.languageHint")).font(.caption).foregroundStyle(.secondary)
            }
        }.formStyle(.grouped).toggleStyle(.checkbox).controlSize(.small)
    }

    private var versionLabel: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "–"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "–"
        return "\(version) (\(build))"
    }
}
