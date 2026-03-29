import Foundation

// Single home for all user-facing strings that aren't passed directly to SwiftUI Text views.
// SwiftUI Text("literal") and .navigationTitle("literal") already use LocalizedStringKey
// automatically — only non-View strings need to go through String(localized:) here.
//
// To add a new language:
//   1. In Xcode, select the project → Info → Localizations → (+)
//   2. Xcode generates a new Localizable.strings (or .xcstrings) for that language
//   3. Translate the keys in Resources/en.lproj/Localizable.strings
enum Strings {
    enum Connection {
        static let idle      = String(localized: "Idle")
        static let connected = String(localized: "Connected")
        static func reconnecting(attempt: Int) -> String {
            // Key in Localizable.strings: "Reconnecting... (%lld)"
            String(localized: "Reconnecting... (\(attempt))")
        }
    }
}
