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
protocol APIClientProtocol {
    var baseURL: URL { get }
    func request(_ endpoint: APIEndpoint) async throws -> Data
}
