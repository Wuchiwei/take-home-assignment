import Foundation

struct Match: Sendable, Hashable, Codable {
    let matchID: Int
    let teamA: String
    let teamB: String
    let startTime: Date
}

struct MatchOdds: Sendable, Hashable, Codable {
    let matchID: Int
    var teamAOdds: Double
    var teamBOdds: Double
}

struct OddsUpdate: Sendable, Hashable, Codable {
    let matchID: Int
    let teamAOdds: Double
    let teamBOdds: Double
}
