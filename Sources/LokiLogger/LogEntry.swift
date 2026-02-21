import Darwin

/// A single log entry with timestamp, level, message, and optional metadata.
///
/// Timestamps are captured in nanoseconds since Unix epoch for
/// compatibility with Loki's log format.
public struct LogEntry: Sendable {

    // MARK: - Properties

    /// Timestamp in nanoseconds since Unix epoch.
    public let timestamp: UInt64

    /// Severity level of the log entry.
    public let level: LogLevel

    /// Log message content.
    public let message: String

    /// Additional key-value metadata attached to the entry.
    public let metadata: [String: String]

    // MARK: - Lifecycle

    /// Creates a new log entry with the current timestamp.
    ///
    /// - Parameters:
    ///   - level: Severity level for this entry.
    ///   - message: Log message content.
    ///   - metadata: Optional key-value pairs for additional context.
    public init(
        level: LogLevel,
        message: String,
        metadata: [String: String] = [:]
    ) {
        self.timestamp = clock_gettime_nsec_np(CLOCK_REALTIME)
        self.level = level
        self.message = message
        self.metadata = metadata
    }

    /// Creates a new log entry with a specific timestamp.
    ///
    /// - Parameters:
    ///   - timestamp: Timestamp in nanoseconds since Unix epoch.
    ///   - level: Severity level for this entry.
    ///   - message: Log message content.
    ///   - metadata: Optional key-value pairs for additional context.
    public init(
        timestamp: UInt64,
        level: LogLevel,
        message: String,
        metadata: [String: String] = [:]
    ) {
        self.timestamp = timestamp
        self.level = level
        self.message = message
        self.metadata = metadata
    }
}
