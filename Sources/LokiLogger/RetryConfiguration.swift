import Foundation

/// Configuration for retry behavior with exponential backoff.
///
/// Calculates delays between retry attempts using exponential backoff
/// with configurable jitter to prevent thundering herd problems.
public struct RetryConfiguration: Sendable, Equatable {

    // MARK: - Properties

    /// Maximum number of retry attempts before giving up.
    public let maxRetries: Int

    /// Initial delay in seconds before first retry.
    public let baseDelay: TimeInterval

    /// Maximum delay cap in seconds.
    public let maxDelay: TimeInterval

    /// Jitter factor (0.0-1.0) for randomizing delays.
    public let jitterFactor: Double

    // MARK: - Lifecycle

    /// Creates a new retry configuration.
    ///
    /// - Parameters:
    ///   - maxRetries: Maximum retry attempts (default: 3).
    ///   - baseDelay: Initial delay in seconds (default: 1.0).
    ///   - maxDelay: Maximum delay cap in seconds (default: 30.0).
    ///   - jitterFactor: Jitter factor 0.0-1.0 (default: 0.1).
    public init(
        maxRetries: Int = 3,
        baseDelay: TimeInterval = 1.0,
        maxDelay: TimeInterval = 30.0,
        jitterFactor: Double = 0.1
    ) {
        self.maxRetries = maxRetries
        self.baseDelay = baseDelay
        self.maxDelay = maxDelay
        self.jitterFactor = min(max(jitterFactor, 0.0), 1.0)
    }

    // MARK: - Public Methods

    /// Calculates delay for a specific retry attempt.
    ///
    /// Uses exponential backoff formula: `baseDelay * 2^attempt`
    /// with optional jitter to prevent synchronized retries.
    ///
    /// - Parameter attempt: Zero-indexed attempt number.
    /// - Returns: Delay in seconds before the retry.
    public func delay(forAttempt attempt: Int) -> TimeInterval {
        let exponential: TimeInterval = baseDelay * pow(2.0, Double(attempt))
        let capped: TimeInterval = min(exponential, maxDelay)
        let jitter: Double = Double.random(in: -jitterFactor...jitterFactor)
        return capped * (1.0 + jitter)
    }

    // MARK: - Default

    /// Default retry configuration.
    public static let `default`: RetryConfiguration = RetryConfiguration()
}
