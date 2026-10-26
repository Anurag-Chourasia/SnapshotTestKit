#if canImport(UIKit)
import UIKit

/// Supported snapshot testing devices with their standard configurations and optimal OS runtimes.
public enum SnapshotDevice: String, CaseIterable, Sendable {
    /// Base Phone: iPhone 11 (Logical: 414 × 896 pt, Scale: @2x). Target OS: iOS 26.5.
    case iPhone11 = "iPhone 11"
    /// Foldable / Dual Aspect Phone: iPhone Duo (Logical: 466 × 678 pt, Scale: @3x). Target OS: iOS 27.1.
    case iPhoneDuo = "iPhone Duo"
    /// Standard Tablet: iPad (A16) 10.9-inch (Logical: 820 × 1180 pt, Scale: @2x). Target OS: iPadOS 27.0.
    case iPad = "iPad (A16)"

    /// Friendly identifier used for file naming and tagging.
    public var identifier: String {
        switch self {
        case .iPhone11:
            return "iPhone11"
        case .iPhoneDuo:
            return "iPhoneDuo"
        case .iPad:
            return "iPad"
        }
    }

    /// The recommended, best standard OS version for this device type.
    public var bestStandardOSVersion: String {
        switch self {
        case .iPhone11:
            return "26.5"
        case .iPhoneDuo:
            return "27.1"
        case .iPad:
            return "27.0"
        }
    }

    /// Corresponding ViewImageConfig geometry for snapshot testing.
    public var config: ViewImageConfig {
        switch self {
        case .iPhone11:
            return .iPhone11
        case .iPhoneDuo:
            return .iPhoneDuo
        case .iPad:
            return .iPadStandard
        }
    }

    /// Default destination specifier string for xcodebuild.
    public var destinationString: String {
        "platform=iOS Simulator,name=\(rawValue),OS=\(bestStandardOSVersion)"
    }

    /// Returns the currently active simulator device, if running in an iOS simulator environment.
    public static var current: SnapshotDevice? {
        let envDevice = ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"]
        let deviceName = envDevice ?? UIDevice.current.name

        for device in SnapshotDevice.allCases {
            if deviceName.localizedCaseInsensitiveContains(device.rawValue) ||
               device.rawValue.localizedCaseInsensitiveContains(deviceName) {
                return device
            }
        }
        return nil
    }
}
#endif
