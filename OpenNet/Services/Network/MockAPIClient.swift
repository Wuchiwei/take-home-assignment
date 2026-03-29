#if DEBUG
import Foundation

/// Mock API client that returns in-memory JSON for known endpoints.
/// Simulates network latency and randomized data without hitting a real server.
final class MockAPIClient: APIClientProtocol {
    let baseURL = URL(string: "https://api.example.com")!

    func request(_ endpoint: APIEndpoint) async throws -> Data {
        try await Task.sleep(for: .milliseconds(Int.random(in: 200...400)))

        switch endpoint.path {
        case "/matches":
            return try buildMatchesJSON()
        case "/odds":
            return try buildOddsJSON()
        default:
            throw URLError(.badURL)
        }
    }
}

private extension MockAPIClient {
    static let teamNames = [
        "Eagles", "Tigers", "Lions", "Bears", "Wolves", "Hawks",
        "Sharks", "Panthers", "Dragons", "Falcons", "Knights", "Rebels",
        "Storm", "Thunder", "Blaze", "Frost", "Vipers", "Cobras",
        "Titans", "Giants", "Raptors", "Stallions", "Phoenix", "Cyclones"
    ]

    func buildMatchesJSON() throws -> Data {
        let now = Date()
        let formatter = ISO8601DateFormatter()
        let shuffledNames = Self.teamNames.shuffled()

        let jsonArray: [[String: Any]] = (0..<MockConstants.matchCount).map { i in
            let teamAIndex = (i * 2) % shuffledNames.count
            let teamBIndex = (i * 2 + 1) % shuffledNames.count
            let offsetMinutes = Int.random(in: 0...1440) // within 24 hours
            let startTime = now.addingTimeInterval(TimeInterval(offsetMinutes * 60))

            return [
                "matchID": MockConstants.matchIDStart + i,
                "teamA": "\(shuffledNames[teamAIndex]) \(i / shuffledNames.count + 1)",
                "teamB": "\(shuffledNames[teamBIndex]) \(i / shuffledNames.count + 1)",
                "startTime": formatter.string(from: startTime)
            ]
        }

        return try JSONSerialization.data(withJSONObject: jsonArray)
    }

    func buildOddsJSON() throws -> Data {
        let jsonArray: [[String: Any]] = (0..<MockConstants.matchCount).map { i in
            [
                "matchID": MockConstants.matchIDStart + i,
                "teamAOdds": Double.random(in: 1.10...5.00).rounded(toPlaces: 2),
                "teamBOdds": Double.random(in: 1.10...5.00).rounded(toPlaces: 2)
            ]
        }

        return try JSONSerialization.data(withJSONObject: jsonArray)
    }
}
#endif
