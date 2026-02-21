import Foundation
import Testing
@testable import LokiLogger

@Suite("LokiLogger Tests")
struct LokiLoggerTests {

    // MARK: - Properties

    private let endpoint: URL = URL(string: "https://loki.example.com/loki/api/v1/push")!

    // MARK: - Tests

    @Test("Instance log method adds entry to buffer")
    func instanceLogAddsToBuffer() async throws {
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

        let logger: LokiLogger = LokiLogger(
            buffer: buffer,
            configuration: configuration
        )

        logger.log(level: .info, message: "Test message", metadata: ["key": "value"])

        // Give time for the Task to execute
        try await Task.sleep(nanoseconds: 100_000_000)

        await buffer.flush()

        #expect(session.capturedRequests.count == 1)

        let body: Data = session.capturedRequests.first!.httpBody!
        let json: [String: Any] = try JSONSerialization.jsonObject(with: body) as! [String: Any]
        let streams: [[String: Any]] = json["streams"] as! [[String: Any]]
        let values: [[String]] = streams.first!["values"] as! [[String]]
        let message: String = values.first![1]

        #expect(message.contains("Test message"))
        #expect(message.contains("key=value"))
    }

    @Test("Instance log with debug level")
    func instanceLogDebugLevel() async throws {
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

        let logger: LokiLogger = LokiLogger(
            buffer: buffer,
            configuration: configuration
        )

        logger.log(level: .debug, message: "Debug message")

        try await Task.sleep(nanoseconds: 100_000_000)
        await buffer.flush()

        #expect(session.capturedRequests.count == 1)

        let body: Data = session.capturedRequests.first!.httpBody!
        let json: [String: Any] = try JSONSerialization.jsonObject(with: body) as! [String: Any]
        let streams: [[String: Any]] = json["streams"] as! [[String: Any]]
        let stream: [String: String] = streams.first!["stream"] as! [String: String]

        #expect(stream["level"] == "debug")
    }

    @Test("Instance log with warn level")
    func instanceLogWarnLevel() async throws {
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

        let logger: LokiLogger = LokiLogger(
            buffer: buffer,
            configuration: configuration
        )

        logger.log(level: .warn, message: "Warning message")

        try await Task.sleep(nanoseconds: 100_000_000)
        await buffer.flush()

        #expect(session.capturedRequests.count == 1)

        let body: Data = session.capturedRequests.first!.httpBody!
        let json: [String: Any] = try JSONSerialization.jsonObject(with: body) as! [String: Any]
        let streams: [[String: Any]] = json["streams"] as! [[String: Any]]
        let stream: [String: String] = streams.first!["stream"] as! [String: String]

        #expect(stream["level"] == "warn")
    }

    @Test("Instance log with error level")
    func instanceLogErrorLevel() async throws {
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

        let logger: LokiLogger = LokiLogger(
            buffer: buffer,
            configuration: configuration
        )

        logger.log(level: .error, message: "Error message")

        try await Task.sleep(nanoseconds: 100_000_000)
        await buffer.flush()

        #expect(session.capturedRequests.count == 1)

        let body: Data = session.capturedRequests.first!.httpBody!
        let json: [String: Any] = try JSONSerialization.jsonObject(with: body) as! [String: Any]
        let streams: [[String: Any]] = json["streams"] as! [[String: Any]]
        let stream: [String: String] = streams.first!["stream"] as! [String: String]

        #expect(stream["level"] == "error")
    }

    @Test("Instance log with critical level")
    func instanceLogCriticalLevel() async throws {
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

        let logger: LokiLogger = LokiLogger(
            buffer: buffer,
            configuration: configuration
        )

        logger.log(level: .critical, message: "Critical message")

        try await Task.sleep(nanoseconds: 100_000_000)
        await buffer.flush()

        #expect(session.capturedRequests.count == 1)

        let body: Data = session.capturedRequests.first!.httpBody!
        let json: [String: Any] = try JSONSerialization.jsonObject(with: body) as! [String: Any]
        let streams: [[String: Any]] = json["streams"] as! [[String: Any]]
        let stream: [String: String] = streams.first!["stream"] as! [String: String]

        #expect(stream["level"] == "critical")
    }

    @Test("Multiple logs are batched together")
    func multipleLogsBatched() async throws {
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

        let logger: LokiLogger = LokiLogger(
            buffer: buffer,
            configuration: configuration
        )

        logger.log(level: .info, message: "Message 1")
        logger.log(level: .info, message: "Message 2")
        logger.log(level: .info, message: "Message 3")

        try await Task.sleep(nanoseconds: 100_000_000)
        await buffer.flush()

        #expect(session.capturedRequests.count == 1)

        let body: Data = session.capturedRequests.first!.httpBody!
        let json: [String: Any] = try JSONSerialization.jsonObject(with: body) as! [String: Any]
        let streams: [[String: Any]] = json["streams"] as! [[String: Any]]
        let values: [[String]] = streams.first!["values"] as! [[String]]

        #expect(values.count == 3)
    }

    @Test("Configuration sets correct labels")
    func configurationSetsLabels() async throws {
        let session: MockURLSession = MockURLSession()
        session.statusCode = 200

        let configuration: LokiConfiguration = LokiConfiguration(
            endpoint: endpoint,
            app: "MyApp",
            environment: "production",
            batchSize: 100,
            flushInterval: 60,
            extraLabels: ["version": "1.0.0"]
        )

        let transport: LokiTransport = LokiTransport(
            configuration: configuration,
            session: session
        )

        let buffer: LogBuffer = LogBuffer(
            transport: transport,
            configuration: configuration
        )

        let logger: LokiLogger = LokiLogger(
            buffer: buffer,
            configuration: configuration
        )

        logger.log(level: .info, message: "Test")

        try await Task.sleep(nanoseconds: 100_000_000)
        await buffer.flush()

        let body: Data = session.capturedRequests.first!.httpBody!
        let json: [String: Any] = try JSONSerialization.jsonObject(with: body) as! [String: Any]
        let streams: [[String: Any]] = json["streams"] as! [[String: Any]]
        let stream: [String: String] = streams.first!["stream"] as! [String: String]

        #expect(stream["app"] == "MyApp")
        #expect(stream["environment"] == "production")
        #expect(stream["version"] == "1.0.0")
    }
}
