import Foundation
@testable import LokiLogger

/// Mock implementation of LogPersisting for testing.
actor MockLogPersistence: LogPersisting {

    // MARK: - Properties

    private(set) var savedEntries: [LogEntry] = []
    private(set) var saveCallCount: Int = 0
    private(set) var loadAndClearCallCount: Int = 0
    private(set) var appendCallCount: Int = 0
    private(set) var clearCallCount: Int = 0

    var shouldThrowOnSave: Bool = false
    var shouldThrowOnLoad: Bool = false
    var shouldThrowOnAppend: Bool = false
    var shouldThrowOnClear: Bool = false

    // MARK: - LogPersisting

    func save(_ entries: [LogEntry]) async throws {
        saveCallCount += 1
        if shouldThrowOnSave {
            throw MockPersistenceError.saveFailed
        }
        savedEntries = entries
    }

    func loadAndClear() async throws -> [LogEntry] {
        loadAndClearCallCount += 1
        if shouldThrowOnLoad {
            throw MockPersistenceError.loadFailed
        }
        let entries: [LogEntry] = savedEntries
        savedEntries = []
        return entries
    }

    func append(_ entries: [LogEntry]) async throws {
        appendCallCount += 1
        if shouldThrowOnAppend {
            throw MockPersistenceError.appendFailed
        }
        savedEntries.append(contentsOf: entries)
    }

    func clear() async throws {
        clearCallCount += 1
        if shouldThrowOnClear {
            throw MockPersistenceError.clearFailed
        }
        savedEntries = []
    }

    // MARK: - Test Helpers

    func reset() {
        savedEntries = []
        saveCallCount = 0
        loadAndClearCallCount = 0
        appendCallCount = 0
        clearCallCount = 0
        shouldThrowOnSave = false
        shouldThrowOnLoad = false
        shouldThrowOnAppend = false
        shouldThrowOnClear = false
    }

    func preloadEntries(_ entries: [LogEntry]) {
        savedEntries = entries
    }
}

// MARK: - Mock Error

enum MockPersistenceError: Error {
    case saveFailed
    case loadFailed
    case appendFailed
    case clearFailed
}
