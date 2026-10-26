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
        let environment = ProcessInfo.processInfo.environment
        if environment["SNAPSHOT_RECORD"] == "1" {
            guard environment["CI"] == nil else {
                XCTFail("Recording snapshots is forbidden in CI", file: file, line: line); return
            }
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try XCTUnwrap(actual.pngData()).write(to: referenceURL)
            XCTFail("Recorded \(referenceURL.path). Inspect the image, then rerun without SNAPSHOT_RECORD.", file: file, line: line)
            return
        }
        guard let reference = UIImage(contentsOfFile: referenceURL.path) else {
            attach(actual, name: name + "-actual")
            XCTFail("Missing baseline: \(referenceURL.path). Record and review locally; CI never records.", file: file, line: line)
            return
        }
        guard reference.size == actual.size,
              let actualBytes = rgba(actual), let referenceBytes = rgba(reference),
              let difference = PixelComparison.difference(actual: actualBytes, reference: referenceBytes) else {
            XCTFail("Snapshot dimensions or pixel format differ: \(name)", file: file, line: line); return
        }
        if difference > tolerance {
            attach(reference, name: name + "-reference")
            attach(actual, name: name + "-actual")
            XCTFail("Snapshot \(name): \(difference * 100)% pixels differ; permitted \(tolerance * 100)%", file: file, line: line)
        }
    }

    private static func attach(_ image: UIImage, name: String) {
        XCTContext.runActivity(named: name) { activity in
            let attachment = XCTAttachment(image: image)
            attachment.name = name
            attachment.lifetime = .keepAlways
            activity.add(attachment)
        }
    }

    private static func rgba(_ image: UIImage) -> [UInt8]? {
        guard let cgImage = image.cgImage else { return nil }
        let width = cgImage.width, height = cgImage.height
        var bytes = [UInt8](repeating: 0, count: width * height * 4)
        let success = bytes.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(data: buffer.baseAddress, width: width, height: height,
                bitsPerComponent: 8, bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return false }
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        return success ? bytes : nil
    }
}
#endif
