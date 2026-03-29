import Foundation

protocol MatchDetailDependencies {
    @MainActor func makeMatchDetailViewModel(match: Match, odds: MatchOdds) -> MatchDetailViewModel
}
