#if canImport(UIKit)
import SwiftUI

/// A sample SwiftUI component used for demonstrating multi-variant snapshot testing.
public struct DemoCardView: View {
    public let title: String
    public let subtitle: String
    public let badgeText: String
    public let actionTitle: String

    public init(
        title: String = "Design System Card",
        subtitle: String = "Tested in Light, Dark, and Accessibility on iPhone 11",
        badgeText: String = "iOS 16+",
        actionTitle: String = "Continue"
    ) {
        self.title = title
        self.subtitle = subtitle
        self.badgeText = badgeText
        self.actionTitle = actionTitle
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(badgeText)
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.15))
                    .foregroundColor(.blue)
                    .clipShape(Capsule())
                    .accessibilityLabel("Badge: \(badgeText)")

                Spacer()

                let sealSymbolName = "checkmark.seal.fill"
                Image(systemName: sealSymbolName)
                    .foregroundColor(.green)
                    .accessibilityLabel("Verified component")
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .accessibilityAddTraits(.isHeader)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Button(action: {}) {
                HStack {
                    Spacer()
                    Text(actionTitle)
                        .font(.body.weight(.semibold))
                    Spacer()
                }
                .padding(.vertical, 12)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .accessibilityLabel(actionTitle)
            .accessibilityHint("Double tap to proceed")
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(uiColor: .secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal, 24)
        .accessibilityElement(children: .contain)
    }
}
#endif
