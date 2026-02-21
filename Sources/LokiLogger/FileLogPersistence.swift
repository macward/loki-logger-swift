import Foundation

/// File-based implementation of log persistence.
///
/// Stores log entries as JSON in a file within the app's caches directory.
/// Thread-safe through actor isolation for concurrent access.
public actor FileLogPersistence: LogPersisting {

    // MARK: - Properties

    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let fileManager: FileManager

    // MARK: - Lifecycle

    /// Creates a new file-based log persistence.
    ///
    /// - Parameters:
    ///   - filename: Name of the persistence file (default: "loki_logs_cache.json").
    ///   - fileManager: FileManager for file operations (default: .default).
    public init(
        filename: String = "loki_logs_cache.json",
        fileManager: FileManager = .default
    ) {
        let cacheDirectory: URL = fileManager.urls(
            for: .cachesDirectory,
            in: .userDomainMask
        ).first!

        self.fileURL = cacheDirectory.appendingPathComponent(filename)
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        self.fileManager = fileManager
    }

    /// Creates a file persistence with a custom URL (for testing).
    ///
    /// - Parameters:
    ///   - fileURL: URL for the persistence file.
    ///   - fileManager: FileManager for file operations.
    internal init(
        fileURL: URL,
        fileManager: FileManager = .default
    ) {
        self.fileURL = fileURL
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        self.fileManager = fileManager
    }

    // MARK: - LogPersisting

    public func save(_ entries: [LogEntry]) async throws {
        let data: Data = try encoder.encode(entries)
        try data.write(to: fileURL, options: .atomic)
    }

    public func loadAndClear() async throws -> [LogEntry] {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return []
        }

        let data: Data = try Data(contentsOf: fileURL)
        let entries: [LogEntry] = try decoder.decode([LogEntry].self, from: data)

        try await clear()

        return entries
    }

    public func append(_ entries: [LogEntry]) async throws {
        var existingEntries: [LogEntry] = []

        if fileManager.fileExists(atPath: fileURL.path) {
            let data: Data = try Data(contentsOf: fileURL)
            existingEntries = try decoder.decode([LogEntry].self, from: data)
        }

        let combined: [LogEntry] = existingEntries + entries
        try await save(combined)
    }

    public func clear() async throws {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return
        }
        try fileManager.removeItem(at: fileURL)
    }
}
