#if canImport(UIKit)
import UIKit
import XCTest

/// Shared baseline policy, RGBA comparison, persistence and failure artifacts.
public enum SnapshotEngine {
    public static func isRecordMode(explicit: Bool) -> Bool {
        SnapshotBaselinePolicy.recordingRequested(explicit: explicit, environment: ProcessInfo.processInfo.environment)
    }

    public static func snapshotURL(file: StaticString, testName: String, snapshotName: String?) -> URL {
        let source = URL(fileURLWithPath: "\(file)")
        let directory = source.deletingLastPathComponent().appendingPathComponent("__Snapshots__")
            .appendingPathComponent(source.deletingPathExtension().lastPathComponent)
        let suffix = snapshotName.flatMap { $0.isEmpty ? nil : "." + $0 } ?? ""
        return directory.appendingPathComponent(sanitize(name: testName) + suffix + ".png")
    }

    public static func sanitize(name: String) -> String {
        String(name.prefix { $0 != "(" }).replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "\\", with: "_")
    }

    @discardableResult
    public static func compare(image: UIImage, file: StaticString, testName: String, snapshotName: String?,
                               record: Bool = false, precision: Float = 1, perceptualPrecision: Float = 1,
                               line: UInt) -> Bool {
        compare(image: image, referenceURL: snapshotURL(file: file, testName: testName, snapshotName: snapshotName),
                record: record, precision: precision, perceptualPrecision: perceptualPrecision, file: file, line: line)
    }

    @discardableResult
    static func compare(image: UIImage, referenceURL: URL, record: Bool, precision: Float,
                        perceptualPrecision: Float, file: StaticString, line: UInt,
                        environment: [String: String] = ProcessInfo.processInfo.environment) -> Bool {
        guard precision.isFinite, perceptualPrecision.isFinite,
              (0...1).contains(precision), (0...1).contains(perceptualPrecision) else {
            XCTFail("Snapshot precision must be between zero and one", file: file, line: line)
            return false
        }
        let recording = SnapshotBaselinePolicy.recordingRequested(explicit: record, environment: environment)
        let action = SnapshotBaselinePolicy.action(baselineExists: FileManager.default.fileExists(atPath: referenceURL.path),
                                                   recording: recording, environment: environment)
        switch action {
        case .recordingForbidden:
            XCTFail("Recording snapshots is forbidden in CI", file: file, line: line)
            return false
        case .missing:
            attach(image, name: "actual-missing-baseline")
            XCTFail("Missing baseline: \(referenceURL.path). Record and review locally; CI never records.", file: file, line: line)
            return false
        case .record:
            do {
                try FileManager.default.createDirectory(at: referenceURL.deletingLastPathComponent(), withIntermediateDirectories: true)
                try XCTUnwrap(image.pngData()).write(to: referenceURL, options: .atomic)
            } catch {
                XCTFail("Failed to record snapshot: \(error)", file: file, line: line)
                return false
            }
            XCTFail("Recorded \(referenceURL.path). Inspect the image and rerun without recording.", file: file, line: line)
            return false
        case .compare:
            break
        }
        guard let reference = UIImage(contentsOfFile: referenceURL.path) else {
            XCTFail("Failed to read baseline: \(referenceURL.path)", file: file, line: line)
            return false
        }
        let result = compareImages(current: image, reference: reference, precision: precision, perceptualPrecision: perceptualPrecision)
        guard !result.isMatch else { return true }
        attach(reference, name: "reference")
        attach(image, name: "actual")
        if let diff = result.diffImage {
            attach(diff, name: "diff")
            try? diff.pngData()?.write(to: referenceURL.deletingPathExtension().appendingPathExtension("diff.png"), options: .atomic)
        }
        XCTFail("Snapshot mismatch: \(result.matchRate * 100)% match; required \(precision * 100)%. Reference: \(referenceURL.path)",
                file: file, line: line)
        return false
    }

    public static func compareImages(current: UIImage, reference: UIImage, precision: Float,
                                     perceptualPrecision: Float) -> (isMatch: Bool, matchRate: Float, diffImage: UIImage?) {
        guard precision.isFinite, perceptualPrecision.isFinite,
              (0...1).contains(precision), (0...1).contains(perceptualPrecision),
              let currentCG = current.cgImage, let referenceCG = reference.cgImage,
              currentCG.width == referenceCG.width, currentCG.height == referenceCG.height,
              let actual = rgba(currentCG), let expected = rgba(referenceCG) else { return (false, 0, nil) }
        let threshold = UInt8((1 - perceptualPrecision) * 255)
        guard let difference = PixelComparison.difference(actual: actual, reference: expected, channelTolerance: threshold) else {
            return (false, 0, nil)
        }
        let matchRate = Float(1 - difference)
        guard matchRate < precision else { return (true, matchRate, nil) }
        var pixels = actual
        for offset in stride(from: 0, to: pixels.count, by: 4) {
            let changed = (0..<4).contains { abs(Int(actual[offset + $0]) - Int(expected[offset + $0])) > Int(threshold) }
            if changed {
                pixels[offset] = 255; pixels[offset + 1] = 0; pixels[offset + 2] = 255; pixels[offset + 3] = 255
            } else {
                pixels[offset] /= 2; pixels[offset + 1] /= 2; pixels[offset + 2] /= 2
            }
        }
        guard let provider = CGDataProvider(data: Data(pixels) as CFData),
              let diff = CGImage(width: currentCG.width, height: currentCG.height, bitsPerComponent: 8, bitsPerPixel: 32,
                                 bytesPerRow: currentCG.width * 4, space: CGColorSpaceCreateDeviceRGB(),
                                 bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                                 provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent) else {
            return (false, matchRate, nil)
        }
        return (false, matchRate, UIImage(cgImage: diff, scale: current.scale, orientation: .up))
    }

    private static func rgba(_ image: CGImage) -> [UInt8]? {
        var bytes = [UInt8](repeating: 0, count: image.width * image.height * 4)
        let success = bytes.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(data: buffer.baseAddress, width: image.width, height: image.height,
                                          bitsPerComponent: 8, bytesPerRow: image.width * 4,
                                          space: CGColorSpaceCreateDeviceRGB(),
                                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return false }
            context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
            return true
        }
        return success ? bytes : nil
    }

    private static func attach(_ image: UIImage, name: String) {
        XCTContext.runActivity(named: name) { activity in
            let attachment = XCTAttachment(image: image)
            attachment.name = name
            attachment.lifetime = .keepAlways
            activity.add(attachment)
        }
    }
}
#endif
