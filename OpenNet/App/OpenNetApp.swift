//
//  OpenNetApp.swift
//  OpenNet
//
//  Created by LukeWu on 2026/3/28.
//

import SwiftUI

@main
struct OpenNetApp: App {
    @State private var router = AppRouter()

    private let container: AppContainer = {
        #if DEBUG
        return AppContainer(
            dataService: MatchDataService(),
            oddsStreamService: MockOddsStreamService()
        )
        #else
        return AppContainer(
            dataService: DataService(),
            oddsStreamService: WebSocketService()
        )
        #endif
    }()

    var body: some Scene {
        WindowGroup {
            RootView(container: container, router: router)
        }
    }
}
