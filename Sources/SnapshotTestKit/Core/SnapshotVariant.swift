#if canImport(UIKit)
import Foundation

/// Represents the three snapshot testing modes supported by the test harness.
public enum SnapshotVariant: String, CaseIterable, Hashable, Sendable {
    /// Standard snapshot rendered under Light user interface style.
    case light
    /// Standard snapshot rendered under Dark user interface style.
    case dark
    /// Accessibility snapshot highlighting VoiceOver elements, activation points, and legend.
    case accessibility
}

public extension Set where Element == SnapshotVariant {
    /// The standard snapshot test suite testing in all 3 required ways: Light, Dark, and Accessibility.
    static let allThreeModes: Set<SnapshotVariant> = [.light, .dark, .accessibility]
}
#endif
