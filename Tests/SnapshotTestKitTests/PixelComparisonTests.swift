import XCTest
@testable import SnapshotTestKit
final class PixelComparisonTests: XCTestCase {
    func testIdenticalPixelsPass() {
        XCTAssertEqual(PixelComparison.difference(actual: [1, 2, 3, 255], reference: [1, 2, 3, 255]), 0)
    }
    func testSingleChannelChangeCountsWholePixel() {
        XCTAssertEqual(PixelComparison.difference(actual: [1, 2, 3, 255, 1, 2, 3, 255], reference: [1, 2, 4, 255, 1, 2, 3, 255]), 0.5)
    }
    func testInvalidOrDifferentDimensionsFail() {
        XCTAssertNil(PixelComparison.difference(actual: [], reference: []))
        XCTAssertNil(PixelComparison.difference(actual: [1], reference: [1]))
        XCTAssertNil(PixelComparison.difference(actual: [1, 2, 3, 4], reference: []))
    }
    func testPerChannelToleranceIsExplicitAndDefaultRemainsExact() {
        let actual: [UInt8] = [2, 4, 6, 255]
        let reference: [UInt8] = [1, 2, 3, 255]
        XCTAssertEqual(PixelComparison.difference(actual: actual, reference: reference), 1)
        XCTAssertEqual(PixelComparison.difference(actual: actual, reference: reference, channelTolerance: 3), 0)
        XCTAssertEqual(PixelComparison.difference(actual: actual, reference: reference, channelTolerance: 2), 1)
    }

}
