import SwiftUI

struct MatchDetailViewContainer: View {
    @State private var viewModel: MatchDetailViewModel

    init(dependencies: any MatchDetailDependencies, match: Match, odds: MatchOdds) {
        _viewModel = State(initialValue: dependencies.makeMatchDetailViewModel(match: match, odds: odds))
    }

    var body: some View {
        MatchDetailView(
            title: viewModel.title,
            teamA: viewModel.match.teamA,
            teamB: viewModel.match.teamB,
            startTime: viewModel.match.startTime.formatted(
                date: .abbreviated,
                time: .shortened
            ),
            teamAOdds: String(format: "%.2f", viewModel.odds.teamAOdds),
            teamBOdds: String(format: "%.2f", viewModel.odds.teamBOdds)
        )
    }
}

private struct MatchDetailView: View {
    let title: String
    let teamA: String
    let teamB: String
    let startTime: String
    let teamAOdds: String
    let teamBOdds: String

    var body: some View {
        VStack(spacing: 20) {
            teamsHeader
            startTimeLabel
            oddsRow
        }
        .padding()
        .navigationTitle(title)
    }

    private var teamsHeader: some View {
        Text("\(teamA) vs \(teamB)")
            .font(.title.bold())
    }

    private var startTimeLabel: some View {
        Text(startTime)
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }

    private var oddsRow: some View {
        HStack(spacing: 40) {
            oddsColumn(team: teamA, odds: teamAOdds)
            oddsColumn(team: teamB, odds: teamBOdds)
        }
    }

    private func oddsColumn(team: String, odds: String) -> some View {
        VStack(spacing: 4) {
            Text(odds)
                .font(.title2.bold())
            Text(team)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        MatchDetailView(
            title: "Match Detail",
            teamA: "Eagles 1",
            teamB: "Tigers 1",
            startTime: "Mar 29, 2026, 3:00 PM",
            teamAOdds: "2.35",
            teamBOdds: "1.75"
        )
    }
}
#endif
