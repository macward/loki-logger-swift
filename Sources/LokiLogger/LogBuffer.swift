@preconcurrency import Foundation

#if canImport(UIKit)
@preconcurrency import UIKit
#endif

#if canImport(AppKit)
@preconcurrency import AppKit
#endif

/// Thread-safe log buffer using Swift actor.
///
/// Handles batching, automatic flushing, and retry logic with an
/// in-memory queue. Flushes automatically when batch size is reached,
/// on timer intervals, or when the app enters background.
public actor LogBuffer {

    // MARK: - Properties

    private var buffer: [LogEntry] = []
    private var retryQueue: [(entries: [LogEntry], attempts: Int)] = []
    private let transport: LokiTransport
    private let configuration: LokiConfiguration
    private var flushTask: Task<Void, Never>?
    private var isRunning: Bool = false
    private var notificationObserver: (any NSObjectProtocol)?

    // MARK: - Lifecycle

    /// Creates a new log buffer with the given transport and configuration.
    ///
    /// - Parameters:
    ///   - transport: Transport for sending log batches.
    ///   - configuration: Configuration for buffer behavior.
    public init(transport: LokiTransport, configuration: LokiConfiguration) {
        self.transport = transport
        self.configuration = configuration
    }

    // MARK: - Public Methods

    /// Starts the buffer's automatic flush timer.
    public func start() {
        guard !isRunning else { return }
        isRunning = true
        startFlushTimer()
        observeBackgroundNotifications()
    }

    /// Stops the buffer and flushes any remaining entries.
    public func stop() async {
        isRunning = false
        flushTask?.cancel()
        flushTask = nil
        removeBackgroundObserver()
        await flush()
    }

    /// Adds a log entry to the buffer.
    ///
    /// Triggers a flush if the batch size is reached or buffer exceeds max size.
    ///
    /// - Parameter entry: Log entry to buffer.
    public func append(_ entry: LogEntry) async {
        // Drop oldest if buffer exceeds max size
        if buffer.count >= configuration.maxBufferSize {
            buffer.removeFirst()
        }

        buffer.append(entry)

        if buffer.count >= configuration.batchSize {
            await flush()
        }
    }

    /// Flushes all buffered entries immediately.
    public func flush() async {
        guard !buffer.isEmpty || !retryQueue.isEmpty else { return }

        // Move current buffer to send batch
        let entriesToSend: [LogEntry] = buffer
        buffer = []

        // Try sending current batch
        if !entriesToSend.isEmpty {
            await sendBatch(entriesToSend, attempts: 0)
        }

        // Process retry queue
        await processRetryQueue()
    }

    // MARK: - Private Methods

    private func startFlushTimer() {
        let flushIntervalNanoseconds: UInt64 = UInt64(configuration.flushInterval * 1_000_000_000)
        flushTask = Task { [weak self] in
            while let self = self, await self.isRunning {
                try? await Task.sleep(nanoseconds: flushIntervalNanoseconds)
                if await self.isRunning {
                    await self.flush()
                }
            }
        }
    }

    private func observeBackgroundNotifications() {
        #if os(iOS) || os(tvOS)
        Task { @MainActor [weak self] in
            let observer: any NSObjectProtocol = NotificationCenter.default.addObserver(
                forName: UIApplication.willResignActiveNotification,
                object: nil,
                queue: nil
            ) { [weak self] _ in
                Task {
                    await self?.flush()
                }
            }
            await self?.setNotificationObserver(observer)
        }
        #elseif os(macOS)
        Task { @MainActor [weak self] in
            let observer: any NSObjectProtocol = NotificationCenter.default.addObserver(
                forName: NSApplication.willResignActiveNotification,
                object: nil,
                queue: nil
            ) { [weak self] _ in
                Task {
                    await self?.flush()
                }
            }
            await self?.setNotificationObserver(observer)
        }
        #endif
    }

    private func setNotificationObserver(_ observer: any NSObjectProtocol) {
        notificationObserver = observer
    }

    private func removeBackgroundObserver() {
        if let observer = notificationObserver {
            NotificationCenter.default.removeObserver(observer)
            notificationObserver = nil
        }
    }

    private func sendBatch(_ entries: [LogEntry], attempts: Int) async {
        do {
            try await transport.send(entries)
        } catch {
            let newAttempts: Int = attempts + 1
            if newAttempts < configuration.maxRetries {
                retryQueue.append((entries: entries, attempts: newAttempts))
            }
            // If max retries exceeded, entries are dropped
        }
    }

    private func processRetryQueue() async {
        let retries: [(entries: [LogEntry], attempts: Int)] = retryQueue
        retryQueue = []

        for retry in retries {
            await sendBatch(retry.entries, attempts: retry.attempts)
        }
    }
}
