import Foundation
import Observation

@Observable
@MainActor
final class MatchDetailViewModel {
    let title = String(localized: "Match Detail")
    let match: Match
    let odds: MatchOdds

    init(match: Match, odds: MatchOdds) {
        self.match = match
        self.odds = odds
    }
}
