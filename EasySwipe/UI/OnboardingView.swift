import SwiftUI

struct OnboardingView: View {
    @ObservedObject var permissions: AccessibilityPermissionController
    @ObservedObject var loginItem: LoginItemController
    let finish: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text(L10n.onboardingTitle)
                    .font(.largeTitle.bold())
                Text(L10n.onboardingSubtitle)
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 12) {
                GestureRow(symbol: "arrow.left", text: L10n.gestureLeft)
                GestureRow(symbol: "arrow.right", text: L10n.gestureRight)
                GestureRow(symbol: "arrow.down", text: L10n.gestureDown)
            }

            Text(L10n.deviceHint)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: permissions.isTrusted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(permissions.isTrusted ? Color.green : Color.orange)
                    Text(L10n.permissionTitle)
                        .font(.headline)
                    Spacer()
                    Text(permissions.isTrusted ? L10n.permissionGranted : L10n.permissionMissing)
                        .foregroundStyle(.secondary)
                }

                Text(L10n.permissionExplanation)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if !permissions.isTrusted {
                    HStack {
                        Button(L10n.permissionRequest) {
                            permissions.requestAccess()
                        }
                        Button(L10n.permissionOpenSettings) {
                            permissions.openSystemSettings()
                        }
                    }
                }
            }

            Toggle(
                L10n.menuLaunchAtLogin,
                isOn: Binding(
                    get: { loginItem.isEnabled },
                    set: { loginItem.setEnabled($0) }
                )
            )

            if let error = loginItem.lastError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            HStack {
                Spacer()
                Button(L10n.finishSetup) {
                    finish()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!permissions.isTrusted)
            }
        }
        .padding(28)
        .frame(width: 560)
    }
}

private struct GestureRow: View {
    let symbol: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .frame(width: 22)
                .foregroundStyle(.tint)
            Text(text)
        }
    }
}
