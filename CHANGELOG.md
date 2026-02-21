# Changelog

All notable changes to LokiLogger will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

#### LogLevel `critical`
- Added `critical` case to `LogLevel` enum for highest severity logs
- Added `LokiLogger.critical(_:metadata:)` static convenience method
- New test file: `LogLevelTests.swift`

#### Authentication Support
- New `LokiAuthentication` enum with support for:
  - `.none` - No authentication
  - `.basic(username:password:)` - HTTP Basic Auth
  - `.bearer(token:)` - Bearer token (OAuth, JWT, API keys)
  - `.custom(headers:)` - Custom header dictionary
- Added `authentication` parameter to `LokiConfiguration`
- Added `authentication` parameter to `LokiLogger.configure()`
- Authentication headers are automatically applied to all requests
- New file: `Sources/LokiLogger/LokiAuthentication.swift`
- New test file: `LokiAuthenticationTests.swift`

#### Exponential Backoff Retry
- New `RetryConfiguration` struct with configurable:
  - `maxRetries` - Maximum retry attempts (default: 3)
  - `baseDelay` - Initial delay in seconds (default: 1.0)
  - `maxDelay` - Maximum delay cap in seconds (default: 30.0)
  - `jitterFactor` - Randomization factor 0.0-1.0 (default: 0.1)
- Added `retryConfiguration` parameter to `LokiConfiguration`
- Retry delays now use exponential backoff formula: `baseDelay * 2^attempt`
- Jitter prevents thundering herd problems on retries
- New file: `Sources/LokiLogger/RetryConfiguration.swift`
- New test file: `RetryConfigurationTests.swift`

#### Gzip Compression
- Added `compressionEnabled` parameter to `LokiConfiguration` (default: `false`)
- When enabled, request bodies are compressed with gzip
- Adds `Content-Encoding: gzip` header automatically
- Added `compressionError` case to `LokiError`
- New file: `Sources/LokiLogger/Extensions/Data+Compression.swift`
- New test file: `CompressionTests.swift`

#### Offline Persistence
- New `LogPersisting` protocol for custom persistence implementations
- New `FileLogPersistence` actor for file-based JSON storage
- Added `persistence` parameter to `LokiConfiguration` (default: `nil`)
- Added `persistenceError` case to `LokiError`
- `LogEntry` now conforms to `Codable` and `Equatable`
- `LogBuffer.start()` recovers persisted entries from previous sessions
- `LogBuffer.stop()` persists remaining unsent entries
- Failed retries (after max attempts) are persisted for later recovery
- New files:
  - `Sources/LokiLogger/LogPersisting.swift`
  - `Sources/LokiLogger/FileLogPersistence.swift`
- New test files:
  - `LogPersistenceTests.swift`
  - `Helpers/Mocks/MockLogPersistence.swift`

### Changed

- `LogBuffer.start()` is now `async` to support persistence recovery
- `LokiConfiguration.maxRetries` is deprecated in favor of `retryConfiguration.maxRetries`
- `LogLevel` now conforms to `Codable`
- `LogEntry` now conforms to `Codable` and `Equatable`

### Backward Compatibility

All changes are backward compatible:
- Existing code works without modifications
- New parameters have sensible defaults
- `maxRetries` parameter still works (creates `RetryConfiguration` internally)
- Compression and persistence are opt-in features

## [1.0.0] - Initial Release

### Added

- Core logging functionality with `LokiLogger` facade
- Log levels: `debug`, `info`, `warn`, `error`
- `LogBuffer` actor for thread-safe batching
- `LokiTransport` for HTTP communication with Loki
- Configurable batch size and flush intervals
- Automatic retry on network failures
- Device info labels (model, OS version)
- Custom labels support
- Background flush on app resign active
- Dependency injection support for testing
