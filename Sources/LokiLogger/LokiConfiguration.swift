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
    public let maxRetries: Int

    /// Maximum buffer size before dropping oldest entries (default: 500).
    public let maxBufferSize: Int

    /// Additional custom labels to attach to all log entries.
    public let extraLabels: [String: String]

    /// Device information provider for automatic device labels.
    public let deviceInfo: (any DeviceInfoProviding)?

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
    public init(
        endpoint: URL,
        app: String,
        environment: String,
        batchSize: Int = 20,
        flushInterval: TimeInterval = 10,
        maxRetries: Int = 3,
        maxBufferSize: Int = 500,
        extraLabels: [String: String] = [:],
        deviceInfo: (any DeviceInfoProviding)? = DeviceInfo()
    ) {
        self.endpoint = endpoint
        self.app = app
        self.environment = environment
        self.batchSize = batchSize
        self.flushInterval = flushInterval
        self.maxRetries = maxRetries
        self.maxBufferSize = maxBufferSize
        self.extraLabels = extraLabels
        self.deviceInfo = deviceInfo
    }
}
