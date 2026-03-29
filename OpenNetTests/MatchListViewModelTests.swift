import Foundation
import SwiftUI
import Testing
@testable import OpenNet

@MainActor
struct MatchListViewModelTests {

    // MARK: - Stubs

    private actor StubRepository: MatchRepositoryProtocol {
        var cachedMatches: [Match] = []
        var cachedOddsMap: [Int: MatchOdds] = [:]
        var isCacheValid = false

        var loadResult: Result<([Match], [Int: MatchOdds]), Error> = .success(([], [:]))
        private(set) var loadCallCount = 0
        private(set) var forceLoadCallCount = 0
        private(set) var appliedUpdates: [OddsUpdate] = []

        func setLoadResult(_ result: Result<([Match], [Int: MatchOdds]), Error>) {
            loadResult = result
        }

        func load() async throws -> ([Match], [Int: MatchOdds]) {
            loadCallCount += 1
            return try loadResult.get()
        }

        func forceLoad() async throws -> ([Match], [Int: MatchOdds]) {
            forceLoadCallCount += 1
            return try loadResult.get()
        }

        func applyUpdate(_ update: OddsUpdate) {
            appliedUpdates.append(update)
        }
    }

    private final class StubOddsStreamService: OddsStreamServiceProtocol {
        var eventsToEmit: [WebSocketEvent] = []
        private(set) var connectCallCount = 0
        private(set) var disconnectCallCount = 0

        func connect() -> AsyncStream<WebSocketEvent> {
            connectCallCount += 1
            let events = eventsToEmit
            return AsyncStream { continuation in
                for event in events {
                    continuation.yield(event)
                }
                continuation.finish()
            }
        }

        func disconnect() {
            disconnectCallCount += 1
        }
    }

    // MARK: - Helpers

    private func makeSUT(
        repository: StubRepository? = nil,
        oddsStreamService: StubOddsStreamService? = nil
    ) -> (MatchListViewModel, StubRepository, StubOddsStreamService, AppRouter) {
        let repo = repository ?? StubRepository()
        let stream = oddsStreamService ?? StubOddsStreamService()
        let router = AppRouter()
        let reducer = MatchListReducer(colorScheme: .western)
        let vm = MatchListViewModel(
            reducer: reducer,
            router: router,
            repository: repo,
            oddsStreamService: stream
        )
        return (vm, repo, stream, router)
    }

    private func makeSampleData() -> ([Match], [Int: MatchOdds]) {
        let matches = [
            Match(matchID: 1, teamA: "Eagles", teamB: "Tigers", startTime: Date()),
        ]
        let oddsMap: [Int: MatchOdds] = [
            1: MatchOdds(matchID: 1, teamAOdds: 1.5, teamBOdds: 2.3),
        ]
        return (matches, oddsMap)
    }

    // MARK: - start

    @Test func start_loadsDataAndConnectsWebSocket() async {
        // Given
        let (matches, oddsMap) = makeSampleData()
        let repo = StubRepository()
        await repo.setLoadResult(.success((matches, oddsMap)))
        let stream = StubOddsStreamService()
        stream.eventsToEmit = [.connected]
        let (vm, _, _, _) = makeSUT(repository: repo, oddsStreamService: stream)

        // When
        await vm.start()

        // Then
        await #expect(repo.loadCallCount == 1)
        #expect(stream.connectCallCount == 1)
        if case .loaded(let viewModels) = vm.state.viewState {
            #expect(viewModels.count == 1)
        } else {
            Issue.record("Expected .loaded state but got \(vm.state.viewState)")
        }
    }

    @Test func start_whenLoadFails_showsErrorAndSkipsConnect() async {
        // Given
        let repo = StubRepository()
        await repo.setLoadResult(.failure(
            NSError(
                domain: "test",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Network error"]
            )
        ))
        let stream = StubOddsStreamService()
        let (vm, _, _, _) = makeSUT(repository: repo, oddsStreamService: stream)

        // When
        await vm.start()

        // Then
        await #expect(repo.loadCallCount == 1)
        #expect(stream.connectCallCount == 0)
        if case .error = vm.state.viewState {
            // expected
        } else {
            Issue.record("Expected .error state but got \(vm.state.viewState)")
        }
    }

    // MARK: - refresh

    @Test func refresh_callsForceLoad() async {
        // Given
        let (matches, oddsMap) = makeSampleData()
        let repo = StubRepository()
        await repo.setLoadResult(.success((matches, oddsMap)))
        let (vm, _, _, _) = makeSUT(repository: repo)

        // When
        await vm.refresh()

        // Then
        await #expect(repo.forceLoadCallCount == 1)
    }

