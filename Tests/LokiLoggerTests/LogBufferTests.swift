import Foundation
import Testing
@testable import LokiLogger

@Suite("LogBuffer Tests")
struct LogBufferTests {

    // MARK: - Properties

    private let endpoint: URL = URL(string: "https://loki.example.com/loki/api/v1/push")!

    // MARK: - Tests

    @Test("Flush triggers when batch size reached")
    func flushTriggersAtBatchSize() async throws {
        let session: MockURLSession = MockURLSession()
        session.statusCode = 200

        let configuration: LokiConfiguration = LokiConfiguration(
            endpoint: endpoint,
            app: "TestApp",
            environment: "test",
            batchSize: 3,
            flushInterval: 60 // Long interval so we don't auto-flush
        )

        let transport: LokiTransport = LokiTransport(
            configuration: configuration,
            session: session
        )

        let buffer: LogBuffer = LogBuffer(
            transport: transport,
            configuration: configuration
        )

        // Add entries up to batch size
        await buffer.append(LogEntry(level: .info, message: "Message 1"))
        await buffer.append(LogEntry(level: .info, message: "Message 2"))

        // Should not have flushed yet
        #expect(session.capturedRequests.isEmpty)

        // This should trigger flush
        await buffer.append(LogEntry(level: .info, message: "Message 3"))

        // Should have flushed
        #expect(session.capturedRequests.count == 1)
    }

    @Test("Oldest entries dropped when buffer exceeds capacity")
    func oldestEntriesDropped() async throws {
        let session: MockURLSession = MockURLSession()
        session.statusCode = 200

        let configuration: LokiConfiguration = LokiConfiguration(
            endpoint: endpoint,
            app: "TestApp",
            environment: "test",
            batchSize: 100, // High so we don't auto-flush
            flushInterval: 60,
            maxBufferSize: 3
        )

        let transport: LokiTransport = LokiTransport(
            configuration: configuration,
            session: session
        )

        let buffer: LogBuffer = LogBuffer(
            transport: transport,
            configuration: configuration
        )

        // Add more entries than max buffer size
        await buffer.append(LogEntry(level: .info, message: "Message 1"))
        await buffer.append(LogEntry(level: .info, message: "Message 2"))
        await buffer.append(LogEntry(level: .info, message: "Message 3"))
        await buffer.append(LogEntry(level: .info, message: "Message 4"))

        // Manually flush to verify only last 3 entries remain
        await buffer.flush()

        #expect(session.capturedRequests.count == 1)

        let body: Data = session.capturedRequests.first!.httpBody!
        let json: [String: Any] = try JSONSerialization.jsonObject(with: body) as! [String: Any]
        let streams: [[String: Any]] = json["streams"] as! [[String: Any]]
        let values: [[String]] = streams.first!["values"] as! [[String]]

        // Should only have 3 entries (oldest dropped)
        #expect(values.count == 3)

        // Verify Message 1 was dropped
        let messages: [String] = values.map { $0[1] }
        #expect(!messages.contains { $0.contains("Message 1") })
        #expect(messages.contains { $0.contains("Message 2") })
        #expect(messages.contains { $0.contains("Message 4") })
    }

    @Test("Manual flush sends all buffered entries")
    func manualFlushSendsAll() async throws {
        let session: MockURLSession = MockURLSession()
        session.statusCode = 200

        let configuration: LokiConfiguration = LokiConfiguration(
            endpoint: endpoint,
            app: "TestApp",
            environment: "test",
            batchSize: 100,
            flushInterval: 60
        )

        let transport: LokiTransport = LokiTransport(
            configuration: configuration,
            session: session
        )

        let buffer: LogBuffer = LogBuffer(
            transport: transport,
            configuration: configuration
        )

        await buffer.append(LogEntry(level: .info, message: "Test 1"))
        await buffer.append(LogEntry(level: .debug, message: "Test 2"))

        #expect(session.capturedRequests.isEmpty)

        await buffer.flush()

        #expect(session.capturedRequests.count == 1)
    }

    @Test("Failed batches are added to retry queue")
    func failedBatchesAddedToRetryQueue() async throws {
        let session: MockURLSession = MockURLSession()
        session.statusCode = 500 // Fail

        let configuration: LokiConfiguration = LokiConfiguration(
            endpoint: endpoint,
            app: "TestApp",
            environment: "test",
            batchSize: 100, // High so we control flush manually
            flushInterval: 60,
            maxRetries: 3
        )

        let transport: LokiTransport = LokiTransport(
            configuration: configuration,
            session: session
        )

        let buffer: LogBuffer = LogBuffer(
            transport: transport,
            configuration: configuration
        )

        // Add entry
        await buffer.append(LogEntry(level: .info, message: "Retry test"))

        // Manual flush - should fail and add to retry queue
        await buffer.flush()

        // Should have attempted at least once
        #expect(session.capturedRequests.count >= 1)

        // Change to success for future retries
        session.statusCode = 200

        // Add another entry and flush - this triggers retry queue processing
        await buffer.append(LogEntry(level: .info, message: "New entry"))
        await buffer.flush()

        // Should have more requests now (original retry + new entry)
        #expect(session.capturedRequests.count >= 2)
    }

    @Test("Empty buffer flush does nothing")
    func emptyBufferFlushDoesNothing() async throws {
        let session: MockURLSession = MockURLSession()
        session.statusCode = 200

        let configuration: LokiConfiguration = LokiConfiguration(
            endpoint: endpoint,
            app: "TestApp",
            environment: "test"
        )

        let transport: LokiTransport = LokiTransport(
            configuration: configuration,
            session: session
        )

        let buffer: LogBuffer = LogBuffer(
            transport: transport,
            configuration: configuration
        )

        await buffer.flush()

        #expect(session.capturedRequests.isEmpty)
    }
}
