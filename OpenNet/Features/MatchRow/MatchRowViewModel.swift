import Foundation
import Observation

@Observable
@MainActor
final class MatchRowViewModel: Identifiable {
    let id: Int
    let match: Match
    let teamA: String
    let teamB: String
    let startTime: Date
    var teamAOdds: Double?
    var teamBOdds: Double?
    let colorScheme: OddsFlashColorScheme

    init(
        match: Match,
        odds: MatchOdds?,
        colorScheme: OddsFlashColorScheme
    ) {
        self.id = match.matchID
        self.match = match
        self.teamA = match.teamA
        self.teamB = match.teamB
        self.startTime = match.startTime
        self.teamAOdds = odds?.teamAOdds
        self.teamBOdds = odds?.teamBOdds
        self.colorScheme = colorScheme
    }

    let versusLabel = "vs"

    var formattedStartTime: String {
        startTime.formatted(date: .abbreviated, time: .shortened)
    }

    let oddsPlaceholder = "-"

    var teamAOddsText: String {
        teamAOdds.map { String(format: "%.2f", $0) } ?? oddsPlaceholder
    }

    var teamBOddsText: String {
        teamBOdds.map { String(format: "%.2f", $0) } ?? oddsPlaceholder
    }

    var currentOdds: MatchOdds? {
        guard let teamAOdds, let teamBOdds else { return nil }
        return MatchOdds(
            matchID: id,
            teamAOdds: teamAOdds,
            teamBOdds: teamBOdds
        )
    }

    func applyUpdate(_ update: OddsUpdate) {
        teamAOdds = update.teamAOdds
        teamBOdds = update.teamBOdds
    }
}
