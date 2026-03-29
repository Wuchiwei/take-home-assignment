import Foundation

// MARK: - State

struct MatchListState: Equatable {
    var viewState: MatchListViewState = .loading
    var connectionStatus: ConnectionStatus = .idle
    var oddsIndex: [Int: MatchRowViewModel] = [:]
    var reconnectAttempt = 0
    var hasEnteredBackground = false

    static func == (lhs: MatchListState, rhs: MatchListState) -> Bool {
        lhs.viewState == rhs.viewState
            && lhs.connectionStatus == rhs.connectionStatus
            && lhs.reconnectAttempt == rhs.reconnectAttempt
            && lhs.hasEnteredBackground == rhs.hasEnteredBackground
            && lhs.oddsIndex.keys == rhs.oddsIndex.keys
    }
}

// MARK: - Action

enum MatchListAction {
    case startLoading
    case startRefresh
    case enterBackground
    case becomeActive
    case dataLoaded([Match], [Int: MatchOdds])
    case dataFailed(String)
    case webSocketEvent(WebSocketEvent)
    case matchTapped(Int)
}

// MARK: - Effect

enum MatchListEffect: Equatable {
    case none
    case navigate(match: Match, odds: MatchOdds)
    case disconnectWebSocket
    case loadAndConnect
    case loadData(force: Bool)
    case applyOddsUpdate(OddsUpdate)
}

// MARK: - Reducer

struct MatchListReducer {
    let colorScheme: OddsFlashColorScheme

    func reduce(
        state: MatchListState,
        action: MatchListAction
    ) -> (MatchListState, MatchListEffect) {
        var state = state

        switch action {
        case .startLoading:
            switch state.viewState {
            case .loaded:
                break
            case .loading, .error:
                state.viewState = .loading
            }
            return (state, .loadAndConnect)

        case .startRefresh:
            return (state, .loadData(force: true))

        case .enterBackground:
            state.hasEnteredBackground = true
            return (state, .disconnectWebSocket)

        case .becomeActive:
            guard state.hasEnteredBackground else { return (state, .none) }
            state.hasEnteredBackground = false
            return (state, .loadAndConnect)

        case .dataLoaded(let matches, let oddsMap):
            let newState = applyMatchData(
                state: state,
                matches: matches,
                oddsMap: oddsMap
            )
            return (newState, .none)

        case .dataFailed(let message):
            switch state.viewState {
            case .loaded:
                // Already showing data — keep it visible, don't replace with error.
                // TODO: Show a non-blocking toast/banner so the user knows refresh failed.
                // Log to server/Firebase for monitoring.
                break
            case .loading, .error:
                state.viewState = .error(message)
            }
            return (state, .none)

        case .webSocketEvent(let event):
            return handleWebSocketEvent(state: state, event: event)

        case .matchTapped(let id):
            guard let viewModel = state.oddsIndex[id],
                  let odds = viewModel.currentOdds else {
                // This should never happen: the row exists in the list and odds should be loaded.
                // If it does, log to server/Firebase for investigation.
                return (state, .none)
            }
            return (state, .navigate(match: viewModel.match, odds: odds))
        }
    }
}

// MARK: - State Helpers

private extension MatchListReducer {
    func applyMatchData(
        state: MatchListState,
        matches: [Match],
        oddsMap: [Int: MatchOdds]
    ) -> MatchListState {
        var state = state
        let viewModels = matches
            .map { match in
                MatchRowViewModel(
                    match: match,
                    odds: oddsMap[match.matchID],
                    colorScheme: colorScheme
                )
            }
            .sorted { $0.startTime < $1.startTime }

        state.viewState = .loaded(viewModels)
        state.oddsIndex = Dictionary(
            viewModels.map { ($0.id, $0) },
            uniquingKeysWith: { _, latest in latest }
        )
        return state
    }

    func handleWebSocketEvent(
        state: MatchListState,
        event: WebSocketEvent
    ) -> (MatchListState, MatchListEffect) {
        var state = state

        switch event {
        case .connected:
            state.reconnectAttempt = 0
            state.connectionStatus = .connected

        case .oddsUpdate(let update):
            guard state.oddsIndex[update.matchID] != nil else { break }
            return (state, .applyOddsUpdate(update))

        case .disconnected(let reason):
            switch reason {
            case .invalidURL:
                // Configuration error — should not happen in production.
                // Log to server/Firebase for investigation.
                switch state.viewState {
                case .loaded:
                    break
                case .loading, .error:
                    state.viewState = .error("Invalid WebSocket URL")
                }
            case .manual:
                state.connectionStatus = .idle
            case .serverClosed, .networkError:
                state.reconnectAttempt += 1
                state.connectionStatus = .reconnecting(attempt: state.reconnectAttempt)
            }
        }
        return (state, .none)
    }
}
