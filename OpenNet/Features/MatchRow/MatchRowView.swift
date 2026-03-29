import SwiftUI

struct MatchRowView: View {
    let viewModel: MatchRowViewModel

    var body: some View {
        #if DEBUG
        let _ = Self._printChanges()
        #endif
        VStack(spacing: 12) {
            teamsHeader
            startTimeLabel
            oddsRow
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private var teamsHeader: some View {
        HStack {
            teamAName
            versusLabel
            teamBName
        }
    }

    private var teamAName: some View {
        Text(viewModel.teamA)
            .font(.headline)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var versusLabel: some View {
        Text(viewModel.versusLabel)
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }

    private var teamBName: some View {
        Text(viewModel.teamB)
            .font(.headline)
            .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private var startTimeLabel: some View {
        Text(viewModel.formattedStartTime)
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    private var oddsRow: some View {
        HStack {
            OddsView(
                teamName: viewModel.teamA,
                oddsText: viewModel.teamAOddsText,
                oddsValue: viewModel.teamAOdds,
                colorScheme: viewModel.colorScheme
            )
            Spacer()
            OddsView(
                teamName: viewModel.teamB,
                oddsText: viewModel.teamBOddsText,
                oddsValue: viewModel.teamBOdds,
                colorScheme: viewModel.colorScheme
            )
        }
    }
}

#if DEBUG
#Preview {
    let match = Match(
        matchID: 1001,
        teamA: "Eagles 1",
        teamB: "Tigers 1",
        startTime: Date()
    )
    let odds = MatchOdds(
        matchID: 1001,
        teamAOdds: 2.35,
        teamBOdds: 1.75
    )
    MatchRowView(
        viewModel: MatchRowViewModel(
            match: match,
            odds: odds,
            colorScheme: .western
        )
    )
    .padding()
}
#endif
