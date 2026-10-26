#if canImport(UIKit)
import XCTest
import UIKit
@testable import SnapshotTestKit

final class SnapshotDeviceTests: XCTestCase {
    func testiPhone11PortraitConfiguration() {
        let config = ViewImageConfig.iPhone11

        XCTAssertEqual(config.size?.width, 414, "iPhone 11 logical width should be 414 points")
        XCTAssertEqual(config.size?.height, 896, "iPhone 11 logical height should be 896 points")
        XCTAssertEqual(config.safeArea.top, 48, "iPhone 11 top safe area should be 48 points")
        XCTAssertEqual(config.safeArea.bottom, 34, "iPhone 11 bottom safe area should be 34 points")
        XCTAssertEqual(config.traits.userInterfaceIdiom, .phone, "iPhone 11 idiom should be phone")
        XCTAssertEqual(config.traits.horizontalSizeClass, .compact, "iPhone 11 portrait horizontal size class should be compact")
        XCTAssertEqual(config.traits.verticalSizeClass, .regular, "iPhone 11 portrait vertical size class should be regular")
    }

    func testiPhone11LandscapeConfiguration() {
        let config = ViewImageConfig.iPhone11(.landscape)

        XCTAssertEqual(config.size?.width, 896)
        XCTAssertEqual(config.size?.height, 414)
        XCTAssertEqual(config.safeArea.left, 48)
        XCTAssertEqual(config.safeArea.right, 48)
        XCTAssertEqual(config.safeArea.bottom, 21)
        XCTAssertEqual(config.traits.horizontalSizeClass, .regular)
        XCTAssertEqual(config.traits.verticalSizeClass, .compact)
    }
}
#endif
