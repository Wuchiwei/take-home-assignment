import Foundation
import Testing
@testable import OpenNet

@MainActor
struct MatchRepositoryTests {

    // MARK: - Stub

    private final class StubDataService: DataServiceProtocol {
        var matchesToReturn: [Match] = []
        var oddsToReturn: [MatchOdds] = []
        var shouldThrow = false
        private(set) var fetchMatchesCallCount = 0
        private(set) var fetchOddsCallCount = 0

        func fetchMatches() async throws -> [Match] {
            fetchMatchesCallCount += 1
            if shouldThrow { throw StubError.fetch }
            return matchesToReturn
        }

        func fetchOdds() async throws -> [MatchOdds] {
            fetchOddsCallCount += 1
            if shouldThrow { throw StubError.fetch }
            return oddsToReturn
        }
    }

    private enum StubError: Error {
        case fetch
    }

    // MARK: - Helpers

    private func makeSUT(
        cacheDuration: TimeInterval = 300
    ) -> (MatchRepository, StubDataService) {
        let service = StubDataService()
        service.matchesToReturn = [
            Match(matchID: 1, teamA: "Eagles", teamB: "Tigers", startTime: Date()),
        ]
        service.oddsToReturn = [
            MatchOdds(matchID: 1, teamAOdds: 1.5, teamBOdds: 2.3),
        ]
        let repo = MatchRepository(dataService: service, cacheDuration: cacheDuration)
        return (repo, service)
    }

    // MARK: - load

    @Test func load_firstCall_fetchesFromService() async throws {
        // Given
        let (repo, service) = makeSUT()

        // When
        let (matches, oddsMap) = try await repo.load()

        // Then
        #expect(matches.count == 1)
        #expect(oddsMap[1]?.teamAOdds == 1.5)
        #expect(service.fetchMatchesCallCount == 1)
        #expect(service.fetchOddsCallCount == 1)
    }

    @Test func load_secondCall_returnsCacheWithoutFetching() async throws {
        // Given
        let (repo, service) = makeSUT()

        // When
        _ = try await repo.load()
        let (matches, _) = try await repo.load()

        // Then
        #expect(matches.count == 1)
        #expect(service.fetchMatchesCallCount == 1) // only called once
    }

    @Test func load_afterCacheExpires_fetchesAgain() async throws {
        // Given
        let (repo, service) = makeSUT(cacheDuration: 0) // expires immediately

        // When
        _ = try await repo.load()
        let (matches, _) = try await repo.load()

        // Then
        #expect(matches.count == 1)
        #expect(service.fetchMatchesCallCount == 2)
    }

    // MARK: - forceLoad

    @Test func forceLoad_alwaysFetchesEvenWithValidCache() async throws {
        // Given
        let (repo, service) = makeSUT()
        _ = try await repo.load()

        // When
        _ = try await repo.forceLoad()

        // Then
        #expect(service.fetchMatchesCallCount == 2)
        #expect(service.fetchOddsCallCount == 2)
    }

    @Test func forceLoad_updatesCacheWithNewData() async throws {
        // Given
        let (repo, service) = makeSUT()
        _ = try await repo.load()
        service.oddsToReturn = [
            MatchOdds(matchID: 1, teamAOdds: 9.9, teamBOdds: 8.8),
        ]

        // When
        _ = try await repo.forceLoad()

        // Then
        let oddsMap = await repo.cachedOddsMap
        #expect(oddsMap[1]?.teamAOdds == 9.9)
        #expect(oddsMap[1]?.teamBOdds == 8.8)
    }

    // MARK: - isCacheValid

    @Test func isCacheValid_beforeAnyLoad_returnsFalse() async {
        // Given
        let (repo, _) = makeSUT()

        // When — no action, initial state

        // Then
        let valid = await repo.isCacheValid
        #expect(valid == false)
    }

    @Test func isCacheValid_afterLoad_returnsTrue() async throws {
        // Given
        let (repo, _) = makeSUT()

        // When
        _ = try await repo.load()

        // Then
        let valid = await repo.isCacheValid
        #expect(valid == true)
    }

    @Test func isCacheValid_afterCacheExpires_returnsFalse() async throws {
        // Given
        let (repo, _) = makeSUT(cacheDuration: 0)

        // When
        _ = try await repo.load()

        // Then
        let valid = await repo.isCacheValid
        #expect(valid == false)
    }

    // MARK: - applyUpdate

    @Test func applyUpdate_updatesCachedOdds() async throws {
        // Given
        let (repo, _) = makeSUT()
        _ = try await repo.load()
        let update = OddsUpdate(matchID: 1, teamAOdds: 1.8, teamBOdds: 2.0)

        // When
        await repo.applyUpdate(update)

        // Then
        let oddsMap = await repo.cachedOddsMap
        #expect(oddsMap[1]?.teamAOdds == 1.8)
        #expect(oddsMap[1]?.teamBOdds == 2.0)
    }

    @Test func applyUpdate_forUnknownMatch_addsToCache() async {
        // Given
        let (repo, _) = makeSUT()
        let update = OddsUpdate(matchID: 999, teamAOdds: 3.0, teamBOdds: 1.2)

        // When
        await repo.applyUpdate(update)

        // Then
        let oddsMap = await repo.cachedOddsMap
        #expect(oddsMap[999]?.teamAOdds == 3.0)
    }

    @Test func applyUpdate_doesNotAffectCacheValidity() async throws {
        // Given
        let (repo, _) = makeSUT(cacheDuration: 0)
        _ = try await repo.load()
        let update = OddsUpdate(matchID: 1, teamAOdds: 1.8, teamBOdds: 2.0)

        // When
        await repo.applyUpdate(update)

        // Then — cache should still be expired
        let valid = await repo.isCacheValid
        #expect(valid == false)
    }

    // MARK: - Error Handling

    @Test func load_whenServiceThrows_propagatesError() async {
        // Given
        let (repo, service) = makeSUT()
        service.shouldThrow = true

        // When / then
        await #expect(throws: StubError.self) {
            _ = try await repo.load()
        }
    }

    @Test func load_afterFailure_cacheRemainsEmpty() async {
        // Given
        let (repo, service) = makeSUT()
        service.shouldThrow = true

        // When
        _ = try? await repo.load()

        // Then
        let matches = await repo.cachedMatches
        let oddsMap = await repo.cachedOddsMap
        let valid = await repo.isCacheValid
        #expect(matches.isEmpty)
        #expect(oddsMap.isEmpty)
        #expect(valid == false)
    }
}
