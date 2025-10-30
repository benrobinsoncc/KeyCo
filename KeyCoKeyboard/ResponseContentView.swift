import UIKit
import SwiftUI

/// Content view for displaying mode title and response text
final class ResponseContentView: UIView {

    // MARK: - Properties

    private let titleLabel = UILabel()
    private let scrollView = UIScrollView()
    private let responseContainer = UIView()
    private var hostingController: UIHostingController<AnimatedResponseText>?

    var title: String = "" {
        didSet {
            titleLabel.text = title
        }
    }

    var responseText: String = "" {
        didSet {
            updateAnimatedText(responseText)
        }
    }

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupLayout()

        // Allow compression so we don't push action bar down
        setContentHuggingPriority(.defaultLow, for: .vertical)
        setContentCompressionResistancePriority(.defaultLow - 1, for: .vertical)
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
        // Align text to top of label by removing baseline padding
        titleLabel.baselineAdjustment = .alignBaselines
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)

        // Setup response container directly (no scroll view - let parent handle scrolling)
        responseContainer.translatesAutoresizingMaskIntoConstraints = false
        addSubview(responseContainer)

        // Setup SwiftUI hosting controller for animated text
        let swiftUIView = AnimatedResponseText(text: "", shouldAnimate: false, id: UUID())
        let hosting = UIHostingController(rootView: swiftUIView)
        hosting.view.backgroundColor = UIColor.clear
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        hostingController = hosting
        responseContainer.addSubview(hosting.view)
    }

    private func setupLayout() {
        guard let hostingView = hostingController?.view else { return }

        NSLayoutConstraint.activate([
            // Title label at the very top - offset up by ~3pt to compensate for UILabel's text baseline padding
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: -3),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),

            // Response container directly below title - add back the offset so spacing is correct
            responseContainer.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 3),
            responseContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            responseContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            responseContainer.bottomAnchor.constraint(equalTo: bottomAnchor),

            // SwiftUI hosting view fills the container
            hostingView.topAnchor.constraint(equalTo: responseContainer.topAnchor),
            hostingView.leadingAnchor.constraint(equalTo: responseContainer.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: responseContainer.trailingAnchor),
            hostingView.bottomAnchor.constraint(equalTo: responseContainer.bottomAnchor)
        ])
    }

    // MARK: - Update

    private func updateAnimatedText(_ text: String) {
        let shouldAnimate = !text.isEmpty && text != "Loading..."

        // Force recreation of the view with a unique ID
        let newView = AnimatedResponseText(
            text: text,
            shouldAnimate: shouldAnimate,
            id: UUID()
        )
        hostingController?.rootView = newView

        // Force layout update
        hostingController?.view.setNeedsLayout()
        hostingController?.view.layoutIfNeeded()
    }
}

// MARK: - SwiftUI Animated Text View

struct AnimatedResponseText: View {
    let text: String
    var shouldAnimate: Bool = false
    let id: UUID

    var body: some View {
        ScrollView {
            Text(text)
                .font(.system(size: 16))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .padding(.top, 0)
                .opacity(text == "Loading..." ? 0.5 : 1.0)
        }
    }
}
