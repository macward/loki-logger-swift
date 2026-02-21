import Foundation
@testable import LokiLogger

/// Mock URLSession for testing network operations.
final class MockURLSession: URLSessionProtocol, @unchecked Sendable {

    // MARK: - Properties

    /// Response data to return from requests.
    var responseData: Data = Data()

    /// HTTP status code to return.
    var statusCode: Int = 200

    /// Error to throw from requests (if set).
    var error: (any Error)?

    /// Captured requests for verification.
    private(set) var capturedRequests: [URLRequest] = []

    // MARK: - URLSessionProtocol

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        capturedRequests.append(request)

        if let error {
            throw error
        }

        let response: HTTPURLResponse = HTTPURLResponse(
            url: request.url ?? URL(string: "https://localhost")!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!

        return (responseData, response)
    }
}
