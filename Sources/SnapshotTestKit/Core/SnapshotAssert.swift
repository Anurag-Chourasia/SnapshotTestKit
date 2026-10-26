#if canImport(UIKit)
import UIKit
import SwiftUI
import XCTest

/// Public assertion API providing snapshot testing across Light, Dark, and Accessibility modalities.
public enum SnapshotAssert {
    /// Checks whether record mode is active either explicitly or via environment variables (`RECORD_SNAPSHOTS=1` or `SNAPSHOT_RECORD=1`).
    public static var isRecordModeEnabled: Bool {
        SnapshotEngine.isRecordMode(explicit: false)
    }

    /// Asserts snapshots for a SwiftUI view in 3 variants: Light, Dark, and Accessibility on the specified device.
    ///
    /// - Parameters:
    ///   - view: The SwiftUI view to snapshot.
    ///   - device: The snapshot target device (.iPhone11, .iPhoneDuo, or .iPad). Defaults to base device .iPhone11.
    ///   - named: Optional custom snapshot name prefix.
    ///   - variants: The set of snapshot variants to run. Defaults to all 3 modes (.light, .dark, .accessibility).
    ///   - record: Set to true to record new baseline images.
    ///   - precision: Percentage of pixels that must match (1.0 = 100%).
    ///   - perceptualPrecision: Visual pixel match threshold (1.0 = exact).
    ///   - file: The file where assertion is called.
    ///   - testName: The test function name.
    ///   - line: The line number.
    public static func assertVariants<V: View>(
        of view: V,
        on device: SnapshotDevice = .iPhone11,
        named: String? = nil,
        variants: Set<SnapshotVariant> = .allThreeModes,
        record: Bool = isRecordModeEnabled,
        precision: Float = 0.99,
        perceptualPrecision: Float = 0.98,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) {
        runOnMain {
            let hostingController = UIHostingController(rootView: view)
            let config = device.config
            let width = config.size?.width ?? 414
            let height = config.size?.height ?? 896
            hostingController.view.bounds = CGRect(x: 0, y: 0, width: width, height: height)
            hostingController.view.layoutIfNeeded()

            assertVariants(
                of: hostingController,
                on: device,
                named: named,
                variants: variants,
                record: record,
                precision: precision,
                perceptualPrecision: perceptualPrecision,
                file: file,
                testName: testName,
                line: line
            )
        }
    }

    /// Asserts snapshots for a UIViewController in 3 variants: Light, Dark, and Accessibility on the specified device.
    ///
    /// - Parameters:
    ///   - controller: The UIViewController to snapshot.
    ///   - device: The snapshot target device (.iPhone11, .iPhoneDuo, or .iPad). Defaults to .iPhone11.
    ///   - named: Optional custom snapshot name prefix.
    ///   - variants: The set of snapshot variants to run. Defaults to all 3 modes (.light, .dark, .accessibility).
    ///   - record: Set to true to record new baseline images.
    ///   - precision: Percentage of pixels that must match.
    ///   - perceptualPrecision: Visual pixel match threshold.
    ///   - file: Calling file.
    ///   - testName: Calling function.
    ///   - line: Calling line number.
    public static func assertVariants(
        of controller: UIViewController,
        on device: SnapshotDevice = .iPhone11,
        named: String? = nil,
        variants: Set<SnapshotVariant> = .allThreeModes,
        record: Bool = isRecordModeEnabled,
        precision: Float = 0.99,
        perceptualPrecision: Float = 0.98,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) {
        runOnMain {
            let deviceSuffix = (device == .iPhone11) ? "" : "-\(device.identifier)"
            let baseName: String
            if let customName = named {
                baseName = "\(customName)\(deviceSuffix)-"
            } else {
                baseName = (device == .iPhone11) ? "" : "\(device.identifier)-"
            }

            let config = device.config

            // 1. Light Mode
            if variants.contains(.light) {
                let image = ViewRenderer.render(controller: controller, config: config, style: .light)
                SnapshotEngine.compare(
                    image: image,
                    file: file,
                    testName: testName,
                    snapshotName: "\(baseName)light",
                    record: record,
                    precision: precision,
                    perceptualPrecision: perceptualPrecision,
                    line: line
                )
            }

            // 2. Dark Mode
            if variants.contains(.dark) {
                let image = ViewRenderer.render(controller: controller, config: config, style: .dark)
                SnapshotEngine.compare(
                    image: image,
                    file: file,
                    testName: testName,
                    snapshotName: "\(baseName)dark",
                    record: record,
                    precision: precision,
                    perceptualPrecision: perceptualPrecision,
                    line: line
                )
            }

            // 3. Accessibility Mode
            if variants.contains(.accessibility) {
                let image = AccessibilityRenderer.render(controller: controller, config: config)
                SnapshotEngine.compare(
                    image: image,
                    file: file,
                    testName: testName,
                    snapshotName: "\(baseName)accessibility",
                    record: record,
                    precision: precision,
                    perceptualPrecision: perceptualPrecision,
                    line: line
                )
            }
        }
    }

