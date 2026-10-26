#if canImport(UIKit)
import UIKit
import SwiftUI

/// Pure native accessibility snapshot engine that visualizes VoiceOver reading orders,
/// highlights accessible elements with bounding boxes and callouts, and appends an accessibility legend.
@MainActor
public enum AccessibilityRenderer {
    /// Information captured for each accessible element.
    public struct ElementInfo: Sendable {
        public let index: Int
        public let frame: CGRect
        public let label: String
        public let value: String?
        public let hint: String?
        public let traits: UIAccessibilityTraits
        public let activationPoint: CGPoint?

        public var traitDescriptions: [String] {
            var descriptions: [String] = []
            if traits.contains(.header) { descriptions.append("Header") }
            if traits.contains(.button) { descriptions.append("Button") }
            if traits.contains(.link) { descriptions.append("Link") }
            if traits.contains(.image) { descriptions.append("Image") }
            if traits.contains(.selected) { descriptions.append("Selected") }
            if traits.contains(.notEnabled) { descriptions.append("Disabled") }
            if traits.contains(.playsSound) { descriptions.append("PlaysSound") }
            if traits.contains(.keyboardKey) { descriptions.append("KeyboardKey") }
            if traits.contains(.staticText) { descriptions.append("StaticText") }
            if traits.contains(.summaryElement) { descriptions.append("Summary") }
            if descriptions.isEmpty { descriptions.append("Element") }
            return descriptions
        }

