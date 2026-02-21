import Foundation

/// Authentication methods for connecting to Loki.
///
/// Supports common authentication mechanisms including Basic Auth,
/// Bearer tokens, and custom headers for enterprise deployments.
public enum LokiAuthentication: Sendable {
    /// No authentication required.
    case none

    /// Basic HTTP authentication with username and password.
    case basic(username: String, password: String)

    /// Bearer token authentication (OAuth, JWT, API keys).
    case bearer(token: String)

    /// Custom authentication headers for specialized setups.
    case custom(headers: [String: String])

    // MARK: - Internal Methods

    /// Returns authentication headers for the request.
    internal func headers() -> [String: String] {
        switch self {
        case .none:
            return [:]

        case .basic(let username, let password):
            let credentials: String = "\(username):\(password)"
            guard let data: Data = credentials.data(using: .utf8) else {
                return [:]
            }
            let base64Credentials: String = data.base64EncodedString()
            return ["Authorization": "Basic \(base64Credentials)"]

        case .bearer(let token):
            return ["Authorization": "Bearer \(token)"]

        case .custom(let headers):
            return headers
        }
    }
}
