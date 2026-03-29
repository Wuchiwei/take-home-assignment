import Foundation

/// Layer 2: feature-specific WebSocket service.
/// Owns the endpoint URL, handles reconnection policy, decodes raw data into typed events.
/// The ViewModel only talks to this layer.
protocol OddsStreamServiceProtocol {
    /// Connects and returns a unified stream of typed events.
    /// Auto-reconnects on network errors. The stream ends when disconnect() is called.
    func connect() -> AsyncStream<WebSocketEvent>

    // In a production app, subscribe/unsubscribe would tell the server which
    // matchIDs to push updates for:
    //
    //   func subscribe(matchIDs: Set<Int>)
    //   func unsubscribe(matchIDs: Set<Int>)

    /// Tears down the connection and cancels any pending reconnection attempts.
    func disconnect()
}
