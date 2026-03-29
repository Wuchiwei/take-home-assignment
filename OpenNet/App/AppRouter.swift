import SwiftUI

enum AppDestination: Hashable {
    case matchDetail(match: Match, odds: MatchOdds)
}

@Observable
final class AppRouter {
    var path = NavigationPath()

    func push(_ destination: AppDestination) {
        path.append(destination)
    }
}
