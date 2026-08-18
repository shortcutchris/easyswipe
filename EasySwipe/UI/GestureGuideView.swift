import SwiftUI

struct GestureGuideView: View {
    let close: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(L10n.guideTitle)
                .font(.title.bold())

            VStack(alignment: .leading, spacing: 12) {
                GuideRow(symbol: "arrow.left", title: L10n.gestureLeft)
                GuideRow(symbol: "arrow.right", title: L10n.gestureRight)
                GuideRow(symbol: "arrow.down", title: L10n.gestureDown)
            }

            Text(L10n.guideFooter)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Text(L10n.deviceHint)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Spacer()
                Button(L10n.close) { close() }
                    .keyboardShortcut(.cancelAction)
            }
        }
        .padding(24)
        .frame(width: 480)
    }
}

private struct GuideRow: View {
    let symbol: String
    let title: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.title3)
                .frame(width: 28)
                .foregroundStyle(.tint)
            Text(title)
                .font(.body)
        }
    }
}
