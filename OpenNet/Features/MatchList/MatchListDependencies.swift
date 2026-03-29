import Foundation

protocol MatchListDependencies {
    @MainActor func makeMatchListViewModel(router: AppRouter) -> MatchListViewModel
}