    /// Asserts snapshots for a UIView in 3 variants: Light, Dark, and Accessibility on the specified device.
    ///
    /// - Parameters:
    ///   - view: The UIView to snapshot.
    ///   - device: The snapshot target device (.iPhone11, .iPhoneDuo, or .iPad). Defaults to .iPhone11.
    ///   - named: Optional custom snapshot name prefix.
    ///   - variants: The set of snapshot variants to run. Defaults to all 3 modes (.light, .dark, .accessibility).
    ///   - record: Set to true to record new baseline images.
    ///   - precision: Percentage of pixels that must match.
    ///   - perceptualPrecision: Visual pixel match threshold.
    ///   - file: Calling file.
    ///   - testName: Calling function.
    ///   - line: Calling line number.
    public static func assertVariants(
        of view: UIView,
        on device: SnapshotDevice = .iPhone11,
        named: String? = nil,
        variants: Set<SnapshotVariant> = .allThreeModes,
        record: Bool = isRecordModeEnabled,
        precision: Float = 0.99,
        perceptualPrecision: Float = 0.98,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) {
        runOnMain {
            let containerController = UIViewController()
            containerController.view.backgroundColor = .systemBackground
            containerController.view.addSubview(view)
            view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                view.centerXAnchor.constraint(equalTo: containerController.view.centerXAnchor),
                view.centerYAnchor.constraint(equalTo: containerController.view.centerYAnchor),
                view.leadingAnchor.constraint(greaterThanOrEqualTo: containerController.view.leadingAnchor, constant: 16),
                view.trailingAnchor.constraint(lessThanOrEqualTo: containerController.view.trailingAnchor, constant: -16)
            ])

            let config = device.config
            let width = config.size?.width ?? 414
            let height = config.size?.height ?? 896
            containerController.view.bounds = CGRect(x: 0, y: 0, width: width, height: height)
            containerController.view.layoutIfNeeded()

            assertVariants(
                of: containerController,
                on: device,
                named: named,
                variants: variants,
                record: record,
                precision: precision,
                perceptualPrecision: perceptualPrecision,
                file: file,
                testName: testName,
                line: line
            )
        }
    }

    /// Helper to execute a block on the main actor synchronously.
    private static func runOnMain(_ block: @MainActor () -> Void) {
        if Thread.isMainThread {
            MainActor.assumeIsolated {
                block()
            }
        } else {
            DispatchQueue.main.sync {
                MainActor.assumeIsolated {
                    block()
                }
            }
        }
    }
}

// MARK: - PointFree Style Convenience Function

public enum SnapshotStrategy<Value> {
    case image(
        on: ViewImageConfig = .iPhone11,
        precision: Float = 0.99,
        perceptualPrecision: Float = 0.98,
        traits: UITraitCollection = .init()
    )
}

public func assertSnapshot<V: View>(
    of view: V,
    as strategy: SnapshotStrategy<V> = .image(),
    named name: String? = nil,
    record: Bool = SnapshotAssert.isRecordModeEnabled,
    file: StaticString = #file,
    testName: String = #function,
    line: UInt = #line
) {
    if Thread.isMainThread {
        MainActor.assumeIsolated {
            executeAssertSnapshot(of: view, as: strategy, named: name, record: record, file: file, testName: testName, line: line)
        }
    } else {
        DispatchQueue.main.sync {
            MainActor.assumeIsolated {
                executeAssertSnapshot(of: view, as: strategy, named: name, record: record, file: file, testName: testName, line: line)
            }
        }
    }
}

@MainActor
private func executeAssertSnapshot<V: View>(
    of view: V,
    as strategy: SnapshotStrategy<V>,
    named name: String?,
    record: Bool,
    file: StaticString,
    testName: String,
    line: UInt
) {
    switch strategy {
    case let .image(config, precision, perceptualPrecision, traits):
        var modifiedConfig = config
        if traits.userInterfaceStyle != .unspecified {
            modifiedConfig.traits = UITraitCollection(traitsFrom: [config.traits, traits])
        }
        let style = (traits.userInterfaceStyle == .dark) ? UIUserInterfaceStyle.dark : UIUserInterfaceStyle.light
        let image = ViewRenderer.render(view: view, config: modifiedConfig, style: style)
        SnapshotEngine.compare(
            image: image,
            file: file,
            testName: testName,
            snapshotName: name,
            record: record,
            precision: precision,
            perceptualPrecision: perceptualPrecision,
            line: line
        )
    }
}
#endif
