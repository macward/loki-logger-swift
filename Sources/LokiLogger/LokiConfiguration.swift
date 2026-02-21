import Foundation

/// Configuration for the LokiLogger client.
///
/// Defines the Loki endpoint, application metadata, and tuning
/// parameters for batching, retry, and buffer behavior.
public struct LokiConfiguration: Sendable {

    // MARK: - Properties

    /// Loki push API endpoint URL.
    public let endpoint: URL

    /// Application name used as a label.
    public let app: String

    /// Environment name (e.g., "production", "staging").
    public let environment: String

    /// Number of log entries per batch (default: 20).
    public let batchSize: Int

    /// Seconds between automatic flushes (default: 10).
    public let flushInterval: TimeInterval

    /// Maximum retry attempts for failed requests (default: 3).
    @available(*, deprecated, message: "Use retryConfiguration.maxRetries instead")
    public var maxRetries: Int { retryConfiguration.maxRetries }

    /// Retry configuration with exponential backoff settings.
    public let retryConfiguration: RetryConfiguration

    /// Maximum buffer size before dropping oldest entries (default: 500).
    public let maxBufferSize: Int

    /// Additional custom labels to attach to all log entries.
    public let extraLabels: [String: String]

    /// Device information provider for automatic device labels.
    public let deviceInfo: (any DeviceInfoProviding)?

    /// Authentication method for Loki requests.
    public let authentication: LokiAuthentication

    /// Whether to compress request bodies with gzip.
    public let compressionEnabled: Bool

    /// Persistence provider for offline log storage.
    public let persistence: (any LogPersisting)?

    // MARK: - Lifecycle

    /// Creates a new Loki configuration.
    ///
    /// - Parameters:
    ///   - endpoint: Loki push API endpoint URL.
    ///   - app: Application name for labeling.
    ///   - environment: Environment name (e.g., "production").
    ///   - batchSize: Entries per batch (default: 20).
    ///   - flushInterval: Seconds between flushes (default: 10).
    ///   - maxRetries: Retry attempts for failures (default: 3).
    ///   - maxBufferSize: Max buffer before dropping (default: 500).
    ///   - extraLabels: Custom labels for all entries (default: empty).
    ///   - deviceInfo: Device info provider for automatic device labels (default: DeviceInfo()).
    ///   - authentication: Authentication method for Loki requests (default: .none).
    ///   - compressionEnabled: Whether to compress requests with gzip (default: false).
    ///   - persistence: Persistence provider for offline storage (default: nil).
    ///   - retryConfiguration: Retry configuration with backoff settings (default: .default).
    public init(
        endpoint: URL,
        app: String,
        environment: String,
        batchSize: Int = 20,
        flushInterval: TimeInterval = 10,
        maxRetries: Int = 3,
        maxBufferSize: Int = 500,
        extraLabels: [String: String] = [:],
        deviceInfo: (any DeviceInfoProviding)? = DeviceInfo(),
        authentication: LokiAuthentication = .none,
        compressionEnabled: Bool = false,
        persistence: (any LogPersisting)? = nil,
        retryConfiguration: RetryConfiguration? = nil
    ) {
        self.endpoint = endpoint
        self.app = app
        self.environment = environment
        self.batchSize = batchSize
        self.flushInterval = flushInterval
        self.maxBufferSize = maxBufferSize
        self.extraLabels = extraLabels
        self.deviceInfo = deviceInfo
        self.authentication = authentication
        self.compressionEnabled = compressionEnabled
        self.persistence = persistence
        // Use provided retryConfiguration or create one from maxRetries for backward compatibility
        self.retryConfiguration = retryConfiguration ?? RetryConfiguration(maxRetries: maxRetries)
    }
}
