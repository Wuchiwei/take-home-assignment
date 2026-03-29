#if DEBUG
import Foundation

enum MockConstants: Sendable {
    static let matchCount = Int.random(in: 80...120)
    static let matchIDStart = 1001
    static let matchIDRange: ClosedRange<Int> = matchIDStart...(matchIDStart + matchCount - 1)
}
#endif
