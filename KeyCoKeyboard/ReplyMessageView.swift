import UIKit
import SwiftUI

/// View for displaying pasted message or generated reply in Reply mode
final class ReplyMessageView: UIView {

    private let titleLabel = UILabel()
    private let scrollView = UIScrollView()
    private let messageLabel = UILabel()
    private var shimmerHostingController: UIHostingController<ShimmerLoadingText>?
    private let shimmerContainer = UIView()

    var message: String = "" {
        didSet {
            messageLabel.text = message
            updateShimmerState()
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

        // Shimmer container (for Loading... state)
        shimmerContainer.translatesAutoresizingMaskIntoConstraints = false
        shimmerContainer.backgroundColor = .clear
        shimmerContainer.isHidden = true
        scrollView.addSubview(shimmerContainer)

        // Setup SwiftUI shimmer view
        let shimmerView = ShimmerLoadingText()
        let hosting = UIHostingController(rootView: shimmerView)
        hosting.view.backgroundColor = .clear
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        shimmerHostingController = hosting
        shimmerContainer.addSubview(hosting.view)
    }

    private func setupLayout() {
        guard let shimmerHostingView = shimmerHostingController?.view else { return }

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
            messageLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            // Shimmer container (same position as message label)
            shimmerContainer.topAnchor.constraint(equalTo: scrollView.topAnchor),
            shimmerContainer.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            shimmerContainer.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            shimmerContainer.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            // Shimmer hosting view fills container
            shimmerHostingView.topAnchor.constraint(equalTo: shimmerContainer.topAnchor),
            shimmerHostingView.leadingAnchor.constraint(equalTo: shimmerContainer.leadingAnchor),
            shimmerHostingView.trailingAnchor.constraint(equalTo: shimmerContainer.trailingAnchor),
            shimmerHostingView.bottomAnchor.constraint(equalTo: shimmerContainer.bottomAnchor)
        ])
    }

    private func updateShimmerState() {
        let isLoading = message == "Loading..."
        shimmerContainer.isHidden = !isLoading
        messageLabel.isHidden = isLoading
    }
}

// MARK: - SwiftUI Shimmer Loading View

struct ShimmerLoadingText: View {
    var body: some View {
        Text("Loading...")
            .font(.system(size: 16))
            .foregroundColor(.black)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .opacity(0.6)
    }
}
