import XCTest
@testable import SnapshotTestKit

final class BaselinePolicyTests: XCTestCase {
    func testMissingReferenceNeverRequestsWriting() {
        XCTAssertEqual(SnapshotBaselinePolicy.action(baselineExists: false, recording: false, environment: [:]), .missing)
        XCTAssertEqual(SnapshotBaselinePolicy.action(baselineExists: false, recording: false, environment: ["CI": "true"]), .missing)
    }

    func testEveryRecordingAliasAndExplicitFlagIsRecognized() {
        for key in ["RECORD_SNAPSHOTS", "SNAPSHOT_RECORD", "TEST_RUNNER_SNAPSHOT_RECORD", "TEST_RUNNER_RECORD_SNAPSHOTS"] {
            XCTAssertTrue(SnapshotBaselinePolicy.recordingRequested(explicit: false, environment: [key: "1"]))
        }
        XCTAssertTrue(SnapshotBaselinePolicy.recordingRequested(explicit: true, environment: [:]))
        XCTAssertFalse(SnapshotBaselinePolicy.recordingRequested(explicit: false, environment: ["SNAPSHOT_RECORD": "0"]))
    }

    func testCIRejectsRecordingWhetherReferenceExistsOrNot() {
        for flag in ["CI", "TEST_RUNNER_CI", "GITHUB_ACTIONS"] {
            for exists in [false, true] {
                XCTAssertEqual(SnapshotBaselinePolicy.action(baselineExists: exists, recording: true,
                                                            environment: [flag: "true"]), .recordingForbidden)
            }
        }
    }

    func testLocalRecordingIsExplicitAndExistingReferencesCompare() {
        XCTAssertEqual(SnapshotBaselinePolicy.action(baselineExists: true, recording: false, environment: [:]), .compare)
        XCTAssertEqual(SnapshotBaselinePolicy.action(baselineExists: false, recording: true, environment: [:]), .record)
    }
}
