import Foundation
import Testing
import zlib
@testable import LokiLogger

@Suite("Compression Tests")
struct CompressionTests {

    // MARK: - Data+Compression Tests

    @Test("Gzip compresses data successfully")
    func gzipCompressesData() throws {
        let originalString: String = "Hello, World! This is a test message for compression."
        let originalData: Data = Data(originalString.utf8)

        let compressedData: Data = try originalData.gzipCompressed()

        // Compressed data should exist
        #expect(!compressedData.isEmpty)

        // Compressed data should typically be smaller for repetitive content
        // (though not always for very small inputs)
        #expect(compressedData.count > 0)
    }

    @Test("Gzip creates valid gzip header")
    func gzipCreatesValidHeader() throws {
        let originalData: Data = Data("Test data for compression".utf8)
        let compressedData: Data = try originalData.gzipCompressed()

        // Gzip magic number: 0x1f 0x8b
        #expect(compressedData.count >= 2)
        #expect(compressedData[0] == 0x1f)
        #expect(compressedData[1] == 0x8b)
    }

    @Test("Gzip empty data throws error")
    func gzipEmptyDataThrows() {
        let emptyData: Data = Data()

        #expect(throws: CompressionError.self) {
            _ = try emptyData.gzipCompressed()
        }
    }

    @Test("Gzip compressed data can be decompressed")
    func gzipRoundTrip() throws {
        let originalString: String = "This is test data that should survive a round-trip compression."
        let originalData: Data = Data(originalString.utf8)

        let compressedData: Data = try originalData.gzipCompressed()
        let decompressedData: Data = try gunzipData(compressedData)

        #expect(decompressedData == originalData)
    }

    @Test("Large data compresses efficiently")
    func largeDataCompresses() throws {
        // Create larger data with repetitive content (compresses well)
        let repeatedString: String = String(repeating: "Log entry with some data. ", count: 1000)
        let originalData: Data = Data(repeatedString.utf8)

        let compressedData: Data = try originalData.gzipCompressed()

        // Repetitive data should compress significantly
        #expect(compressedData.count < originalData.count)
        // Should achieve at least 50% compression for repetitive content
        #expect(compressedData.count < originalData.count / 2)
    }

    // MARK: - Transport Integration Tests

    @Test("Transport applies compression when enabled")
    func transportAppliesCompression() async throws {
        let session: MockURLSession = MockURLSession()
        session.statusCode = 200

        let endpoint: URL = URL(string: "https://loki.example.com/loki/api/v1/push")!
        let configuration: LokiConfiguration = LokiConfiguration(
            endpoint: endpoint,
            app: "TestApp",
            environment: "test",
            compressionEnabled: true
        )

        let transport: LokiTransport = LokiTransport(
            configuration: configuration,
            session: session
        )

        let entry: LogEntry = LogEntry(level: .info, message: "Test message")

        try await transport.send([entry])

        let request: URLRequest = session.capturedRequests.first!

        // Should have Content-Encoding: gzip header
        #expect(request.value(forHTTPHeaderField: "Content-Encoding") == "gzip")

        // Body should be gzip-compressed (starts with magic bytes)
        let body: Data = request.httpBody!
        #expect(body[0] == 0x1f)
        #expect(body[1] == 0x8b)
    }

    @Test("Transport does not compress when disabled")
    func transportNoCompressionWhenDisabled() async throws {
        let session: MockURLSession = MockURLSession()
        session.statusCode = 200

        let endpoint: URL = URL(string: "https://loki.example.com/loki/api/v1/push")!
        let configuration: LokiConfiguration = LokiConfiguration(
            endpoint: endpoint,
            app: "TestApp",
            environment: "test",
            compressionEnabled: false
        )

        let transport: LokiTransport = LokiTransport(
            configuration: configuration,
            session: session
        )

        let entry: LogEntry = LogEntry(level: .info, message: "Test message")

        try await transport.send([entry])

        let request: URLRequest = session.capturedRequests.first!

        // Should not have Content-Encoding header
        #expect(request.value(forHTTPHeaderField: "Content-Encoding") == nil)

        // Body should be plain JSON (starts with '{')
        let body: Data = request.httpBody!
        let bodyString: String = String(data: body, encoding: .utf8)!
        #expect(bodyString.hasPrefix("{"))
    }

    // MARK: - Helper Methods

    /// Decompresses gzip data using zlib for test verification.
    private func gunzipData(_ data: Data) throws -> Data {
        var stream: z_stream = z_stream()

        // Initialize inflate with gzip detection (windowBits + 32)
        let initStatus: Int32 = inflateInit2_(
            &stream,
            MAX_WBITS + 32,
            ZLIB_VERSION,
            Int32(MemoryLayout<z_stream>.size)
        )

        guard initStatus == Z_OK else {
            throw NSError(domain: "TestDecompression", code: 1, userInfo: nil)
        }

        defer {
            inflateEnd(&stream)
        }

        // Estimate output size (at least input size, typically larger)
        let outputBufferSize: Int = data.count * 10
        var outputData: Data = Data(count: outputBufferSize)

        let decompressedLength: Int = try data.withUnsafeBytes { inputPointer in
            try outputData.withUnsafeMutableBytes { outputPointer in
                stream.next_in = UnsafeMutablePointer<Bytef>(
                    mutating: inputPointer.bindMemory(to: Bytef.self).baseAddress
                )
                stream.avail_in = uInt(data.count)
                stream.next_out = outputPointer.bindMemory(to: Bytef.self).baseAddress
                stream.avail_out = uInt(outputBufferSize)

                let inflateStatus: Int32 = inflate(&stream, Z_FINISH)

                guard inflateStatus == Z_STREAM_END else {
                    throw NSError(domain: "TestDecompression", code: 2, userInfo: nil)
                }

                return Int(stream.total_out)
            }
        }

        return outputData.prefix(decompressedLength)
    }
}
