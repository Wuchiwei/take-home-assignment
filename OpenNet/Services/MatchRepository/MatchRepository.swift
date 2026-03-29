import Foundation

actor MatchRepository: MatchRepositoryProtocol {
    private(set) var cachedMatches: [Match] = []
    private(set) var cachedOddsMap: [Int: MatchOdds] = [:]

    private let dataService: any DataServiceProtocol
    private let cacheDuration: TimeInterval
    private var lastFetchTime: Date?

    init(
        dataService: any DataServiceProtocol,
        cacheDuration: TimeInterval = 300 // 5 minutes
    ) {
        self.dataService = dataService
        self.cacheDuration = cacheDuration
    }

    var isCacheValid: Bool {
        guard let lastFetchTime, !cachedMatches.isEmpty else { return false }
        return Date().timeIntervalSince(lastFetchTime) < cacheDuration
    }

    func load() async throws -> ([Match], [Int: MatchOdds]) {
        if isCacheValid {
            return (cachedMatches, cachedOddsMap)
        }
        return try await fetchAndCache()
    }

    func forceLoad() async throws -> ([Match], [Int: MatchOdds]) {
        return try await fetchAndCache()
    }

    func applyUpdate(_ update: OddsUpdate) {
        cachedOddsMap[update.matchID] = MatchOdds(
            matchID: update.matchID,
            teamAOdds: update.teamAOdds,
            teamBOdds: update.teamBOdds
        )
    }
}

private extension MatchRepository {
    func fetchAndCache() async throws -> ([Match], [Int: MatchOdds]) {
        async let matchList = dataService.fetchMatches()
        async let oddsList  = dataService.fetchOdds()
        let (fetchedMatches, fetchedOdds) = try await (matchList, oddsList)
        let map = Dictionary(fetchedOdds.map { ($0.matchID, $0) }, uniquingKeysWith: { _, latest in latest })
        cachedMatches = fetchedMatches
        cachedOddsMap = map
        lastFetchTime = Date()
        return (fetchedMatches, map)
    }
}
