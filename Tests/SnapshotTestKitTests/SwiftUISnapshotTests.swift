#if canImport(UIKit)
import XCTest
import SwiftUI
@testable import SnapshotTestKit

@MainActor
final class SwiftUISnapshotTests: XCTestCase {
    func testDemoCardViewSnapshots() throws {
        guard SnapshotDevice.current == .iPhone11 else {
            throw XCTSkip("Test calibrated for iPhone 11 (iOS 26.5). Current simulator: \(SnapshotDevice.current?.rawValue ?? "Unknown")")
        }

        SnapshotAssert.assertVariants(
            of: DemoCardView(),
            on: .iPhone11,
            named: "DemoCardView"
        )
    }

    func testDemoCardViewOniPhoneDuo() throws {
        guard SnapshotDevice.current == .iPhoneDuo else {
            throw XCTSkip("Test calibrated for iPhone Duo (iOS 27.1). Current simulator: \(SnapshotDevice.current?.rawValue ?? "Unknown")")
        }

        SnapshotAssert.assertVariants(
            of: DemoCardView(),
            on: .iPhoneDuo,
            named: "DemoCardView"
        )
    }

    func testDemoCardViewOniPad() throws {
        guard SnapshotDevice.current == .iPad else {
            throw XCTSkip("Test calibrated for Standard iPad (iOS 27.0). Current simulator: \(SnapshotDevice.current?.rawValue ?? "Unknown")")
        }

        SnapshotAssert.assertVariants(
            of: DemoCardView(),
            on: .iPad,
            named: "DemoCardView"
        )
    }
}
#endif
