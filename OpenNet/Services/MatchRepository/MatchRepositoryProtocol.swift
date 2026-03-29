import Foundation

/// Abstracts match data access: fetches from network, caches in memory, and applies real-time updates.
/// Inject this protocol into any ViewModel that needs match or odds data.
protocol MatchRepositoryProtocol: Actor {
    /// Cached matches from the last successful fetch.
    var cachedMatches: [Match] { get }
    var cachedOddsMap: [Int: MatchOdds] { get }

    /// Returns true if the cache exists and has not expired.
    var isCacheValid: Bool { get }

    /// Fetches fresh matches and odds concurrently; updates the internal cache on success.
    func load() async throws -> ([Match], [Int: MatchOdds])

    /// Forces a fresh fetch regardless of cache state.
    func forceLoad() async throws -> ([Match], [Int: MatchOdds])

    /// Applies a single real-time odds update to the in-memory cache.
    func applyUpdate(_ update: OddsUpdate)
}
