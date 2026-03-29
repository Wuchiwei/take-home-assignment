import Foundation

enum WebSocketRawEvent: Sendable {
    case connected
    case message(Data)
    case disconnected(reason: DisconnectReason)
}

/// Layer 1: raw WebSocket transport. Manages a single connection lifecycle.
/// No reconnection logic, no data decoding — those belong in the service layer.
protocol WebSocketTransportProtocol {
    func connect(url: URL, token: String?) -> AsyncStream<WebSocketRawEvent>
    func disconnect()
}
