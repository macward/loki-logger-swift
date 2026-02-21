import Foundation
import OSLog

/// Main public interface for LokiLogger.
///
/// Provides static convenience methods for logging and a configurable
/// shared instance. Configure once at app startup, then use static
/// logging methods throughout your codebase.
///
/// Example:
/// ```swift
/// LokiLogger.configure(
///     endpoint: lokiURL,
///     app: "MyApp",
///     environment: "production"
/// )
///
/// LokiLogger.info("User logged in", metadata: ["userId": "123"])
/// ```
public final class LokiLogger: @unchecked Sendable {

    // MARK: - Properties

    /// Shared instance for static API access.
    public static let shared: LokiLogger = LokiLogger()

    private var buffer: LogBuffer?
    private var configuration: LokiConfiguration?
    private let logger: Logger = Logger(subsystem: "LokiLogger", category: "Internal")

    // MARK: - Lifecycle

    private init() {}

    /// Creates a new instance with injected dependencies (for testing).
    ///
    /// - Parameters:
    ///   - buffer: Log buffer for batching and sending.
    ///   - configuration: Loki configuration.
    public init(buffer: LogBuffer, configuration: LokiConfiguration) {
        self.buffer = buffer
        self.configuration = configuration
    }

    // MARK: - Configuration

    /// Configures the shared logger instance.
    ///
    /// Call this once at app startup before logging.
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
    ///   - deviceInfo: Device info for automatic labels (default: DeviceInfo()).
    ///   - authentication: Authentication method for Loki requests (default: .none).
    ///   - compressionEnabled: Whether to compress requests with gzip (default: false).
    ///   - persistence: Persistence provider for offline storage (default: nil).
    ///   - session: URLSession for network requests (default: .shared).
    public static func configure(
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
        session: any URLSessionProtocol = URLSession.shared
    ) {
        let configuration: LokiConfiguration = LokiConfiguration(
            endpoint: endpoint,
            app: app,
            environment: environment,
            batchSize: batchSize,
            flushInterval: flushInterval,
            maxRetries: maxRetries,
            maxBufferSize: maxBufferSize,
            extraLabels: extraLabels,
            deviceInfo: deviceInfo,
            authentication: authentication,
            compressionEnabled: compressionEnabled,
            persistence: persistence
        )

        let transport: LokiTransport = LokiTransport(
            configuration: configuration,
            session: session
        )

        let buffer: LogBuffer = LogBuffer(
            transport: transport,
            configuration: configuration
        )

        shared.configuration = configuration
        shared.buffer = buffer

        Task {
            await buffer.start()
        }
    }

    // MARK: - Logging Methods

    /// Logs a debug message.
    ///
    /// - Parameters:
    ///   - message: Log message content.
    ///   - metadata: Optional key-value pairs for additional context.
    public static func debug(_ message: String, metadata: [String: String] = [:]) {
        shared.log(level: .debug, message: message, metadata: metadata)
    }

    /// Logs an info message.
    ///
    /// - Parameters:
    ///   - message: Log message content.
    ///   - metadata: Optional key-value pairs for additional context.
    public static func info(_ message: String, metadata: [String: String] = [:]) {
        shared.log(level: .info, message: message, metadata: metadata)
    }

    /// Logs a warning message.
    ///
    /// - Parameters:
    ///   - message: Log message content.
    ///   - metadata: Optional key-value pairs for additional context.
    public static func warn(_ message: String, metadata: [String: String] = [:]) {
        shared.log(level: .warn, message: message, metadata: metadata)
    }

    /// Logs an error message.
    ///
    /// - Parameters:
    ///   - message: Log message content.
    ///   - metadata: Optional key-value pairs for additional context.
    public static func error(_ message: String, metadata: [String: String] = [:]) {
        shared.log(level: .error, message: message, metadata: metadata)
    }

    /// Logs a critical message.
    ///
    /// - Parameters:
    ///   - message: Log message content.
    ///   - metadata: Optional key-value pairs for additional context.
    public static func critical(_ message: String, metadata: [String: String] = [:]) {
        shared.log(level: .critical, message: message, metadata: metadata)
    }

    /// Flushes all buffered log entries immediately.
    public static func flush() async {
        await shared.buffer?.flush()
    }

    /// Stops the logger and flushes remaining entries.
    public static func stop() async {
        await shared.buffer?.stop()
    }

    // MARK: - Instance Methods

    /// Logs a message with the specified level.
    ///
    /// - Parameters:
    ///   - level: Log severity level.
    ///   - message: Log message content.
    ///   - metadata: Optional key-value pairs for additional context.
    public func log(level: LogLevel, message: String, metadata: [String: String] = [:]) {
        guard let buffer else {
            logger.warning("LokiLogger not configured. Call configure() first.")
            return
        }

        let entry: LogEntry = LogEntry(
            level: level,
            message: message,
            metadata: metadata
        )

        Task {
            await buffer.append(entry)
        }
    }
}
