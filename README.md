# LokiLogger

Swift 6 library for structured logging to [Grafana Loki](https://grafana.com/oss/loki/). Features automatic batching, retry logic, and background flush support.

## Requirements

- Swift 6.0+
- iOS 17.0+ / macOS 14.0+ / tvOS 17.0+ / watchOS 10.0+

## Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/macward/loki-logger-swift.git", from: "1.0.0")
]
```

Or in Xcode: File → Add Package Dependencies → paste the repository URL.

## Quick Start

```swift
import LokiLogger

// Configure once at app startup
LokiLogger.configure(
    endpoint: URL(string: "https://loki.example.com/loki/api/v1/push")!,
    app: "MyApp",
    environment: "production"
)

// Log messages
LokiLogger.info("User logged in", metadata: ["userId": "123"])
LokiLogger.error("Payment failed", metadata: ["orderId": "456", "reason": "insufficient_funds"])
```

## Configuration

### Basic Configuration

```swift
LokiLogger.configure(
    endpoint: URL(string: "https://loki.example.com/loki/api/v1/push")!,
    app: "MyApp",
    environment: "production"
)
```

### Full Configuration

```swift
LokiLogger.configure(
    endpoint: URL(string: "https://loki.example.com/loki/api/v1/push")!,
    app: "MyApp",
    environment: "production",
    batchSize: 20,              // Entries per batch (default: 20)
    flushInterval: 10,          // Seconds between auto-flush (default: 10)
    maxRetries: 3,              // Retry attempts for failures (default: 3)
    maxBufferSize: 500,         // Max entries before dropping oldest (default: 500)
    extraLabels: [              // Custom labels for all entries
        "version": "1.2.0",
        "region": "us-east-1"
    ],
    deviceInfo: DeviceInfo(),   // Automatic device labels (default: enabled)
    session: URLSession.shared  // Custom URLSession (default: .shared)
)
```

### Disabling Device Info

To disable automatic device labels:

```swift
LokiLogger.configure(
    endpoint: lokiURL,
    app: "MyApp",
    environment: "production",
    deviceInfo: nil
)
```

## Logging

### Log Levels

```swift
LokiLogger.debug("Verbose debugging information")
LokiLogger.info("General informational message")
LokiLogger.warn("Warning condition")
LokiLogger.error("Error requiring attention")
```

### Metadata

Add structured context to any log:

```swift
LokiLogger.info("Order placed", metadata: [
    "orderId": "ORD-123",
    "amount": "99.99",
    "currency": "USD"
])
```

Metadata appears in Loki as: `Order placed [amount=99.99 currency=USD orderId=ORD-123]`

### Manual Flush

Force send all buffered logs:

```swift
await LokiLogger.flush()
```

### Graceful Shutdown

Stop the logger and flush remaining entries:

```swift
await LokiLogger.stop()
```

## Automatic Behaviors

### Batching

Logs are batched for efficiency. A batch is sent when:
- Batch size is reached (default: 20 entries)
- Flush interval elapses (default: 10 seconds)
- App enters background (iOS/macOS)
- `flush()` is called manually

### Retry Logic

Failed batches are retried up to `maxRetries` times (default: 3). After max retries, entries are dropped to prevent memory growth.

### Buffer Overflow

When the buffer exceeds `maxBufferSize` (default: 500), oldest entries are dropped to make room for new ones.

### Background Flush

On iOS/tvOS, logs are automatically flushed when the app resigns active state. On macOS, the same happens when the application becomes inactive.

## Loki Labels

Each log entry includes these labels:

| Label | Source | Example |
|-------|--------|---------|
| `app` | Configuration | `"MyApp"` |
| `environment` | Configuration | `"production"` |
| `level` | Log level | `"info"`, `"error"` |
| `device_model` | Automatic | `"iPhone15,2"` |
| `os_version` | Automatic | `"17.2.0"` |
| Custom | `extraLabels` | Any key-value |

Query in Grafana:

```logql
{app="MyApp", environment="production", level="error"}
```

## Testing

### Injecting Dependencies

For unit tests, use the injectable initializer:

```swift
let mockSession = MockURLSession()
let config = LokiConfiguration(
    endpoint: URL(string: "https://test.local")!,
    app: "TestApp",
    environment: "test",
    deviceInfo: MockDeviceInfo()
)
let transport = LokiTransport(configuration: config, session: mockSession)
let buffer = LogBuffer(transport: transport, configuration: config)
let logger = LokiLogger(buffer: buffer, configuration: config)

logger.log(level: .info, message: "Test message")
```

### Mock URLSession

Implement `URLSessionProtocol`:

```swift
final class MockURLSession: URLSessionProtocol, @unchecked Sendable {
    var statusCode: Int = 200
    var capturedRequests: [URLRequest] = []

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        capturedRequests.append(request)
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        return (Data(), response)
    }
}
```

### Mock DeviceInfo

Implement `DeviceInfoProviding`:

```swift
struct MockDeviceInfo: DeviceInfoProviding, Sendable {
    let deviceModel: String = "TestDevice"
    let osVersion: String = "1.0.0"
}
```

## Architecture

```
┌─────────────┐     ┌───────────┐     ┌───────────────┐     ┌──────┐
│ LokiLogger  │────▶│ LogBuffer │────▶│ LokiTransport │────▶│ Loki │
│  (static)   │     │  (actor)  │     │  (stateless)  │     │ API  │
└─────────────┘     └───────────┘     └───────────────┘     └──────┘
                          │
                          ▼
                    ┌───────────┐
                    │  Retry    │
                    │  Queue    │
                    └───────────┘
```

### Components

| Component | Responsibility |
|-----------|----------------|
| `LokiLogger` | Public API, static convenience methods |
| `LogBuffer` | Actor for thread-safe batching, timing, retries |
| `LokiTransport` | Stateless HTTP client, payload formatting |
| `LokiConfiguration` | Immutable settings container |
| `LogEntry` | Single log with timestamp, level, message, metadata |
| `DeviceInfo` | Platform-agnostic device information |

### Loki Payload Format

```json
{
  "streams": [
    {
      "stream": {
        "app": "MyApp",
        "environment": "production",
        "level": "info",
        "device_model": "iPhone15,2",
        "os_version": "17.2.0"
      },
      "values": [
        ["1708360000000000000", "User logged in [userId=123]"]
      ]
    }
  ]
}
```

## Error Handling

Errors are defined in `LokiError`:

```swift
public enum LokiError: Error, Sendable {
    case notConfigured              // Logger not configured
    case invalidResponse(statusCode: Int)  // Non-2xx response
    case networkError(Error)        // Connection failure
    case encodingError(Error)       // JSON encoding failure
}
```

Errors are handled internally with retry logic. Failed logs are dropped after max retries to prevent memory growth.

## Thread Safety

- `LogBuffer` is a Swift actor, ensuring thread-safe access
- `LokiTransport` is stateless and `Sendable`
- All public types conform to `Sendable`
- Static API is safe to call from any thread/task

## License

MIT License
