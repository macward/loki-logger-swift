import Foundation
import Testing
@testable import LokiLogger

@Suite("LokiTransport Tests")
struct LokiTransportTests {

    // MARK: - Properties

    private let endpoint: URL = URL(string: "https://loki.example.com/loki/api/v1/push")!

    // MARK: - Tests

    @Test("Send succeeds with HTTP 200")
    func sendSucceedsWithHTTP200() async throws {
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

        let entry: LogEntry = LogEntry(level: .info, message: "Test message")

        try await transport.send([entry])

        #expect(session.capturedRequests.count == 1)
        #expect(session.capturedRequests.first?.httpMethod == "POST")
    }

    @Test("Send fails with HTTP 500 throws invalidResponse")
    func sendFailsWithHTTP500() async throws {
        let session: MockURLSession = MockURLSession()
        session.statusCode = 500

        let configuration: LokiConfiguration = LokiConfiguration(
            endpoint: endpoint,
            app: "TestApp",
            environment: "test"
        )

        let transport: LokiTransport = LokiTransport(
            configuration: configuration,
            session: session
        )

        let entry: LogEntry = LogEntry(level: .error, message: "Error message")

        await #expect(throws: LokiError.self) {
            try await transport.send([entry])
        }
    }

    @Test("Logs are grouped by level in streams")
    func logsGroupedByLevel() async throws {
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

        let entries: [LogEntry] = [
            LogEntry(level: .info, message: "Info 1"),
            LogEntry(level: .error, message: "Error 1"),
            LogEntry(level: .info, message: "Info 2")
        ]

        try await transport.send(entries)

        #expect(session.capturedRequests.count == 1)

        let request: URLRequest = session.capturedRequests.first!
        let body: Data = request.httpBody!
        let json: [String: Any] = try JSONSerialization.jsonObject(with: body) as! [String: Any]
        let streams: [[String: Any]] = json["streams"] as! [[String: Any]]

        // Should have 2 streams (info and error)
        #expect(streams.count == 2)
    }

    @Test("Metadata is appended to message")
    func metadataAppendedToMessage() async throws {
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

        let entry: LogEntry = LogEntry(
            level: .info,
            message: "Test message",
            metadata: ["userId": "123", "action": "login"]
        )

        try await transport.send([entry])

        let request: URLRequest = session.capturedRequests.first!
        let body: Data = request.httpBody!
        let json: [String: Any] = try JSONSerialization.jsonObject(with: body) as! [String: Any]
        let streams: [[String: Any]] = json["streams"] as! [[String: Any]]
        let values: [[String]] = streams.first!["values"] as! [[String]]
        let message: String = values.first![1]

        #expect(message.contains("Test message"))
        #expect(message.contains("userId=123"))
        #expect(message.contains("action=login"))
    }

    @Test("Network error throws networkError")
    func networkErrorThrows() async throws {
        let session: MockURLSession = MockURLSession()
        session.error = URLError(.notConnectedToInternet)

        let configuration: LokiConfiguration = LokiConfiguration(
            endpoint: endpoint,
            app: "TestApp",
            environment: "test"
        )

        let transport: LokiTransport = LokiTransport(
            configuration: configuration,
            session: session
        )

        let entry: LogEntry = LogEntry(level: .info, message: "Test")

        await #expect(throws: LokiError.self) {
            try await transport.send([entry])
        }
    }

    @Test("Empty entries array does nothing")
    func emptyEntriesDoesNothing() async throws {
        let session: MockURLSession = MockURLSession()

        let configuration: LokiConfiguration = LokiConfiguration(
            endpoint: endpoint,
            app: "TestApp",
            environment: "test"
        )

        let transport: LokiTransport = LokiTransport(
            configuration: configuration,
            session: session
        )

        try await transport.send([])

        #expect(session.capturedRequests.isEmpty)
    }

    @Test("Device info is included in stream labels")
    func deviceInfoIncludedInLabels() async throws {
        let session: MockURLSession = MockURLSession()
        session.statusCode = 200

        let mockDeviceInfo: MockDeviceInfo = MockDeviceInfo(
            deviceModel: "iPhone15,2",
            osVersion: "17.2.0"
        )

        let configuration: LokiConfiguration = LokiConfiguration(
            endpoint: endpoint,
            app: "TestApp",
            environment: "test",
            deviceInfo: mockDeviceInfo
        )

        let transport: LokiTransport = LokiTransport(
            configuration: configuration,
            session: session
        )

        let entry: LogEntry = LogEntry(level: .info, message: "Test")

        try await transport.send([entry])

        let request: URLRequest = session.capturedRequests.first!
        let body: Data = request.httpBody!
        let json: [String: Any] = try JSONSerialization.jsonObject(with: body) as! [String: Any]
        let streams: [[String: Any]] = json["streams"] as! [[String: Any]]
        let stream: [String: String] = streams.first!["stream"] as! [String: String]

        #expect(stream["device_model"] == "iPhone15,2")
        #expect(stream["os_version"] == "17.2.0")
    }

    @Test("Device info can be disabled")
    func deviceInfoCanBeDisabled() async throws {
        let session: MockURLSession = MockURLSession()
        session.statusCode = 200

        let configuration: LokiConfiguration = LokiConfiguration(
            endpoint: endpoint,
            app: "TestApp",
            environment: "test",
            deviceInfo: nil
        )

        let transport: LokiTransport = LokiTransport(
            configuration: configuration,
            session: session
        )

        let entry: LogEntry = LogEntry(level: .info, message: "Test")

        try await transport.send([entry])

        let request: URLRequest = session.capturedRequests.first!
        let body: Data = request.httpBody!
        let json: [String: Any] = try JSONSerialization.jsonObject(with: body) as! [String: Any]
        let streams: [[String: Any]] = json["streams"] as! [[String: Any]]
        let stream: [String: String] = streams.first!["stream"] as! [String: String]

        #expect(stream["device_model"] == nil)
        #expect(stream["os_version"] == nil)
    }
}
