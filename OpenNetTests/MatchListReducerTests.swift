import Foundation
import Testing
@testable import OpenNet

@MainActor
struct MatchListReducerTests {
    private let reducer = MatchListReducer(colorScheme: .western)

    // MARK: - Helpers

    private func makeState(
        viewState: MatchListViewState = .loading,
        connectionStatus: ConnectionStatus = .idle,
        reconnectAttempt: Int = 0,
        hasEnteredBackground: Bool = false
    ) -> MatchListState {
        var state = MatchListState()
        state.viewState = viewState
        state.connectionStatus = connectionStatus
        state.reconnectAttempt = reconnectAttempt
        state.hasEnteredBackground = hasEnteredBackground
        return state
    }

    private func makeSampleData() -> ([Match], [Int: MatchOdds]) {
        let matches = [
            Match(matchID: 1, teamA: "Eagles", teamB: "Tigers", startTime: Date()),
            Match(matchID: 2, teamA: "Lions", teamB: "Bears", startTime: Date().addingTimeInterval(60)),
        ]
        let oddsMap: [Int: MatchOdds] = [
            1: MatchOdds(matchID: 1, teamAOdds: 1.5, teamBOdds: 2.3),
            2: MatchOdds(matchID: 2, teamAOdds: 1.8, teamBOdds: 1.9),
        ]
        return (matches, oddsMap)
    }

    // MARK: - startLoading

    @Test func startLoading_fromLoading_setsLoadingAndReturnsLoadAndConnect() {
        // Given
        let state = makeState(viewState: .loading)

        // When
        let (newState, effect) = reducer.reduce(state: state, action: .startLoading)

        // Then
        #expect(newState.viewState == .loading)
        #expect(effect == .loadAndConnect)
    }

    @Test func startLoading_fromError_setsLoadingAndReturnsLoadAndConnect() {
        // Given
        let state = makeState(viewState: .error("Something failed"))

        // When
        let (newState, effect) = reducer.reduce(state: state, action: .startLoading)

        // Then
        #expect(newState.viewState == .loading)
        #expect(effect == .loadAndConnect)
    }

    @Test func startLoading_fromLoaded_preservesDataAndStillConnects() {
        // Given
        let (matches, oddsMap) = makeSampleData()
        var state = makeState()
        (state, _) = reducer.reduce(state: state, action: .dataLoaded(matches, oddsMap))

        // When
        let (newState, effect) = reducer.reduce(state: state, action: .startLoading)

        // Then
        if case .loaded = newState.viewState {
            // Data preserved
        } else {
            Issue.record("Expected .loaded but got \(newState.viewState)")
        }
        #expect(effect == .loadAndConnect)
    }

    // MARK: - startRefresh

    @Test func startRefresh_returnsForceLoadEffect() {
        // Given
        let state = makeState()

        // When
        let (newState, effect) = reducer.reduce(state: state, action: .startRefresh)

        // Then
        #expect(newState.viewState == state.viewState)
        #expect(effect == .loadData(force: true))
    }

    // MARK: - dataLoaded

    @Test func dataLoaded_setsLoadedStateWithSortedMatches() {
        // Given
        let laterMatch = Match(matchID: 1, teamA: "A", teamB: "B", startTime: Date().addingTimeInterval(120))
        let earlierMatch = Match(matchID: 2, teamA: "C", teamB: "D", startTime: Date().addingTimeInterval(60))
        let oddsMap: [Int: MatchOdds] = [
            1: MatchOdds(matchID: 1, teamAOdds: 1.5, teamBOdds: 2.0),
            2: MatchOdds(matchID: 2, teamAOdds: 1.8, teamBOdds: 1.9),
        ]
        let state = makeState()

        // When
        let (newState, effect) = reducer.reduce(
            state: state,
            action: .dataLoaded([laterMatch, earlierMatch], oddsMap)
        )

        // Then
        if case .loaded(let viewModels) = newState.viewState {
            #expect(viewModels.count == 2)
            #expect(viewModels[0].id == 2) // earlier match first
            #expect(viewModels[1].id == 1)
        } else {
            Issue.record("Expected .loaded state")
        }
        #expect(effect == .none)
    }

