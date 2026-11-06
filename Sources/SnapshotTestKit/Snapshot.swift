#if canImport(UIKit)
import UIKit
import SwiftUI
import XCTest

/// Test-only library. Never link this product to an application target.
@MainActor
public enum Snapshot {
    public static func assert<V: View>(
        _ view: V, named name: String, size: CGSize = CGSize(width: 414, height: 896),
        style: UIUserInterfaceStyle = .light, tolerance: Double = 0,
        file: StaticString = #filePath, line: UInt = #line
    ) async throws {
        guard tolerance >= 0, tolerance <= 1 else {
            XCTFail("Snapshot tolerance must be between zero and one", file: file, line: line); return
        }
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let previous = scene.windows.first(where: \.isKeyWindow)
        let window = UIWindow(windowScene: scene)
        window.frame = CGRect(origin: .zero, size: size)
        window.overrideUserInterfaceStyle = style
        let controller = UIHostingController(rootView: view.environment(\.locale, Locale(identifier: "en_US")))
        window.rootViewController = controller
        window.makeKeyAndVisible()
        defer { window.isHidden = true; previous?.makeKeyAndVisible() }
        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()
        // Allow SwiftUI's main-run-loop layout transaction to finish.
        try await Task.sleep(nanoseconds: 300_000_000)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let actual = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            XCTAssertTrue(window.drawHierarchy(in: window.bounds, afterScreenUpdates: true), file: file, line: line)
        }
        let version = ProcessInfo.processInfo.operatingSystemVersion
        let directory = URL(fileURLWithPath: "\(file)").deletingLastPathComponent()
            .appendingPathComponent("__Snapshots__/iOS-\(version.majorVersion).\(version.minorVersion)")
        let referenceURL = directory.appendingPathComponent(name + ".png")
        SnapshotEngine.compare(image: actual, referenceURL: referenceURL, record: false,
                               precision: Float(1 - tolerance), perceptualPrecision: 1, file: file, line: line)
    }
}
#endif
