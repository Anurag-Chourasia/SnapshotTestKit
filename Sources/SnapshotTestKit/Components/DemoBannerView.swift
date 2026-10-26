#if canImport(UIKit)
import UIKit

/// A sample UIKit component demonstrating Light, Dark, and Accessibility snapshot testing.
public final class DemoBannerView: UIView {
    public let iconImageView = UIImageView()
    public let titleLabel = UILabel()
    public let messageLabel = UILabel()
    public let actionButton = UIButton(type: .system)

    public init(
        title: String = "Accessibility Notice",
        message: String = "Verified with SnapshotTestingKit accessibility renderer for VoiceOver indicators on iOS 26.5.",
        actionTitle: String = "Dismiss"
    ) {
        super.init(frame: .zero)
        setupUI(title: title, message: message, actionTitle: actionTitle)
        setupAccessibility(title: title, message: message, actionTitle: actionTitle)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI(title: String, message: String, actionTitle: String) {
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 12
        layer.borderWidth = 1
        layer.borderColor = UIColor.separator.cgColor
        layer.masksToBounds = true

        iconImageView.image = UIImage(systemName: "bell.badge.fill")
        iconImageView.tintColor = .systemOrange
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.text = title
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        messageLabel.text = message
        messageLabel.font = .preferredFont(forTextStyle: .subheadline)
        messageLabel.textColor = .secondaryLabel
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false

        actionButton.setTitle(actionTitle, for: .normal)
        actionButton.titleLabel?.font = .preferredFont(forTextStyle: .subheadline)
        actionButton.translatesAutoresizingMaskIntoConstraints = false

        addSubview(iconImageView)
        addSubview(titleLabel)
        addSubview(messageLabel)
        addSubview(actionButton)

        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            iconImageView.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            iconImageView.widthAnchor.constraint(equalToConstant: 28),
            iconImageView.heightAnchor.constraint(equalToConstant: 28),

            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),

            messageLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            messageLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),

            actionButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            actionButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 12),
            actionButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
        ])
    }

    private func setupAccessibility(title: String, message: String, actionTitle: String) {
        isAccessibilityElement = false

        iconImageView.isAccessibilityElement = true
        iconImageView.accessibilityLabel = "Notification alert"
        iconImageView.accessibilityTraits = .image

        titleLabel.isAccessibilityElement = true
        titleLabel.accessibilityTraits = .header

        messageLabel.isAccessibilityElement = true

        actionButton.isAccessibilityElement = true
        actionButton.accessibilityTraits = .button
        actionButton.accessibilityHint = "Double tap to dismiss this alert"

        accessibilityElements = [iconImageView, titleLabel, messageLabel, actionButton]
    }
}
#endif
