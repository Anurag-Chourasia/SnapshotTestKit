#if canImport(UIKit)
import UIKit
import SwiftUI

/// Pure native rendering engine that converts UIKit and SwiftUI view hierarchies into UIImages.
@MainActor
public enum ViewRenderer {
    /// Renders a UIViewController into a UIImage with the provided configuration and user interface style.
    public static func render(
        controller: UIViewController,
        config: ViewImageConfig,
        style: UIUserInterfaceStyle = .light
    ) -> UIImage {
        let targetSize = config.size ?? controller.view.bounds.size
        let targetWidth = max(targetSize.width, 1)
        let targetHeight = max(targetSize.height, 1)
        let frame = CGRect(x: 0, y: 0, width: targetWidth, height: targetHeight)

        let window: UIWindow
        if let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first {
            window = UIWindow(windowScene: scene)
        } else {
            window = UIWindow(frame: frame)
        }
        window.frame = frame
        window.overrideUserInterfaceStyle = style

        controller.additionalSafeAreaInsets = config.safeArea
        controller.overrideUserInterfaceStyle = style
        controller.view.frame = frame
        controller.view.overrideUserInterfaceStyle = style

        window.rootViewController = controller
        window.isHidden = false

        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()

        let scale = config.traits.displayScale > 0 ? config.traits.displayScale : 2.0
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = false

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: targetWidth, height: targetHeight), format: format)
        let image = renderer.image { context in
            let drawn = controller.view.drawHierarchy(in: frame, afterScreenUpdates: true)
            if !drawn {
                controller.view.layer.render(in: context.cgContext)
            }
        }

        window.isHidden = true
        window.rootViewController = nil
        return image
    }

    /// Renders a standalone UIView into a UIImage.
    public static func render(
        view: UIView,
        config: ViewImageConfig,
        style: UIUserInterfaceStyle = .light
    ) -> UIImage {
        let hostController = UIViewController()
        hostController.view.backgroundColor = .systemBackground
        hostController.view.addSubview(view)

        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.centerXAnchor.constraint(equalTo: hostController.view.centerXAnchor),
            view.centerYAnchor.constraint(equalTo: hostController.view.centerYAnchor),
            view.leadingAnchor.constraint(greaterThanOrEqualTo: hostController.view.leadingAnchor, constant: 16),
            view.trailingAnchor.constraint(lessThanOrEqualTo: hostController.view.trailingAnchor, constant: -16)
        ])

        return render(controller: hostController, config: config, style: style)
    }

    /// Renders a SwiftUI View into a UIImage.
    public static func render<V: View>(
        view: V,
        config: ViewImageConfig,
        style: UIUserInterfaceStyle = .light
    ) -> UIImage {
        let hostingController = UIHostingController(rootView: view)
        return render(controller: hostingController, config: config, style: style)
    }
}
#endif
