#if canImport(UIKit)
import XCTest
import UIKit
@testable import SnapshotTestKit

@MainActor
final class EngineContractTests: XCTestCase {
    private func image(_ color: UIColor) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: 12, height: 12), format: format).image { context in
            color.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 12, height: 12))
        }
    }

    private func expectedFailure(_ message: String, action: () -> Void) {
        let options = XCTExpectedFailure.Options()
        options.issueMatcher = { $0.compactDescription.contains(message) }
        XCTExpectFailure(message, options: options, failingBlock: action)
    }

    func testMissingBaselineFailsWithoutCreatingFileOrDirectory() {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let reference = folder.appendingPathComponent("missing.png")
        var matched = true
        expectedFailure("Missing baseline") {
            matched = SnapshotEngine.compare(image: image(.red), referenceURL: reference, record: false,
                                              precision: 1, perceptualPrecision: 1, file: #filePath, line: #line,
                                              environment: [:])
        }
        XCTAssertFalse(matched)
        XCTAssertFalse(FileManager.default.fileExists(atPath: folder.path))
    }

    func testCIRecordingCannotOverwriteReference() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let reference = folder.appendingPathComponent("existing.png")
        let original = try XCTUnwrap(image(.red).pngData())
        try original.write(to: reference)
        expectedFailure("Recording snapshots is forbidden in CI") {
            SnapshotEngine.compare(image: image(.blue), referenceURL: reference, record: true,
                                   precision: 1, perceptualPrecision: 1, file: #filePath, line: #line,
                                   environment: ["CI": "true"])
        }
        XCTAssertEqual(try Data(contentsOf: reference), original)
    }

    func testDeliberateVisualChangeFailsAndProducesDiff() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let reference = folder.appendingPathComponent("reference.png")
        try XCTUnwrap(image(.red).pngData()).write(to: reference)
        expectedFailure("Snapshot mismatch") {
            SnapshotEngine.compare(image: image(.blue), referenceURL: reference, record: false,
                                   precision: 1, perceptualPrecision: 1, file: #filePath, line: #line,
                                   environment: [:])
        }
        let diff = try XCTUnwrap(UIImage(contentsOfFile: folder.appendingPathComponent("reference.diff.png").path))
        XCTAssertEqual(diff.size, CGSize(width: 12, height: 12))
        XCTAssertTrue(SnapshotEngine.compareImages(current: image(.red), reference: image(.red),
                                                  precision: 1, perceptualPrecision: 1).isMatch)
    }

    func testExplicitLocalRecordingRequiresReviewAndThenComparisonPasses() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let reference = folder.appendingPathComponent("recorded.png")
        expectedFailure("Recorded") {
            SnapshotEngine.compare(image: image(.red), referenceURL: reference, record: true,
                                   precision: 1, perceptualPrecision: 1, file: #filePath, line: #line,
                                   environment: [:])
        }
        XCTAssertTrue(SnapshotEngine.compare(image: image(.red), referenceURL: reference, record: false,
                                            precision: 1, perceptualPrecision: 1, file: #filePath, line: #line,
                                            environment: [:]))
    }
}
#endif
