import Foundation
import Testing
@testable import LokiLogger

@Suite("RetryConfiguration Tests")
struct RetryConfigurationTests {

    // MARK: - Default Values Tests

    @Test("Default configuration has expected values")
    func defaultValues() {
        let configuration: RetryConfiguration = .default

        #expect(configuration.maxRetries == 3)
        #expect(configuration.baseDelay == 1.0)
        #expect(configuration.maxDelay == 30.0)
        #expect(configuration.jitterFactor == 0.1)
    }

    @Test("Custom configuration preserves values")
    func customValues() {
        let configuration: RetryConfiguration = RetryConfiguration(
            maxRetries: 5,
            baseDelay: 2.0,
            maxDelay: 60.0,
            jitterFactor: 0.2
        )

        #expect(configuration.maxRetries == 5)
        #expect(configuration.baseDelay == 2.0)
        #expect(configuration.maxDelay == 60.0)
        #expect(configuration.jitterFactor == 0.2)
    }

    // MARK: - Jitter Clamping Tests

    @Test("Jitter factor is clamped to valid range")
    func jitterFactorClamped() {
        let configNegative: RetryConfiguration = RetryConfiguration(jitterFactor: -0.5)
        let configOverOne: RetryConfiguration = RetryConfiguration(jitterFactor: 1.5)

        #expect(configNegative.jitterFactor == 0.0)
        #expect(configOverOne.jitterFactor == 1.0)
    }

    // MARK: - Delay Calculation Tests

    @Test("Delay for attempt 0 is approximately baseDelay")
    func delayAttemptZero() {
        let configuration: RetryConfiguration = RetryConfiguration(
            baseDelay: 1.0,
            jitterFactor: 0.0 // No jitter for deterministic test
        )

        let delay: TimeInterval = configuration.delay(forAttempt: 0)

        #expect(delay == 1.0)
    }

    @Test("Delay increases exponentially")
    func delayIncreasesExponentially() {
        let configuration: RetryConfiguration = RetryConfiguration(
            baseDelay: 1.0,
            maxDelay: 100.0,
            jitterFactor: 0.0
        )

        let delay0: TimeInterval = configuration.delay(forAttempt: 0) // 1 * 2^0 = 1
        let delay1: TimeInterval = configuration.delay(forAttempt: 1) // 1 * 2^1 = 2
        let delay2: TimeInterval = configuration.delay(forAttempt: 2) // 1 * 2^2 = 4
        let delay3: TimeInterval = configuration.delay(forAttempt: 3) // 1 * 2^3 = 8

        #expect(delay0 == 1.0)
        #expect(delay1 == 2.0)
        #expect(delay2 == 4.0)
        #expect(delay3 == 8.0)
    }

    @Test("Delay is capped at maxDelay")
    func delayCappedAtMax() {
        let configuration: RetryConfiguration = RetryConfiguration(
            baseDelay: 1.0,
            maxDelay: 5.0,
            jitterFactor: 0.0
        )

        let delay5: TimeInterval = configuration.delay(forAttempt: 5) // Would be 32, capped at 5

        #expect(delay5 == 5.0)
    }

    @Test("Jitter adds randomness within bounds")
    func jitterAddsRandomness() {
        let configuration: RetryConfiguration = RetryConfiguration(
            baseDelay: 10.0,
            maxDelay: 100.0,
            jitterFactor: 0.1
        )

        // Run multiple times to verify jitter is working
        var delays: Set<TimeInterval> = []
        for _ in 0..<10 {
            delays.insert(configuration.delay(forAttempt: 0))
        }

        // With jitter, we should get some variation
        // All delays should be within 10% of base (9.0 to 11.0)
        for delay in delays {
            #expect(delay >= 9.0)
            #expect(delay <= 11.0)
        }
    }

    // MARK: - Equatable Tests

    @Test("Configurations with same values are equal")
    func equalConfigurations() {
        let config1: RetryConfiguration = RetryConfiguration(
            maxRetries: 3,
            baseDelay: 1.0,
            maxDelay: 30.0,
            jitterFactor: 0.1
        )
        let config2: RetryConfiguration = RetryConfiguration(
            maxRetries: 3,
            baseDelay: 1.0,
            maxDelay: 30.0,
            jitterFactor: 0.1
        )

        #expect(config1 == config2)
    }

    @Test("Configurations with different values are not equal")
    func unequalConfigurations() {
        let config1: RetryConfiguration = RetryConfiguration(maxRetries: 3)
        let config2: RetryConfiguration = RetryConfiguration(maxRetries: 5)

        #expect(config1 != config2)
    }
}
