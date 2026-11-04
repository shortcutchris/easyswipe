import AppKit
import SwiftUI

enum InterfaceLanguage: String, CaseIterable, Sendable {
    case system, de, en

    func resolved(preferredLanguages: [String] = Locale.preferredLanguages) -> String {
        guard self == .system else { return rawValue }
        for identifier in preferredLanguages {
            if let code = Locale(identifier: identifier).language.languageCode?.identifier,
               code == "de" || code == "en" { return code }
        }
        return "en"
    }
}

enum InterfaceAppearance: String, CaseIterable, Sendable {
    case system, light, dark

    var nsAppearance: NSAppearance? {
        switch self {
        case .system: nil
        case .light: NSAppearance(named: .aqua)
        case .dark: NSAppearance(named: .darkAqua)
        }
    }
}

/// Re-evaluate localized children without replacing their identity or losing view state.
struct LocalizedRoot<Content: View>: View {
    @ObservedObject var preferences: AppPreferences
    @ViewBuilder let content: () -> Content

    var body: some View {
        let _ = preferences.language
        let _ = preferences.systemRevision
        content().environment(\.locale, .autoupdatingCurrent)
    }
}
