#if DEBUG
import Foundation

/// Layer 2 implementation: calls APIClient for raw data, decodes into domain models.
/// In production, replace MockAPIClient with a real APIClient — this class stays the same.
final class MatchDataService: DataServiceProtocol {
    private let apiClient: any APIClientProtocol
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    init(apiClient: any APIClientProtocol = MockAPIClient()) {
        self.apiClient = apiClient
    }

    func fetchMatches() async throws -> [Match] {
        let data = try await apiClient.request(.get("/matches"))
        return try decoder.decode([Match].self, from: data)
    }

    func fetchOdds() async throws -> [MatchOdds] {
        let data = try await apiClient.request(.get("/odds"))
        return try decoder.decode([MatchOdds].self, from: data)
    }
}
#endif
