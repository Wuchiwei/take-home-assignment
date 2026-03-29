import Foundation

// NOTE: Scalability concern — as the app grows, this class accumulates a factory
// method per feature (makeMatchListViewModel, makeSettingsViewModel, …).
// Splitting into extensions per feature file is cosmetic: the underlying coupling
// remains because AppContainer still imports and knows about every feature.
//
// The real solution for large apps is SPM feature modularization: each feature
// module owns its own mini-container and exposes only an entry-point View (or
// ViewModel). AppContainer then wires feature modules together, not individual
// ViewModels, keeping the composition root thin regardless of how many features exist.
final class AppContainer {
    let dataService: any DataServiceProtocol
    let oddsStreamService: any OddsStreamServiceProtocol
    let theme: AppTheme
    let matchRepository: any MatchRepositoryProtocol

    init(
        dataService: any DataServiceProtocol,
        oddsStreamService: any OddsStreamServiceProtocol,
        theme: AppTheme = AppTheme()
    ) {
        self.dataService = dataService
        self.oddsStreamService = oddsStreamService
        self.theme = theme
        self.matchRepository = MatchRepository(dataService: dataService)
    }
}

// MARK: - MatchListDependencies
extension AppContainer: MatchListDependencies {
    @MainActor
    func makeMatchListViewModel(router: AppRouter) -> MatchListViewModel {
        MatchListViewModel(
            reducer: MatchListReducer(colorScheme: theme.oddsColorScheme),
            router: router,
            repository: matchRepository,
            oddsStreamService: oddsStreamService
        )
    }
}

// MARK: - MatchDetailDependencies
extension AppContainer: MatchDetailDependencies {
    @MainActor
    func makeMatchDetailViewModel(match: Match, odds: MatchOdds) -> MatchDetailViewModel {
        MatchDetailViewModel(match: match, odds: odds)
    }
}
