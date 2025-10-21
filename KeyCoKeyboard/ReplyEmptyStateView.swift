import UIKit

/// Empty state view for Reply mode showing clipboard icon and instructions
final class ReplyEmptyStateView: UIView {

    private let headerLabel = UILabel()
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let stackView = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        backgroundColor = .clear

        // Header
        headerLabel.text = "REPLY"
        headerLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        headerLabel.textColor = .systemGray
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(headerLabel)

        // Icon
        iconImageView.image = UIImage(systemName: "doc.on.clipboard")
        iconImageView.tintColor = .systemGray
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.setContentHuggingPriority(.required, for: .vertical)

        // Title
        titleLabel.text = "Get a smart reply"
        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        // Subtitle
        subtitleLabel.text = "Copy a message, then tap Paste"
        subtitleLabel.font = .systemFont(ofSize: 13, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        // Stack view
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(iconImageView)
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(subtitleLabel)
        stackView.setCustomSpacing(4, after: titleLabel)

        addSubview(stackView)
    }

    private func setupLayout() {
        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: topAnchor),
            headerLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),

            iconImageView.widthAnchor.constraint(equalToConstant: 32),
            iconImageView.heightAnchor.constraint(equalToConstant: 32),

            stackView.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 16),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -16),
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])
    }
}
