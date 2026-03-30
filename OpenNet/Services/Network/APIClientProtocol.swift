import Foundation

struct APIEndpoint {
    let path: String
    let method: String

    static func get(_ path: String) -> APIEndpoint {
        APIEndpoint(path: path, method: "GET")
    }
}

/// Layer 1: generic HTTP client. Builds URLRequests from endpoints,
/// executes them, and returns raw Data. No knowledge of domain models.
///
/// Production implementation (`URLSessionAPIClient`) should handle:
/// - Request timeout via `URLSessionConfiguration.timeoutIntervalForRequest`
/// - Retry with exponential backoff for transient failures (5xx, timeout)
/// - Network reachability check via `NWPathMonitor` to fail fast when offline
/// - SSL pinning to prevent MITM attacks on sensitive odds data
/// - Auth token refresh on 401, then retry the original request
/// - HTTP conditional requests (`ETag` / `If-Modified-Since`)
/// - Rate limiting: handle 429 with `Retry-After`
protocol APIClientProtocol {
    var baseURL: URL { get }
    func request(_ endpoint: APIEndpoint) async throws -> Data
}
