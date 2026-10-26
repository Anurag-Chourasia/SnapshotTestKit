#if canImport(UIKit)
import UIKit
import XCTest

/// Core comparison, disk persistence, and diffing engine for snapshot testing.
public enum SnapshotEngine {
    /// Determines whether record mode is active via explicit flag or environment variables.
    public static func isRecordMode(explicit: Bool) -> Bool {
        if explicit { return true }
        let env = ProcessInfo.processInfo.environment
        return env["RECORD_SNAPSHOTS"] == "1" ||
               env["SNAPSHOT_RECORD"] == "1"
    }

    /// Resolves the file URL for the baseline snapshot on disk.
    public static func snapshotURL(
        file: StaticString,
        testName: String,
        snapshotName: String?
    ) -> URL {
        let sourceURL = URL(fileURLWithPath: "\(file)")
        let testClassName = sourceURL.deletingPathExtension().lastPathComponent
        let snapshotsDir = sourceURL
            .deletingLastPathComponent()
            .appendingPathComponent("__Snapshots__", isDirectory: true)
            .appendingPathComponent(testClassName, isDirectory: true)

        let cleanTestName = sanitize(name: testName)
        let filename: String
        if let name = snapshotName, !name.isEmpty {
            filename = "\(cleanTestName).\(name).png"
        } else {
            filename = "\(cleanTestName).png"
        }

        return snapshotsDir.appendingPathComponent(filename)
    }

    /// Strips trailing parentheses, argument labels, and special characters from test function names.
    public static func sanitize(name: String) -> String {
        var clean = name
        if let parenIndex = clean.firstIndex(of: "(") {
            clean = String(clean[..<parenIndex])
        }
        return clean
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "\\", with: "_")
    }

    /// Compares a rendered UIImage against a reference image stored on disk.
    @discardableResult
    public static func compare(
        image: UIImage,
        file: StaticString,
        testName: String,
        snapshotName: String?,
        record: Bool = false,
        precision: Float = 1.0,
        perceptualPrecision: Float = 1.0,
        line: UInt
    ) -> Bool {
        let referenceURL = snapshotURL(file: file, testName: testName, snapshotName: snapshotName)
        let isRecord = isRecordMode(explicit: record)

        guard let currentData = image.pngData() else {
            XCTFail("Failed to encode current snapshot to PNG data", file: file, line: line)
            return false
        }

        let fileManager = FileManager.default

        // Record mode or missing baseline
        if isRecord || !fileManager.fileExists(atPath: referenceURL.path) {
            do {
                try fileManager.createDirectory(
                    at: referenceURL.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
                try currentData.write(to: referenceURL, options: .atomic)
            } catch {
                XCTFail("Failed to record snapshot to \(referenceURL.path): \(error)", file: file, line: line)
                return false
            }

            let message = """
            No reference was found on disk. Automatically recorded snapshot: …

            open "file://\(referenceURL.path)"

            Re-run "\(sanitize(name: testName))" to assert against the newly-recorded snapshot.
            """
            XCTFail(message, file: file, line: line)
            return false
        }

        // Baseline exists, load and compare
        guard let referenceImage = UIImage(contentsOfFile: referenceURL.path) else {
            XCTFail("Failed to load reference image at: \(referenceURL.path)", file: file, line: line)
            return false
        }

        let result = compareImages(
            current: image,
            reference: referenceImage,
            precision: precision,
            perceptualPrecision: perceptualPrecision
        )

        if result.isMatch {
            return true
        } else {
            let diffURL = referenceURL.deletingPathExtension().appendingPathExtension("diff.png")
            if let diffImage = result.diffImage, let diffData = diffImage.pngData() {
                try? diffData.write(to: diffURL, options: .atomic)
            }

            let message = """
            Snapshot mismatch (\(String(format: "%.2f%%", result.matchRate * 100)) match, required \(String(format: "%.2f%%", precision * 100))):
            Reference: "file://\(referenceURL.path)"
            Diff:      "file://\(diffURL.path)"
            """
            XCTFail(message, file: file, line: line)
            return false
        }
    }

    /// Performs pixel-by-pixel bitmap comparison with precision thresholds and generates a diff image on mismatch.
    public static func compareImages(
        current: UIImage,
        reference: UIImage,
        precision: Float,
        perceptualPrecision: Float
    ) -> (isMatch: Bool, matchRate: Float, diffImage: UIImage?) {
        guard let curCG = current.cgImage, let refCG = reference.cgImage else {
            return (false, 0, nil)
        }

        let width = curCG.width
        let height = curCG.height

        guard width == refCG.width && height == refCG.height else {
            return (false, 0, nil)
        }

        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let totalBytes = bytesPerRow * height
        let totalPixels = width * height

        var curPixels = [UInt8](repeating: 0, count: totalBytes)
        var refPixels = [UInt8](repeating: 0, count: totalBytes)
        var diffPixels = [UInt8](repeating: 0, count: totalBytes)

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue

        guard
            let curCtx = CGContext(
                data: &curPixels,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: bitmapInfo
            ),
            let refCtx = CGContext(
                data: &refPixels,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: bitmapInfo
            ),
            let diffCtx = CGContext(
                data: &diffPixels,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: bitmapInfo
            )
        else {
            return (false, 0, nil)
        }

        let rect = CGRect(x: 0, y: 0, width: width, height: height)
        curCtx.draw(curCG, in: rect)
        refCtx.draw(refCG, in: rect)

        var matchingPixels = 0
        let threshold = Int((1.0 - min(max(perceptualPrecision, 0.0), 1.0)) * 255.0)

        for i in 0..<totalPixels {
            let offset = i * bytesPerPixel
            let rDiff = abs(Int(curPixels[offset]) - Int(refPixels[offset]))
            let gDiff = abs(Int(curPixels[offset + 1]) - Int(refPixels[offset + 1]))
            let bDiff = abs(Int(curPixels[offset + 2]) - Int(refPixels[offset + 2]))
            let aDiff = abs(Int(curPixels[offset + 3]) - Int(refPixels[offset + 3]))

            if rDiff <= threshold && gDiff <= threshold && bDiff <= threshold && aDiff <= threshold {
                matchingPixels += 1
                diffPixels[offset] = curPixels[offset] / 2
                diffPixels[offset + 1] = curPixels[offset + 1] / 2
                diffPixels[offset + 2] = curPixels[offset + 2] / 2
                diffPixels[offset + 3] = curPixels[offset + 3]
            } else {
                diffPixels[offset] = 255
                diffPixels[offset + 1] = 0
                diffPixels[offset + 2] = 255
                diffPixels[offset + 3] = 255
            }
        }

        let matchRate = Float(matchingPixels) / Float(totalPixels)
        let isMatch = matchRate >= precision

        var diffImage: UIImage? = nil
        if !isMatch, let diffCG = diffCtx.makeImage() {
            diffImage = UIImage(cgImage: diffCG, scale: current.scale, orientation: .up)
        }

        return (isMatch, matchRate, diffImage)
    }
}
#endif
