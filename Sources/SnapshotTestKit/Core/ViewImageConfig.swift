#if canImport(UIKit)
import UIKit

/// Defines layout geometry, safe area insets, and trait collections for snapshot rendering.
public struct ViewImageConfig: Sendable {
    public enum Orientation: Sendable {
        case portrait
        case landscape
    }

    public var safeArea: UIEdgeInsets
    public var size: CGSize?
    public var traits: UITraitCollection

    public init(
        safeArea: UIEdgeInsets = .zero,
        size: CGSize? = nil,
        traits: UITraitCollection = .init()
    ) {
        self.safeArea = safeArea
        self.size = size
        self.traits = traits
    }
}

// MARK: - Standard Device Configurations

public extension ViewImageConfig {
    /// Base Phone: iPhone 11 (Logical: 414 × 896 pt, @2x scale). Target OS: iOS 26.5.
    static let iPhone11 = ViewImageConfig.iPhone11(.portrait)

    /// iPhone 11 layout with the specified device orientation.
    static func iPhone11(_ orientation: Orientation) -> ViewImageConfig {
        switch orientation {
        case .portrait:
            return ViewImageConfig(
                safeArea: UIEdgeInsets(top: 48, left: 0, bottom: 34, right: 0),
                size: CGSize(width: 414, height: 896),
                traits: .iPhone11(.portrait)
            )
        case .landscape:
            return ViewImageConfig(
                safeArea: UIEdgeInsets(top: 0, left: 48, bottom: 21, right: 48),
                size: CGSize(width: 896, height: 414),
                traits: .iPhone11(.landscape)
            )
        }
    }

    /// Foldable / Dual Aspect Phone: iPhone Duo (Logical: 466 × 678 pt, @3x scale). Target OS: iOS 27.1.
    static let iPhoneDuo = ViewImageConfig.iPhoneDuo(.portrait)

    /// iPhone Duo layout with the specified device orientation.
    static func iPhoneDuo(_ orientation: Orientation) -> ViewImageConfig {
        switch orientation {
        case .portrait:
            return ViewImageConfig(
                safeArea: UIEdgeInsets(top: 47, left: 0, bottom: 34, right: 0),
                size: CGSize(width: 466, height: 678),
                traits: .iPhoneDuo(.portrait)
            )
        case .landscape:
            return ViewImageConfig(
                safeArea: UIEdgeInsets(top: 0, left: 47, bottom: 21, right: 47),
                size: CGSize(width: 678, height: 466),
                traits: .iPhoneDuo(.landscape)
            )
        }
    }

    /// Standard Tablet: iPad (A16) 10.9-inch (Logical: 820 × 1180 pt, @2x scale). Target OS: iPadOS 27.0.
    static let iPadStandard = ViewImageConfig.iPadStandard(.portrait)

    /// Standard iPad layout with the specified device orientation.
    static func iPadStandard(_ orientation: Orientation) -> ViewImageConfig {
        switch orientation {
        case .portrait:
            return ViewImageConfig(
                safeArea: UIEdgeInsets(top: 24, left: 0, bottom: 20, right: 0),
                size: CGSize(width: 820, height: 1180),
                traits: .iPadStandard(.portrait)
            )
        case .landscape:
            return ViewImageConfig(
                safeArea: UIEdgeInsets(top: 24, left: 0, bottom: 20, right: 0),
                size: CGSize(width: 1180, height: 820),
                traits: .iPadStandard(.landscape)
            )
        }
    }
}

// MARK: - UITraitCollection Extensions

public extension UITraitCollection {
    /// Generates trait collections matching the iPhone 11 base device.
    static func iPhone11(_ orientation: ViewImageConfig.Orientation) -> UITraitCollection {
        let base: [UITraitCollection] = [
            .init(displayScale: 2.0),
            .init(userInterfaceIdiom: .phone),
            .init(forceTouchCapability: .unavailable),
            .init(layoutDirection: .leftToRight),
            .init(preferredContentSizeCategory: .medium)
        ]
        switch orientation {
        case .portrait:
            return .init(traitsFrom: base + [
                .init(horizontalSizeClass: .compact),
                .init(verticalSizeClass: .regular)
            ])
        case .landscape:
            return .init(traitsFrom: base + [
                .init(horizontalSizeClass: .regular),
                .init(verticalSizeClass: .compact)
            ])
        }
    }

    /// Generates trait collections matching the iPhone Duo foldable device.
    static func iPhoneDuo(_ orientation: ViewImageConfig.Orientation) -> UITraitCollection {
        let base: [UITraitCollection] = [
            .init(displayScale: 3.0),
            .init(userInterfaceIdiom: .phone),
            .init(forceTouchCapability: .unavailable),
            .init(layoutDirection: .leftToRight),
            .init(preferredContentSizeCategory: .medium)
        ]
        switch orientation {
        case .portrait:
            return .init(traitsFrom: base + [
                .init(horizontalSizeClass: .compact),
                .init(verticalSizeClass: .regular)
            ])
        case .landscape:
            return .init(traitsFrom: base + [
                .init(horizontalSizeClass: .regular),
                .init(verticalSizeClass: .compact)
            ])
        }
    }

    /// Generates trait collections matching the Standard iPad (A16) tablet device.
    static func iPadStandard(_ orientation: ViewImageConfig.Orientation) -> UITraitCollection {
        let base: [UITraitCollection] = [
            .init(displayScale: 2.0),
            .init(userInterfaceIdiom: .pad),
            .init(forceTouchCapability: .unavailable),
            .init(layoutDirection: .leftToRight),
            .init(preferredContentSizeCategory: .medium),
            .init(horizontalSizeClass: .regular),
            .init(verticalSizeClass: .regular)
        ]
        return .init(traitsFrom: base)
    }
}
#endif
