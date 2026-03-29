import Foundation

enum ConnectionStatus: Equatable {
    case idle
    case connected
    case reconnecting(attempt: Int)

    var label: String {
        switch self {
        case .idle:                      return Strings.Connection.idle
        case .connected:                 return Strings.Connection.connected
        case .reconnecting(let attempt): return Strings.Connection.reconnecting(attempt: attempt)
        }
    }
}

enum DisconnectReason: Sendable {
    case invalidURL
    case serverClosed
    case networkError(String)
    case manual
}

enum WebSocketEvent: Sendable {
    case connected
    case oddsUpdate(OddsUpdate)
    case disconnected(reason: DisconnectReason)
}