    // MARK: - Background / Active

    @Test func enterBackground_disconnectsWebSocket() async {
        // Given
        let (matches, oddsMap) = makeSampleData()
        let repo = StubRepository()
        await repo.setLoadResult(.success((matches, oddsMap)))
        let stream = StubOddsStreamService()
        stream.eventsToEmit = [.connected]
        let (vm, _, _, _) = makeSUT(repository: repo, oddsStreamService: stream)
        await vm.start()

        // When
        vm.didEnterBackground()
        try? await Task.sleep(for: .milliseconds(50))

        // Then
        #expect(stream.disconnectCallCount == 1)
        #expect(vm.state.hasEnteredBackground == true)
    }

    @Test func becomeActive_afterBackground_reconnects() async {
        // Given
        let (matches, oddsMap) = makeSampleData()
        let repo = StubRepository()
        await repo.setLoadResult(.success((matches, oddsMap)))
        let stream = StubOddsStreamService()
        stream.eventsToEmit = [.connected]
        let (vm, _, _, _) = makeSUT(repository: repo, oddsStreamService: stream)
        await vm.start()
        vm.didEnterBackground()
        try? await Task.sleep(for: .milliseconds(50))

        // When
        vm.didBecomeActive()
        try? await Task.sleep(for: .milliseconds(50))

        // Then — should have loaded again and reconnected
        await #expect(repo.loadCallCount == 2)
        #expect(stream.connectCallCount == 2)
        #expect(vm.state.hasEnteredBackground == false)
    }

    // MARK: - Retry

    @Test func retry_afterError_loadsSuccessfully() async {
        // Given — first load fails
        let (matches, oddsMap) = makeSampleData()
        let repo = StubRepository()
        await repo.setLoadResult(.failure(
            NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "fail"])
        ))
        let stream = StubOddsStreamService()
        stream.eventsToEmit = [.connected]
        let (vm, _, _, _) = makeSUT(repository: repo, oddsStreamService: stream)
        await vm.start()

        // When — fix the error and retry
        await repo.setLoadResult(.success((matches, oddsMap)))
        await vm.retry()

        // Then
        if case .loaded(let viewModels) = vm.state.viewState {
            #expect(viewModels.count == 1)
        } else {
            Issue.record("Expected .loaded state but got \(vm.state.viewState)")
        }
    }

    // MARK: - Navigation

    @Test func matchTapped_pushesMatchDetailToRouter() async {
        // Given
        let match = Match(
            matchID: 1,
            teamA: "Eagles",
            teamB: "Tigers",
            startTime: Date()
        )
        let odds = MatchOdds(matchID: 1, teamAOdds: 1.5, teamBOdds: 2.3)
        let repo = StubRepository()
        await repo.setLoadResult(.success(([match], [1: odds])))
        let stream = StubOddsStreamService()
        stream.eventsToEmit = [.connected]
        let (vm, _, _, router) = makeSUT(repository: repo, oddsStreamService: stream)
        await vm.start()

        // When
        vm.didTapMatch(id: 1)
        try? await Task.sleep(for: .milliseconds(50))

        // Then
        #expect(router.path.count == 1)
    }

    // MARK: - Odds Update

    @Test func oddsUpdate_appliedToViewModelAndRepository() async {
        // Given
        let match = Match(
            matchID: 1,
            teamA: "Eagles",
            teamB: "Tigers",
            startTime: Date()
        )
        let odds = MatchOdds(matchID: 1, teamAOdds: 1.5, teamBOdds: 2.3)
        let repo = StubRepository()
        await repo.setLoadResult(.success(([match], [1: odds])))
        let update = OddsUpdate(matchID: 1, teamAOdds: 1.8, teamBOdds: 2.0)
        let stream = StubOddsStreamService()
        stream.eventsToEmit = [.connected, .oddsUpdate(update)]
        let (vm, _, _, _) = makeSUT(repository: repo, oddsStreamService: stream)

        // When
        await vm.start()

        // Then — viewModel updated
        if case .loaded(let viewModels) = vm.state.viewState {
            #expect(viewModels[0].teamAOdds == 1.8)
            #expect(viewModels[0].teamBOdds == 2.0)
        } else {
            Issue.record("Expected .loaded state")
        }

        // Then — repository updated
        let appliedUpdates = await repo.appliedUpdates
        #expect(appliedUpdates.count == 1)
        #expect(appliedUpdates.first?.matchID == 1)
    }
}
