import Foundation

/// Shared by both public assertion APIs; a missing baseline is always read-only.
enum SnapshotBaselinePolicy {
    enum Action: Equatable { case compare, missing, record, recordingForbidden }

    static func recordingRequested(explicit: Bool, environment: [String: String]) -> Bool {
        explicit || ["RECORD_SNAPSHOTS", "SNAPSHOT_RECORD", "TEST_RUNNER_SNAPSHOT_RECORD", "TEST_RUNNER_RECORD_SNAPSHOTS"]
            .contains { environment[$0] == "1" }
    }

    static func action(baselineExists: Bool, recording: Bool, environment: [String: String]) -> Action {
        if recording {
            let isCI = ["CI", "TEST_RUNNER_CI", "GITHUB_ACTIONS"].contains { !(environment[$0] ?? "").isEmpty }
            return isCI ? .recordingForbidden : .record
        }
        return baselineExists ? .compare : .missing
    }
}
