# SnapshotTestKit

An owned, test-only Swift package for iOS 16+. Renders SwiftUI in a scene-hosted window, normalizes to RGBA pixels, and compares against reviewed PNG baselines. No third-party snapshot engine.

Call `try await Snapshot.assert(view, named: "screen-light")` from an app-hosted XCTest. Default size is iPhone 11 logical bounds (414 × 896), scale 1, English locale, light appearance, and exact pixel comparison. Pass `.dark` and accessibility Dynamic Type environments explicitly for other variants. Fixtures must already be in deterministic states.

Baselines live beside the test source in `__Snapshots__/iOS-MAJOR.MINOR/`. Missing references fail. Mismatches attach reference and actual images to xcresult. Set `TEST_RUNNER_SNAPSHOT_RECORD=1` for a local xcodebuild run to record; recording deliberately fails the test and must be followed by image inspection and a normal passing run. `CI` forbids recording. Never auto-update baselines in CI. Keep simulator runtime, device, locale and Xcode identical when comparing.

`swift test --scratch-path /tmp/SnapshotTestKitBuild` verifies pixel comparison. UIKit rendering is validated by consuming applications on simulator.
