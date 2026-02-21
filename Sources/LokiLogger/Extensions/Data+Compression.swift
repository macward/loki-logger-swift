import Foundation
import zlib

extension Data {

    // MARK: - Gzip Compression

    /// Compresses data using gzip compression.
    ///
    /// Uses zlib with gzip header/trailer for compatibility with
    /// standard gzip decompression (Content-Encoding: gzip).
    ///
    /// - Returns: Gzip-compressed data, or nil if compression fails.
    internal func gzipCompressed() throws -> Data {
        guard !isEmpty else {
            throw CompressionError.emptyData
        }

        var stream: z_stream = z_stream()
        var status: Int32

        // Initialize deflate with gzip wrapper (windowBits + 16)
        status = deflateInit2_(
            &stream,
            Z_DEFAULT_COMPRESSION,
            Z_DEFLATED,
            MAX_WBITS + 16, // +16 for gzip header
            MAX_MEM_LEVEL,
            Z_DEFAULT_STRATEGY,
            ZLIB_VERSION,
            Int32(MemoryLayout<z_stream>.size)
        )

        guard status == Z_OK else {
            throw CompressionError.initializationFailed
        }

        let outputBufferSize: Int = count + 100
        var compressedData: Data = Data(count: outputBufferSize)

        defer {
            deflateEnd(&stream)
        }

        let compressedLength: Int = try withUnsafeBytes { sourcePointer in
            try compressedData.withUnsafeMutableBytes { destinationPointer in
                stream.next_in = UnsafeMutablePointer<Bytef>(
                    mutating: sourcePointer.bindMemory(to: Bytef.self).baseAddress
                )
                stream.avail_in = uInt(count)
                stream.next_out = destinationPointer.bindMemory(to: Bytef.self).baseAddress
                stream.avail_out = uInt(outputBufferSize)

                status = deflate(&stream, Z_FINISH)

                guard status == Z_STREAM_END else {
                    throw CompressionError.compressionFailed
                }

                return Int(stream.total_out)
            }
        }

        return compressedData.prefix(compressedLength)
    }
}

// MARK: - Compression Error

/// Errors that can occur during compression operations.
internal enum CompressionError: Error, Sendable {
    /// Input data was empty.
    case emptyData

    /// Failed to initialize compression.
    case initializationFailed

    /// Compression operation failed.
    case compressionFailed
}
