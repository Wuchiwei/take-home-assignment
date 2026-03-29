import SwiftUI

struct OddsFlashColorScheme {
    let riseColor: Color
    let fallColor: Color

    /// Green = rise, Red = fall (Western convention)
    static let western = OddsFlashColorScheme(riseColor: .green, fallColor: .red)

    /// Red = rise, Green = fall (Asian convention)
    static let asian   = OddsFlashColorScheme(riseColor: .red,   fallColor: .green)
}

