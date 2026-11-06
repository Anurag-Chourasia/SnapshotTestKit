// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SnapshotTestKit",
    platforms: [
        .iOS(.v16),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "SnapshotTestKit",
            targets: ["SnapshotTestKit"]
        ),
        .library(
            name: "SnapshotTestingKit",
            targets: ["SnapshotTestKit"]
        )
    ],
    targets: [
        .target(
            name: "SnapshotTestKit",
            path: "Sources/SnapshotTestKit"
        ),
        .testTarget(
            name: "SnapshotTestKitTests",
            dependencies: ["SnapshotTestKit"],
            path: "Tests/SnapshotTestKitTests",
            exclude: [
                "__Snapshots__"
            ]
        )
    ]
)
