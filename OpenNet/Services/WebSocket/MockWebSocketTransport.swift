#if DEBUG
import Foundation

/// Mock transport: simulates a single WebSocket connection that lasts 10–25 seconds,
/// pushes one odds update every 100ms (~10/sec), then disconnects.
final class MockWebSocketTransport: WebSocketTransportProtocol {
    private var connectionTask: Task<Void, Never>?

    func connect(url: URL, token: String?) -> AsyncStream<WebSocketRawEvent> {
        AsyncStream { [weak self] continuation in
            let task = Task.detached {
                continuation.yield(.connected)

                let matchIDRange = await MockConstants.matchIDRange

                // Controls after how many seconds the server will disconnect automatically (10–25s).
                let maxUpdates = Int.random(in: 100...250)
                var updatesSent = 0

                while !Task.isCancelled && updatesSent < maxUpdates {
                    try? await Task.sleep(for: .milliseconds(100))
                    guard !Task.isCancelled else { break }
                    updatesSent += 1

                    let teamAOdds = Double.random(in: 1.5...3.0).rounded(toPlaces: 2)
                    let teamBOdds = Double.random(in: 1.5...3.0).rounded(toPlaces: 2)
                    let json: [String: Any] = [
                        "matchID": Int.random(in: matchIDRange),
                        "teamAOdds": teamAOdds,
                        "teamBOdds": teamBOdds
                    ]
                    if let data = try? JSONSerialization.data(withJSONObject: json) {
                        continuation.yield(.message(data))
                    }
                }

                if Task.isCancelled {
                    continuation.yield(.disconnected(reason: .manual))
                } else {
                    continuation.yield(.disconnected(reason: .serverClosed))
                }
                continuation.finish()
            }

            self?.connectionTask?.cancel()
            self?.connectionTask = task

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    func disconnect() {
        connectionTask?.cancel()
        connectionTask = nil
    }
}
#endif
