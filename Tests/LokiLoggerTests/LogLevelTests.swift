import Testing
@testable import LokiLogger

@Suite("LogLevel Tests")
struct LogLevelTests {

    // MARK: - Tests

    @Test("LogLevel has all expected cases")
    func allCases() {
        let allLevels: [LogLevel] = LogLevel.allCases

        #expect(allLevels.count == 5)
        #expect(allLevels.contains(.debug))
        #expect(allLevels.contains(.info))
        #expect(allLevels.contains(.warn))
        #expect(allLevels.contains(.error))
        #expect(allLevels.contains(.critical))
    }

    @Test("LogLevel raw values are correct")
    func rawValues() {
        #expect(LogLevel.debug.rawValue == "debug")
        #expect(LogLevel.info.rawValue == "info")
        #expect(LogLevel.warn.rawValue == "warn")
        #expect(LogLevel.error.rawValue == "error")
        #expect(LogLevel.critical.rawValue == "critical")
    }

    @Test("LogLevel critical is highest severity")
    func criticalIsHighestSeverity() {
        let orderedLevels: [LogLevel] = [.debug, .info, .warn, .error, .critical]
        let allCases: [LogLevel] = LogLevel.allCases

        #expect(allCases == orderedLevels)
    }
}
