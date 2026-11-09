#if canImport(UIKit)
import XCTest
import UIKit
@testable import SnapshotTestKit

@MainActor
final class UIKitSnapshotTests: XCTestCase {
    func testDemoBannerViewSnapshots() throws {
        guard SnapshotDevice.current == .iPhone11 else {
            throw XCTSkip("Test calibrated for iPhone 11 (iOS 26.5). Current simulator: \(SnapshotDevice.current?.rawValue ?? "Unknown")")
        }

        SnapshotAssert.assertVariants(
            of: DemoBannerView(),
            on: .iPhone11,
            named: "DemoBannerView"
        )
    }

    func testDemoBannerViewOniPhoneDuo() throws {
        guard SnapshotDevice.current == .iPhoneDuo else {
            throw XCTSkip("Test calibrated for iPhone Duo (iOS 27.1). Current simulator: \(SnapshotDevice.current?.rawValue ?? "Unknown")")
        }

        SnapshotAssert.assertVariants(
            of: DemoBannerView(),
            on: .iPhoneDuo,
            named: "DemoBannerView"
        )
    }

    func testDemoBannerViewOniPad() throws {
        guard SnapshotDevice.current == .iPad else {
            throw XCTSkip("Test calibrated for Standard iPad (iOS 27.0). Current simulator: \(SnapshotDevice.current?.rawValue ?? "Unknown")")
        }

        SnapshotAssert.assertVariants(
            of: DemoBannerView(),
            on: .iPad,
            named: "DemoBannerView"
        )
    }
}
#endif
