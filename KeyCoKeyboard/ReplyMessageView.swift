import UIKit

/// View for displaying pasted message or generated reply in Reply mode
final class ReplyMessageView: UIView {

    private let titleLabel = UILabel()
    private let scrollView = UIScrollView()
    private let messageLabel = UILabel()

    var message: String = "" {
        didSet {
            messageLabel.text = message
        }
    }

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

        // Title
        titleLabel.text = "REPLY"
        titleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        titleLabel.textColor = .systemGray
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)

        // Scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = true
        scrollView.alwaysBounceVertical = false
        addSubview(scrollView)

        // Message label
        messageLabel.font = .systemFont(ofSize: 16)
        messageLabel.textColor = .label
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(messageLabel)
    }

    private func setupLayout() {
        NSLayoutConstraint.activate([
            // Title at top
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),

            // Scroll view below title
            scrollView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            // Message label inside scroll view
            messageLabel.topAnchor.constraint(equalTo: scrollView.topAnchor),
            messageLabel.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            messageLabel.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            messageLabel.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            messageLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }
}
