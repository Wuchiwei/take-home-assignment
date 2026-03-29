import Foundation

/// Layer 2: feature-specific data service.
/// Knows which endpoints to call and how to decode the responses.
/// The ViewModel only talks to this layer.
protocol DataServiceProtocol {
    func fetchMatches() async throws -> [Match]
    func fetchOdds() async throws -> [MatchOdds]
}
