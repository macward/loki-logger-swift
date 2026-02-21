/// Log severity levels for categorizing log entries.
///
/// Conforms to `Sendable` for safe use across concurrency domains
/// and `CaseIterable` for iterating over all available levels.
public enum LogLevel: String, Sendable, CaseIterable {
    /// Verbose debugging information for development.
    case debug
    /// General informational messages.
    case info
    /// Warning conditions that should be addressed.
    case warn
    /// Error conditions requiring attention.
    case error
}
