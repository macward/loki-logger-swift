import Foundation
@testable import LokiLogger

/// Mock DeviceInfo for testing without real device dependencies.
struct MockDeviceInfo: DeviceInfoProviding, Sendable {

    // MARK: - Properties

    /// Device model to return.
    let deviceModel: String

    /// OS version to return.
    let osVersion: String

    // MARK: - Lifecycle

    /// Creates a mock with default values.
    init(deviceModel: String = "TestDevice", osVersion: String = "1.0.0") {
        self.deviceModel = deviceModel
        self.osVersion = osVersion
    }
}