    @Test func dataLoaded_buildsOddsIndex() {
        // Given
        let (matches, oddsMap) = makeSampleData()
        let state = makeState()

        // When
        let (newState, _) = reducer.reduce(state: state, action: .dataLoaded(matches, oddsMap))

        // Then
        #expect(newState.oddsIndex.count == 2)
        #expect(newState.oddsIndex[1] != nil)
        #expect(newState.oddsIndex[2] != nil)
    }

    // MARK: - dataFailed

    @Test func dataFailed_fromLoading_setsErrorState() {
        // Given
        let state = makeState(viewState: .loading)

        // When
        let (newState, effect) = reducer.reduce(state: state, action: .dataFailed("Network error"))

        // Then
        #expect(newState.viewState == .error("Network error"))
        #expect(effect == .none)
    }

    @Test func dataFailed_fromLoaded_preservesExistingData() {
        // Given
        let (matches, oddsMap) = makeSampleData()
        var state = makeState()
        (state, _) = reducer.reduce(state: state, action: .dataLoaded(matches, oddsMap))

        // When
        let (newState, effect) = reducer.reduce(state: state, action: .dataFailed("Network error"))

        // Then
        if case .loaded = newState.viewState {
            // Data preserved — good
        } else {
            Issue.record("Expected .loaded to be preserved, got \(newState.viewState)")
        }
        #expect(effect == .none)
    }

    @Test func dataFailed_fromError_replacesErrorMessage() {
        // Given
        let state = makeState(viewState: .error("Old error"))

        // When
        let (newState, effect) = reducer.reduce(state: state, action: .dataFailed("New error"))

        // Then
        #expect(newState.viewState == .error("New error"))
        #expect(effect == .none)
    }

    // MARK: - enterBackground / becomeActive

    @Test func enterBackground_disconnectsWebSocket() {
        // Given
        let state = makeState(connectionStatus: .connected)

        // When
        let (newState, effect) = reducer.reduce(state: state, action: .enterBackground)

        // Then
        #expect(newState.hasEnteredBackground == true)
        #expect(effect == .disconnectWebSocket)
    }

    @Test func becomeActive_afterBackground_reconnects() {
        // Given
        let state = makeState(hasEnteredBackground: true)

        // When
        let (newState, effect) = reducer.reduce(state: state, action: .becomeActive)

        // Then
        #expect(newState.hasEnteredBackground == false)
        #expect(effect == .loadAndConnect)
    }

    @Test func becomeActive_withoutBackground_doesNothing() {
        // Given
        let state = makeState(hasEnteredBackground: false)

        // When
        let (newState, effect) = reducer.reduce(state: state, action: .becomeActive)

        // Then
        #expect(newState.hasEnteredBackground == false)
        #expect(effect == .none)
    }

    // MARK: - WebSocket Events

    @Test func webSocketConnected_resetsReconnectAttemptAndSetsConnected() {
        // Given
        let state = makeState(connectionStatus: .reconnecting(attempt: 3), reconnectAttempt: 3)

        // When
        let (newState, effect) = reducer.reduce(state: state, action: .webSocketEvent(.connected))

        // Then
        #expect(newState.connectionStatus == .connected)
        #expect(newState.reconnectAttempt == 0)
        #expect(effect == .none)
    }

    @Test func webSocketOddsUpdate_returnsApplyEffect_whenMatchExists() {
        // Given
        let (matches, oddsMap) = makeSampleData()
        var state = makeState()
        (state, _) = reducer.reduce(state: state, action: .dataLoaded(matches, oddsMap))
        let update = OddsUpdate(matchID: 1, teamAOdds: 1.6, teamBOdds: 2.1)

        // When
        let (_, effect) = reducer.reduce(state: state, action: .webSocketEvent(.oddsUpdate(update)))

        // Then
        #expect(effect == .applyOddsUpdate(update))
    }

    @Test func webSocketOddsUpdate_ignored_whenMatchNotFound() {
        // Given
        let (matches, oddsMap) = makeSampleData()
        var state = makeState()
        (state, _) = reducer.reduce(state: state, action: .dataLoaded(matches, oddsMap))
        let update = OddsUpdate(matchID: 999, teamAOdds: 1.0, teamBOdds: 1.0)

        // When
        let (_, effect) = reducer.reduce(state: state, action: .webSocketEvent(.oddsUpdate(update)))

        // Then
        #expect(effect == .none)
    }

