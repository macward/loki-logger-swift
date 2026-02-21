import Foundation
import Testing
@testable import LokiLogger

@Suite("LokiAuthentication Tests")
struct LokiAuthenticationTests {

    // MARK: - None Tests

    @Test("None authentication returns empty headers")
    func noneReturnsEmptyHeaders() {
        let authentication: LokiAuthentication = .none
        let headers: [String: String] = authentication.headers()

        #expect(headers.isEmpty)
    }

    // MARK: - Basic Auth Tests

    @Test("Basic auth returns correct Authorization header")
    func basicAuthReturnsAuthorizationHeader() {
        let authentication: LokiAuthentication = .basic(username: "user", password: "pass")
        let headers: [String: String] = authentication.headers()

        #expect(headers.count == 1)
        #expect(headers["Authorization"] != nil)

        let expectedCredentials: String = "user:pass"
        let expectedBase64: String = Data(expectedCredentials.utf8).base64EncodedString()

        #expect(headers["Authorization"] == "Basic \(expectedBase64)")
    }

    @Test("Basic auth encodes special characters correctly")
    func basicAuthEncodesSpecialCharacters() {
        let authentication: LokiAuthentication = .basic(username: "user@domain.com", password: "p@ss:word!")
        let headers: [String: String] = authentication.headers()

        let expectedCredentials: String = "user@domain.com:p@ss:word!"
        let expectedBase64: String = Data(expectedCredentials.utf8).base64EncodedString()

        #expect(headers["Authorization"] == "Basic \(expectedBase64)")
    }

    // MARK: - Bearer Token Tests

    @Test("Bearer token returns correct Authorization header")
    func bearerTokenReturnsAuthorizationHeader() {
        let token: String = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9"
        let authentication: LokiAuthentication = .bearer(token: token)
        let headers: [String: String] = authentication.headers()

        #expect(headers.count == 1)
        #expect(headers["Authorization"] == "Bearer \(token)")
    }

    // MARK: - Custom Headers Tests

    @Test("Custom headers returns provided headers")
    func customHeadersReturnsProvidedHeaders() {
        let customHeaders: [String: String] = [
            "X-Custom-Auth": "secret-key",
            "X-Tenant-ID": "tenant-123"
        ]
        let authentication: LokiAuthentication = .custom(headers: customHeaders)
        let headers: [String: String] = authentication.headers()

        #expect(headers.count == 2)
        #expect(headers["X-Custom-Auth"] == "secret-key")
        #expect(headers["X-Tenant-ID"] == "tenant-123")
    }

    @Test("Custom headers with empty dictionary returns empty")
    func customHeadersEmptyReturnsEmpty() {
        let authentication: LokiAuthentication = .custom(headers: [:])
        let headers: [String: String] = authentication.headers()

        #expect(headers.isEmpty)
    }
}