        public var themeColor: UIColor {
            if traits.contains(.button) {
                return UIColor(red: 1.0, green: 0.58, blue: 0.0, alpha: 1.0) // Orange
            } else if traits.contains(.header) {
                return UIColor(red: 0.69, green: 0.32, blue: 0.87, alpha: 1.0) // Purple
            } else if traits.contains(.image) {
                return UIColor(red: 0.2, green: 0.78, blue: 0.35, alpha: 1.0) // Green
            } else if traits.contains(.link) {
                return UIColor(red: 0.0, green: 0.78, blue: 1.0, alpha: 1.0) // Cyan
            } else {
                return UIColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1.0) // iOS Blue
            }
        }
    }

    /// Renders an accessibility snapshot of a UIViewController.
    public static func render(
        controller: UIViewController,
        config: ViewImageConfig
    ) -> UIImage {
        // 1. Render base visual view
        let baseImage = ViewRenderer.render(controller: controller, config: config, style: .light)

        // 2. Discover accessibility elements
        let rawElements = discoverElements(in: controller.view, root: controller.view)
        let sortedElements = sortAndIndex(elements: rawElements)

        // 3. Composite base image, bounding overlays, badges, and accessibility legend
        return drawComposite(
            baseImage: baseImage,
            elements: sortedElements,
            scale: config.traits.displayScale > 0 ? config.traits.displayScale : 2.0
        )
    }

    // MARK: - Element Discovery & Traversal

    private static func discoverElements(in view: UIView, root: UIView) -> [ElementInfo] {
        var results: [ElementInfo] = []
        collectElements(from: view, root: root, into: &results)
        return results
    }

    private static func collectElements(from view: UIView, root: UIView, into elements: inout [ElementInfo]) {
        guard !view.isHidden, view.alpha > 0.01 else { return }

        // Custom accessibility elements container
        if let customElements = view.accessibilityElements as? [AnyObject], !customElements.isEmpty {
            for item in customElements {
                if let subview = item as? UIView {
                    collectElements(from: subview, root: root, into: &elements)
                } else if let axElem = item as? UIAccessibilityElement {
                    let frame = root.convert(axElem.accessibilityFrame, from: nil)
                    if frame.width > 0, frame.height > 0 {
                        let label = axElem.accessibilityLabel ?? ""
                        elements.append(
                            ElementInfo(
                                index: elements.count + 1,
                                frame: frame,
                                label: label,
                                value: axElem.accessibilityValue,
                                hint: axElem.accessibilityHint,
                                traits: axElem.accessibilityTraits,
                                activationPoint: axElem.accessibilityActivationPoint
                            )
                        )
                    }
                }
            }
            return
        }

        // Standard accessibility element
        if view.isAccessibilityElement {
            let frame = view.convert(view.bounds, to: root)
            if frame.width > 0, frame.height > 0 {
                let fallbackText = (view as? UILabel)?.text ?? (view as? UIButton)?.currentTitle ?? ""
                let label = (view.accessibilityLabel?.isEmpty == false ? view.accessibilityLabel : nil) ?? fallbackText
                elements.append(
                    ElementInfo(
                        index: elements.count + 1,
                        frame: frame,
                        label: label,
                        value: view.accessibilityValue,
                        hint: view.accessibilityHint,
                        traits: view.accessibilityTraits,
                        activationPoint: view.accessibilityActivationPoint
                    )
                )
            }
        }

        // Recurse into subviews
        for subview in view.subviews {
            collectElements(from: subview, root: root, into: &elements)
        }
    }

    private static func sortAndIndex(elements: [ElementInfo]) -> [ElementInfo] {
        // Sort according to standard VoiceOver reading order: top-to-bottom, then left-to-right
        let sorted = elements.sorted { a, b in
            if abs(a.frame.minY - b.frame.minY) > 8 {
                return a.frame.minY < b.frame.minY
            }
            return a.frame.minX < b.frame.minX
        }

        return sorted.enumerated().map { index, element in
            ElementInfo(
                index: index + 1,
                frame: element.frame,
                label: element.label,
                value: element.value,
                hint: element.hint,
                traits: element.traits,
                activationPoint: element.activationPoint
            )
        }
    }

    // MARK: - Composite Drawing

    private static func drawComposite(
        baseImage: UIImage,
        elements: [ElementInfo],
        scale: CGFloat
    ) -> UIImage {
        let baseWidth = baseImage.size.width
        let baseHeight = baseImage.size.height

        let rowHeight: CGFloat = 32
        let legendHeaderHeight: CGFloat = 36
        let legendPadding: CGFloat = 16
        let legendHeight = legendHeaderHeight + CGFloat(max(elements.count, 1)) * rowHeight + legendPadding * 2

        let totalHeight = baseHeight + legendHeight
        let canvasSize = CGSize(width: baseWidth, height: totalHeight)

        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = true

        let renderer = UIGraphicsImageRenderer(size: canvasSize, format: format)
        return renderer.image { context in
            let cg = context.cgContext

            // 1. Draw base rendered image
            baseImage.draw(in: CGRect(x: 0, y: 0, width: baseWidth, height: baseHeight))

            // 2. Draw element highlights and badges
            for element in elements {
                let color = element.themeColor

                // Bounding box fill & border
                let boxRect = element.frame.insetBy(dx: -1, dy: -1)
                cg.setFillColor(color.withAlphaComponent(0.12).cgColor)
                cg.fill(boxRect)

                cg.setStrokeColor(color.cgColor)
                cg.setLineWidth(2.0)
                cg.stroke(boxRect)

                // Number badge
                let badgeRadius: CGFloat = 9
                let badgeX = min(max(element.frame.minX + 2, 4), baseWidth - 22)
                let badgeY = min(max(element.frame.minY + 2, 4), baseHeight - 22)
                let badgeRect = CGRect(x: badgeX, y: badgeY, width: badgeRadius * 2, height: badgeRadius * 2)

                cg.setFillColor(color.cgColor)
                cg.fillEllipse(in: badgeRect)

                let numberString = "\(element.index)"
                let numAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 10),
                    .foregroundColor: UIColor.white
                ]
                let numSize = (numberString as NSString).size(withAttributes: numAttrs)
                let numPos = CGPoint(
                    x: badgeRect.midX - numSize.width / 2,
                    y: badgeRect.midY - numSize.height / 2
                )
                (numberString as NSString).draw(at: numPos, withAttributes: numAttrs)
            }

            // 3. Draw Legend Card
            let legendRect = CGRect(x: 0, y: baseHeight, width: baseWidth, height: legendHeight)
            cg.setFillColor(UIColor.systemGroupedBackground.cgColor)
            cg.fill(legendRect)

            // Divider line
            cg.setStrokeColor(UIColor.separator.cgColor)
            cg.setLineWidth(1.0)
            cg.strokeLineSegments(between: [
                CGPoint(x: 0, y: baseHeight),
                CGPoint(x: baseWidth, y: baseHeight)
            ])

            // Legend Header
            let headerAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12, weight: .bold),
                .foregroundColor: UIColor.secondaryLabel
            ]
            let headerText = "ACCESSIBILITY ELEMENTS (VOICEOVER ORDER)"
            (headerText as NSString).draw(at: CGPoint(x: legendPadding, y: baseHeight + legendPadding), withAttributes: headerAttrs)

            // Legend Rows
            if elements.isEmpty {
                let emptyAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 13, weight: .regular),
                    .foregroundColor: UIColor.tertiaryLabel
                ]
                ("No accessible elements detected." as NSString).draw(
                    at: CGPoint(x: legendPadding, y: baseHeight + legendPadding + legendHeaderHeight),
                    withAttributes: emptyAttrs
                )
            } else {
                var currentY = baseHeight + legendPadding + legendHeaderHeight
                for element in elements {
                    let color = element.themeColor

                    // Row Badge
                    let rowBadgeRect = CGRect(x: legendPadding, y: currentY + 4, width: 18, height: 18)
                    cg.setFillColor(color.cgColor)
                    cg.fillEllipse(in: rowBadgeRect)

                    let rowNumStr = "\(element.index)"
                    let rowNumAttrs: [NSAttributedString.Key: Any] = [
                        .font: UIFont.boldSystemFont(ofSize: 10),
                        .foregroundColor: UIColor.white
                    ]
                    let rowNumSize = (rowNumStr as NSString).size(withAttributes: rowNumAttrs)
                    (rowNumStr as NSString).draw(
                        at: CGPoint(x: rowBadgeRect.midX - rowNumSize.width / 2, y: rowBadgeRect.midY - rowNumSize.height / 2),
                        withAttributes: rowNumAttrs
                    )

                    // Traits pill text
                    let traitsStr = "[\(element.traitDescriptions.joined(separator: ", "))]"
                    let traitsAttrs: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: 11, weight: .semibold),
                        .foregroundColor: color
                    ]
                    let traitsSize = (traitsStr as NSString).size(withAttributes: traitsAttrs)
                    (traitsStr as NSString).draw(
                        at: CGPoint(x: legendPadding + 26, y: currentY + 5),
                        withAttributes: traitsAttrs
                    )

                    // Label & value
                    var detailsText = element.label.isEmpty ? "(\"unlabeled\")" : "\"\(element.label)\""
                    if let val = element.value, !val.isEmpty {
                        detailsText += " • Value: \"\(val)\""
                    }
                    if let hint = element.hint, !hint.isEmpty {
                        detailsText += " • Hint: \"\(hint)\""
                    }

                    let detailsAttrs: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: 12, weight: .regular),
                        .foregroundColor: UIColor.label
                    ]
                    let textX = legendPadding + 32 + traitsSize.width
                    let availableWidth = baseWidth - textX - legendPadding
                    let detailsRect = CGRect(x: textX, y: currentY + 4, width: availableWidth, height: 20)
                    (detailsText as NSString).draw(in: detailsRect, withAttributes: detailsAttrs)

                    currentY += rowHeight
                }
            }
        }
    }
}
#endif
