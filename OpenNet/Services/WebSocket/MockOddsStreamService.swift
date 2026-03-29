#if DEBUG
import Foundation

/// Layer 2 mock: wraps a transport, decodes OddsUpdate from raw JSON,
/// and auto-reconnects with exponential backoff (3s → 6s → 12s → ... max 5min).
final class MockOddsStreamService: OddsStreamServiceProtocol {
    private let transport: any WebSocketTransportProtocol
    private let urlString: String
    private let token: String
    private var connectionTask: Task<Void, Never>?

    init(
        transport: any WebSocketTransportProtocol = MockWebSocketTransport(),
        urlString: String = "wss://api.example.com/odds",
        token: String = "mock-token"
    ) {
        self.transport = transport
        self.urlString = urlString
        self.token = token
    }

    func connect() -> AsyncStream<WebSocketEvent> {
        AsyncStream { [weak self] continuation in
            guard let self else {
                continuation.finish()
                return
            }

            guard let url = URL(string: self.urlString) else {
                continuation.yield(.disconnected(reason: .invalidURL))
                continuation.finish()
                return
            }

            let task = Task {
                let decoder = JSONDecoder()
                var reconnectDelay: Duration = .seconds(3)
                let maxReconnectDelay: Duration = .seconds(300)

                while !Task.isCancelled {
                    for await rawEvent in self.transport.connect(
                        url: url,
                        token: self.token
                    ) {
                        switch rawEvent {
                        case .connected:
                            reconnectDelay = .seconds(3) // Reset on successful connection
                            continuation.yield(.connected)

                        case .message(let data):
                            if let update = try? decoder.decode(
                                OddsUpdate.self,
                                from: data
                            ) {
                                continuation.yield(.oddsUpdate(update))
                            }

                        case .disconnected(let reason):
                            continuation.yield(.disconnected(reason: reason))
                        }
                    }

                    // Transport stream ended — reconnect with exponential backoff
                    guard !Task.isCancelled else { break }
                    try? await Task.sleep(for: reconnectDelay)
                    guard !Task.isCancelled else { break }
                    reconnectDelay = min(reconnectDelay * 2, maxReconnectDelay)
                }

                continuation.finish()
            }

            self.connectionTask?.cancel()
            self.connectionTask = task

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    func disconnect() {
        connectionTask?.cancel()
        connectionTask = nil
        transport.disconnect()
    }
}
#endif