    @Test func webSocketDisconnected_serverClosed_incrementsReconnectAttempt() {
        // Given
        let state = makeState(connectionStatus: .connected, reconnectAttempt: 0)

        // When
        let (newState, effect) = reducer.reduce(
            state: state,
            action: .webSocketEvent(.disconnected(reason: .serverClosed))
        )

        // Then
        #expect(newState.reconnectAttempt == 1)
        #expect(newState.connectionStatus == .reconnecting(attempt: 1))
        #expect(effect == .none)
    }

    @Test func webSocketDisconnected_networkError_incrementsReconnectAttempt() {
        // Given
        let state = makeState(connectionStatus: .connected, reconnectAttempt: 0)

        // When
        let (newState, effect) = reducer.reduce(
            state: state,
            action: .webSocketEvent(.disconnected(reason: .networkError("timeout")))
        )

        // Then
        #expect(newState.reconnectAttempt == 1)
        #expect(newState.connectionStatus == .reconnecting(attempt: 1))
        #expect(effect == .none)
    }

    @Test func webSocketDisconnected_consecutiveDisconnects_incrementsReconnectAttempt() {
        // Given
        var state = makeState(connectionStatus: .connected, reconnectAttempt: 0)

        // When — first disconnect
        (state, _) = reducer.reduce(
            state: state,
            action: .webSocketEvent(.disconnected(reason: .serverClosed))
        )

        // Then
        #expect(state.reconnectAttempt == 1)
        #expect(state.connectionStatus == .reconnecting(attempt: 1))

        // When — second disconnect
        (state, _) = reducer.reduce(
            state: state,
            action: .webSocketEvent(.disconnected(reason: .serverClosed))
        )

        // Then
        #expect(state.reconnectAttempt == 2)
        #expect(state.connectionStatus == .reconnecting(attempt: 2))
    }

    @Test func webSocketDisconnected_manual_setsIdle() {
        // Given
        let state = makeState(connectionStatus: .connected)

        // When
        let (newState, _) = reducer.reduce(
            state: state,
            action: .webSocketEvent(.disconnected(reason: .manual))
        )

        // Then
        #expect(newState.connectionStatus == .idle)
    }

    @Test func webSocketDisconnected_invalidURL_setsError_whenNotLoaded() {
        // Given
        let state = makeState(viewState: .loading)

        // When
        let (newState, _) = reducer.reduce(
            state: state,
            action: .webSocketEvent(.disconnected(reason: .invalidURL))
        )

        // Then
        #expect(newState.viewState == .error("Invalid WebSocket URL"))
    }

    @Test func webSocketDisconnected_invalidURL_preservesData_whenLoaded() {
        // Given
        let (matches, oddsMap) = makeSampleData()
        var state = makeState()
        (state, _) = reducer.reduce(state: state, action: .dataLoaded(matches, oddsMap))

        // When
        let (newState, _) = reducer.reduce(
            state: state,
            action: .webSocketEvent(.disconnected(reason: .invalidURL))
        )

        // Then
        if case .loaded = newState.viewState {
            // preserved
        } else {
            Issue.record("Expected loaded state to be preserved")
        }
    }

    // MARK: - matchTapped

    @Test func matchTapped_returnsNavigateEffect_whenOddsExist() {
        // Given
        let match = Match(matchID: 1, teamA: "Eagles", teamB: "Tigers", startTime: Date())
        let odds = MatchOdds(matchID: 1, teamAOdds: 1.5, teamBOdds: 2.3)
        var state = makeState()
        (state, _) = reducer.reduce(state: state, action: .dataLoaded([match], [1: odds]))

        // When
        let (_, effect) = reducer.reduce(state: state, action: .matchTapped(1))

        // Then
        #expect(effect == .navigate(match: match, odds: odds))
    }

    @Test func matchTapped_returnsNone_whenMatchNotFound() {
        // Given
        let state = makeState()

        // When
        let (_, effect) = reducer.reduce(state: state, action: .matchTapped(999))

        // Then
        #expect(effect == .none)
    }

    @Test func matchTapped_returnsNone_whenOddsAreNil() {
        // Given — match exists in oddsIndex but was loaded without odds
        let match = Match(matchID: 1, teamA: "Eagles", teamB: "Tigers", startTime: Date())
        var state = makeState()
        (state, _) = reducer.reduce(state: state, action: .dataLoaded([match], [:]))

        // When
        let (_, effect) = reducer.reduce(state: state, action: .matchTapped(1))

        // Then
        #expect(effect == .none)
    }
}
