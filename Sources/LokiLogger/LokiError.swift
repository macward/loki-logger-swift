import Foundation

/// Errors that can occur during LokiLogger operations.
public enum LokiError: Error, Sendable {
    /// Logger has not been configured before use.
    case notConfigured

    /// Server returned an unexpected status code.
    case invalidResponse(statusCode: Int)

    /// Network request failed with underlying error.
    case networkError(any Error & Sendable)

    /// Failed to encode log entries to JSON.
    case encodingError(any Error & Sendable)

    /// Failed to compress request body.
    case compressionError(any Error & Sendable)

    /// Failed to persist or recover log entries.
    case persistenceError(any Error & Sendable)
}
