import SwiftUI

struct RootView: View {
    @Bindable var router: AppRouter
    private let container: AppContainer

    init(container: AppContainer, router: AppRouter) {
        self.container = container
        self.router = router
    }

    var body: some View {
        NavigationStack(path: $router.path) {
            MatchListViewContainer(dependencies: container, router: router)
                // NOTE: Scalability concern — this switch grows with every new screen.
                // Splitting cases into extensions is cosmetic; the coupling is still here.
                // At scale, reduce AppDestination to feature boundaries (not individual
                // screens), and let each feature module manage its own internal navigation
                // via its own NavigationStack or sub-path. This file then only handles
                // cross-feature transitions.
                .navigationDestination(for: AppDestination.self) { destination in
                    switch destination {
                    case .matchDetail(let match, let odds):
                        MatchDetailViewContainer(
                            dependencies: container,
                            match: match,
                            odds: odds
                        )
                    }
                }
        }
        #if DEBUG
        .overlay(alignment: .bottomTrailing) {
            FPSOverlay()
                .padding()
        }
        #endif
    }
}

#if DEBUG
#Preview {
    let container = AppContainer(
        dataService: MatchDataService(),
        oddsStreamService: MockOddsStreamService()
    )
    RootView(container: container, router: AppRouter())
}
#endif
