import SwiftUI

// Extend this enum when entering a new market — no other file needs to change.
enum Market {
    case western
    case asian

    static func detect(locale: Locale = .current) -> Market {
        locale.region?.identifier == "TW" ? .asian : .western
    }

    var oddsColorScheme: OddsFlashColorScheme {
        switch self {
        case .western: return .western
        case .asian:   return .asian
        }
    }
}

// @Observable omitted intentionally: all properties are immutable.
// If runtime theme-switching is needed (e.g. user toggles market in Settings),
// convert properties to var and re-add @Observable.
final class AppTheme {
    let oddsColorScheme: OddsFlashColorScheme

    init(market: Market = .detect()) {
        oddsColorScheme = market.oddsColorScheme
    }
}
