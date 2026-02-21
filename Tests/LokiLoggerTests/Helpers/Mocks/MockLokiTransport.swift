import Foundation
@testable import LokiLogger

/// Mock transport for testing LogBuffer behavior.
final class MockLokiTransport: @unchecked Sendable {

    // MARK: - Properties

    /// Number of times send was called.
    private(set) var sendCallCount: Int = 0

    /// Captured entries from all send calls.
    private(set) var capturedEntries: [[LogEntry]] = []

    /// Error to throw on send (if set).
    var shouldFail: Bool = false

    /// Number of failures before succeeding (for retry testing).
    var failuresBeforeSuccess: Int = 0
    private var failureCount: Int = 0

    // MARK: - Methods

    func send(_ entries: [LogEntry]) async throws {
        sendCallCount += 1
        capturedEntries.append(entries)

        if shouldFail || failureCount < failuresBeforeSuccess {
            failureCount += 1
            throw LokiError.networkError(URLError(.notConnectedToInternet))
        }
    }
}
