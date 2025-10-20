import UIKit

/// Content view for displaying mode title and response text
final class ResponseContentView: UIView {

    // MARK: - Properties

    private let titleLabel = UILabel()
    private let responseLabel = UILabel()
    private let scrollView = UIScrollView()
    private let responseContainer = UIView()

    var title: String = "" {
        didSet {
            titleLabel.text = title
        }
    }

    var responseText: String = "" {
        didSet {
            responseLabel.text = responseText

            // Animate blur-in effect for new content
            if !responseText.isEmpty && responseText != "Loading..." {
                animateBlurIn()
            }
        }
    }

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupViews() {
        backgroundColor = .clear

        // Setup title label (fixed, not scrollable)
        titleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        titleLabel.textColor = .systemGray
        titleLabel.numberOfLines = 1
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)

        // Setup scroll view (only for response)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = true
        scrollView.alwaysBounceVertical = true
        addSubview(scrollView)

        // Setup response container
        responseContainer.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(responseContainer)

        // Setup response label
        responseLabel.font = .systemFont(ofSize: 16, weight: .regular)
        responseLabel.textColor = .label
        responseLabel.numberOfLines = 0
        responseLabel.translatesAutoresizingMaskIntoConstraints = false
        responseContainer.addSubview(responseLabel)
    }

    private func setupLayout() {
        NSLayoutConstraint.activate([
            // Title label at the top with padding
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),

            // Scroll view below title, extends to bottom (no gap)
            scrollView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            // Response container inside scroll view
            responseContainer.topAnchor.constraint(equalTo: scrollView.topAnchor),
            responseContainer.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            responseContainer.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            responseContainer.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            responseContainer.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            // Response label inside container with padding
            responseLabel.topAnchor.constraint(equalTo: responseContainer.topAnchor),
            responseLabel.leadingAnchor.constraint(equalTo: responseContainer.leadingAnchor, constant: 4),
            responseLabel.trailingAnchor.constraint(equalTo: responseContainer.trailingAnchor, constant: -4),
            responseLabel.bottomAnchor.constraint(equalTo: responseContainer.bottomAnchor)
        ])
    }

    // MARK: - Animation

    private func animateBlurIn() {
        // Create a blur view container
        let blurContainer = UIVisualEffectView(effect: nil)
        blurContainer.frame = responseLabel.bounds
        blurContainer.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurContainer.clipsToBounds = true
        responseLabel.insertSubview(blurContainer, at: 0)

        // Start with blur and fade in
        responseLabel.alpha = 0

        // Animate blur to clear and fade in text
        UIView.animate(withDuration: 0.8, delay: 0, options: [.curveEaseOut], animations: {
            blurContainer.effect = UIBlurEffect(style: .regular)
        }, completion: { _ in
            // Fade in the text while fading out the blur
            UIView.animate(withDuration: 0.6, delay: 0.1, options: [.curveEaseInOut], animations: {
                self.responseLabel.alpha = 1
                blurContainer.alpha = 0
            }, completion: { _ in
                blurContainer.removeFromSuperview()
            })
        })
    }
}
