import SwiftUI

struct MatchListViewContainer: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var viewModel: MatchListViewModel

    init(dependencies: any MatchListDependencies, router: AppRouter) {
        _viewModel = State(initialValue: dependencies.makeMatchListViewModel(router: router))
    }

    var body: some View {
        #if DEBUG
        let _ = Self._printChanges()
        #endif
        MatchListView(
            title: viewModel.title,
            loadingText: viewModel.loadingText,
            retryText: viewModel.retryText,
            viewState: viewModel.state.viewState,
            connectionStatus: viewModel.state.connectionStatus,
            onMatchTap: { viewModel.didTapMatch(id: $0) },
            onRetry: { await viewModel.retry() },
            onRefresh: { await viewModel.refresh() }
        )
        .task {
            await viewModel.start()
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:     viewModel.didBecomeActive()
            case .background: viewModel.didEnterBackground()
            default:          break
            }
        }
    }
}

private struct MatchListView: View {
    let title: String
    let loadingText: String
    let retryText: String
    let viewState: MatchListViewState
    let connectionStatus: ConnectionStatus
    var onMatchTap: (Int) -> Void = { _ in }
    var onRetry: () async -> Void = {}
    var onRefresh: () async -> Void = {}

    var body: some View {
        #if DEBUG
        let _ = Self._printChanges()
        #endif
        Group {
            switch viewState {
            case .loading:
                loadingView
            case .error(let message):
                errorView(message: message)
            case .loaded(let matches):
                matchList(matches: matches)
                    .refreshable {
                        await onRefresh()
                    }
            }
        }
        .navigationTitle(title)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ConnectionStatusBadge(status: connectionStatus)
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text(loadingText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button(retryText) {
                Task { await onRetry() }
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
    }

    private func matchList(matches: [MatchRowViewModel]) -> some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(matches) { match in
                    Button {
                        onMatchTap(match.id)
                    } label: {
                        MatchRowView(viewModel: match)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
}

private struct ConnectionStatusBadge: View {
    let status: ConnectionStatus

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(dotColor)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var dotColor: Color {
        switch status {
        case .connected:          return .green
        case .reconnecting:       return .orange
        case .idle:               return .gray
        }
    }

    private var label: String { status.label }
}

#if DEBUG
#Preview("With data") {
    let sampleMatches = (0..<10).map { i in
        MatchRowViewModel(
            match: Match(
                matchID: 1001 + i,
                teamA: "Eagles \(i + 1)",
                teamB: "Tigers \(i + 1)",
                startTime: Date()
            ),
            odds: MatchOdds(
                matchID: 1001 + i,
                teamAOdds: 2.35,
                teamBOdds: 1.75
            ),
            colorScheme: .western
        )
    }

    NavigationStack {
        MatchListView(
            title: "Live Odds",
            loadingText: "Loading...",
            retryText: "Retry",
            viewState: .loaded(sampleMatches),
            connectionStatus: .connected
        )
    }
}

#Preview("Loading") {
    NavigationStack {
        MatchListView(
            title: "Live Odds",
            loadingText: "Loading...",
            retryText: "Retry",
            viewState: .loading,
            connectionStatus: .idle
        )
    }
}

#Preview("Error") {
    NavigationStack {
        MatchListView(
            title: "Live Odds",
            loadingText: "Loading...",
            retryText: "Retry",
            viewState: .error("Unable to connect to server. Please check your network connection."),
            connectionStatus: .idle
        )
    }
}
#endif
