import Foundation

/// Protocol for providing device information.
///
/// Abstracted for testability and platform-specific implementations.
public protocol DeviceInfoProviding: Sendable {
    /// The device model identifier (e.g., "iPhone14,2", "MacBookPro18,3").
    var deviceModel: String { get }

    /// The operating system version string (e.g., "17.2", "14.0").
    var osVersion: String { get }
}

/// Default implementation for extracting device information.
///
/// Uses platform-specific APIs to retrieve device model and OS version.
/// All APIs used are thread-safe and do not require MainActor.
public struct DeviceInfo: DeviceInfoProviding, Sendable {

    // MARK: - Properties

    public let deviceModel: String
    public let osVersion: String

    // MARK: - Lifecycle

    /// Creates a DeviceInfo instance with current device information.
    public init() {
        self.deviceModel = Self.currentDeviceModel()
        self.osVersion = Self.currentOSVersion()
    }

    // MARK: - Private Methods

    private static func currentDeviceModel() -> String {
        var systemInfo: utsname = utsname()
        uname(&systemInfo)
        let machineMirror: Mirror = Mirror(reflecting: systemInfo.machine)
        let identifier: String = machineMirror.children.reduce("") { identifier, element in
            guard let value: Int8 = element.value as? Int8, value != 0 else {
                return identifier
            }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }

    private static func currentOSVersion() -> String {
        let version: OperatingSystemVersion = ProcessInfo.processInfo.operatingSystemVersion
        return "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
    }
}
