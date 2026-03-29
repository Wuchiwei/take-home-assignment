import Foundation
import Observation

enum MatchListViewState: Equatable {
    case loading
    case loaded([MatchRowViewModel])
    case error(String)

    static func == (lhs: MatchListViewState, rhs: MatchListViewState) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading): return true
        case (.error(let a), .error(let b)): return a == b
        case (.loaded(let a), .loaded(let b)): return a == b
        default: return false
        }
    }
}

@Observable
@MainActor
final class MatchListViewModel {
    let title = String(localized: "Live Odds")
    let loadingText = String(localized: "Loading...")
    let retryText = String(localized: "Retry")
    private(set) var state = MatchListState()

    private let reducer: MatchListReducer
    private let repository: any MatchRepositoryProtocol
    private let oddsStreamService: any OddsStreamServiceProtocol
    private let router: AppRouter

    init(
        reducer: MatchListReducer,
        router: AppRouter,
        repository: any MatchRepositoryProtocol,
        oddsStreamService: any OddsStreamServiceProtocol
    ) {
        self.reducer = reducer
        self.router = router
        self.repository = repository
        self.oddsStreamService = oddsStreamService
    }

    func start() async {
        await dispatch(.startLoading)
    }

    func didTapMatch(id: Int) {
        Task { await dispatch(.matchTapped(id)) }
    }

    func retry() async {
        await dispatch(.startLoading)
    }

    func refresh() async {
        await dispatch(.startRefresh)
    }

    func didEnterBackground() {
        Task { await dispatch(.enterBackground) }
    }

    func didBecomeActive() {
        Task { await dispatch(.becomeActive) }
    }
}

// MARK: - Dispatch

private extension MatchListViewModel {
    func dispatch(_ action: MatchListAction) async {
        let (newState, effect) = reducer.reduce(state: state, action: action)
        if state != newState {
            state = newState
        }
        await handleEffect(effect)
    }

    func handleEffect(_ effect: MatchListEffect) async {
        switch effect {
        case .none:
            return
        case .navigate(let match, let odds):
            router.push(.matchDetail(match: match, odds: odds))
        case .disconnectWebSocket:
            oddsStreamService.disconnect()
        case .applyOddsUpdate(let update):
            if let viewModel = state.oddsIndex[update.matchID] {
                viewModel.applyUpdate(update)
            }
            await repository.applyUpdate(update)
        case .loadAndConnect:
            await loadAndConnect()
        case .loadData(let force):
            await loadData(force: force)
        }
    }
}

// MARK: - Side Effects

private extension MatchListViewModel {
    func loadAndConnect() async {
        guard await loadData(force: false) else { return }
        await listenToWebSocket()
    }

    @discardableResult
    func loadData(force: Bool) async -> Bool {
        do {
            let (matches, oddsMap) = force
                ? try await repository.forceLoad()
                : try await repository.load()
            await dispatch(.dataLoaded(matches, oddsMap))
            return true
        } catch {
            await dispatch(.dataFailed(error.localizedDescription))
            return false
        }
    }

    func listenToWebSocket() async {
        for await event in oddsStreamService.connect() {
            await dispatch(.webSocketEvent(event))
        }
        await dispatch(.webSocketEvent(.disconnected(reason: .manual)))
    }
}
