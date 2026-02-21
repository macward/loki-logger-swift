import Foundation

/// Protocol for persisting log entries during offline scenarios.
///
/// Implementations can store logs to disk, database, or other
/// persistent storage for recovery after network failures or app restarts.
public protocol LogPersisting: Sendable {

    /// Saves log entries to persistent storage, replacing any existing entries.
    ///
    /// - Parameter entries: Log entries to persist.
    /// - Throws: Persistence-related errors.
    func save(_ entries: [LogEntry]) async throws

    /// Loads persisted entries and clears storage.
    ///
    /// - Returns: Previously persisted log entries.
    /// - Throws: Persistence-related errors.
    func loadAndClear() async throws -> [LogEntry]

    /// Appends entries to existing persisted entries.
    ///
    /// - Parameter entries: Log entries to append.
    /// - Throws: Persistence-related errors.
    func append(_ entries: [LogEntry]) async throws

    /// Clears all persisted entries.
    ///
    /// - Throws: Persistence-related errors.
    func clear() async throws
}
