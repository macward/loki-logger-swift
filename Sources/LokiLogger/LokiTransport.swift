import Foundation

/// Protocol abstracting URLSession for testability.
public protocol URLSessionProtocol: Sendable {
    /// Performs a data task and returns the response.
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionProtocol {}

/// Stateless HTTP client for sending log batches to Loki.
///
/// Groups logs by stream labels and formats payloads according to
/// the Loki push API JSON protocol.
public struct LokiTransport: Sendable {

    // MARK: - Properties

    private let session: any URLSessionProtocol
    private let configuration: LokiConfiguration
    private let encoder: JSONEncoder

    // MARK: - Lifecycle

    /// Creates a new transport with the given configuration.
    ///
    /// - Parameters:
    ///   - configuration: Loki configuration including endpoint and labels.
    ///   - session: URLSession for network requests (default: .shared).
    public init(
        configuration: LokiConfiguration,
        session: any URLSessionProtocol = URLSession.shared
    ) {
        self.configuration = configuration
        self.session = session
        self.encoder = JSONEncoder()
    }

    // MARK: - Public Methods

    /// Sends a batch of log entries to Loki.
    ///
    /// Groups entries by their stream labels (app, environment, level)
    /// and formats them according to the Loki push API protocol.
    ///
    /// - Parameter entries: Log entries to send.
    /// - Throws: `LokiError` if encoding or network request fails.
    public func send(_ entries: [LogEntry]) async throws {
        guard !entries.isEmpty else { return }

        let payload: LokiPayload = buildPayload(from: entries)
        let request: URLRequest = try buildRequest(with: payload)

        do {
            let (_, response): (Data, URLResponse) = try await session.data(for: request)

            guard let httpResponse: HTTPURLResponse = response as? HTTPURLResponse else {
                throw LokiError.invalidResponse(statusCode: 0)
            }

            guard (200..<300).contains(httpResponse.statusCode) else {
                throw LokiError.invalidResponse(statusCode: httpResponse.statusCode)
            }
        } catch let error as LokiError {
            throw error
        } catch {
            throw LokiError.networkError(error)
        }
    }

    // MARK: - Private Methods

    private func buildPayload(from entries: [LogEntry]) -> LokiPayload {
        var streamMap: [String: [LokiValue]] = [:]

        for entry in entries {
            let streamKey: String = streamKey(for: entry)
            let value: LokiValue = LokiValue(
                timestamp: String(entry.timestamp),
                line: formatLine(for: entry)
            )

            streamMap[streamKey, default: []].append(value)
        }

        let streams: [LokiStream] = streamMap.map { key, values in
            LokiStream(
                stream: streamLabels(from: key),
                values: values.map { [$0.timestamp, $0.line] }
            )
        }

        return LokiPayload(streams: streams)
    }

    private func streamKey(for entry: LogEntry) -> String {
        "\(configuration.app)|\(configuration.environment)|\(entry.level.rawValue)"
    }

    private func streamLabels(from key: String) -> [String: String] {
        let parts: [String] = key.split(separator: "|").map { String($0) }
        var labels: [String: String] = [
            "app": parts[0],
            "environment": parts[1],
            "level": parts[2]
        ]

        if let deviceInfo = configuration.deviceInfo {
            labels["device_model"] = deviceInfo.deviceModel
            labels["os_version"] = deviceInfo.osVersion
        }

        for (key, value) in configuration.extraLabels {
            labels[key] = value
        }

        return labels
    }

    private func formatLine(for entry: LogEntry) -> String {
        if entry.metadata.isEmpty {
            return entry.message
        }

        let metadataString: String = entry.metadata
            .sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: " ")

        return "\(entry.message) [\(metadataString)]"
    }

    private func buildRequest(with payload: LokiPayload) throws -> URLRequest {
        var data: Data
        do {
            data = try encoder.encode(payload)
        } catch {
            throw LokiError.encodingError(error)
        }

        var request: URLRequest = URLRequest(url: configuration.endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Apply compression if enabled
        if configuration.compressionEnabled {
            do {
                data = try data.gzipCompressed()
                request.setValue("gzip", forHTTPHeaderField: "Content-Encoding")
            } catch {
                throw LokiError.compressionError(error)
            }
        }

        request.httpBody = data

        // Apply authentication headers
        let authHeaders: [String: String] = configuration.authentication.headers()
        for (key, value) in authHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }

        return request
    }
}

// MARK: - Loki Protocol Types

private struct LokiPayload: Encodable {
    let streams: [LokiStream]
}

private struct LokiStream: Encodable {
    let stream: [String: String]
    let values: [[String]]
}

private struct LokiValue {
    let timestamp: String
    let line: String
}
