import UIKit
import SwiftUI
import AnimateText

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

            // SwiftUI hosting view inside container with padding
            hostingView.topAnchor.constraint(equalTo: responseContainer.topAnchor),
            hostingView.leadingAnchor.constraint(equalTo: responseContainer.leadingAnchor, constant: 4),
            hostingView.trailingAnchor.constraint(equalTo: responseContainer.trailingAnchor, constant: -4),
            hostingView.bottomAnchor.constraint(equalTo: responseContainer.bottomAnchor)
        ])
    }

    // MARK: - Update

    private func updateAnimatedText(_ text: String) {
        let shouldAnimate = !text.isEmpty && text != "Loading..."

        // Force recreation of the view with a unique ID to trigger animation on each update
        let newView = AnimatedResponseText(
            text: text,
            shouldAnimate: shouldAnimate,
            id: UUID()
        )
        hostingController?.rootView = newView

        // Force layout update to ensure wrapping works
        hostingController?.view.setNeedsLayout()
        hostingController?.view.layoutIfNeeded()
    }
}

// MARK: - SwiftUI Animated Text View

struct AnimatedResponseText: View {
    let text: String
    var shouldAnimate: Bool = false
    let id: UUID

    @State private var displayText: String = ""

    var body: some View {
        AnimateText<FastBlurEffect>($displayText, type: .letters)
            .font(.system(size: 16))
            .foregroundColor(Color(uiColor: .label))
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .fixedSize(horizontal: false, vertical: true)
            .id(id) // Use ID to force SwiftUI to recreate the view
            .onAppear {
                // Reset and set text to trigger animation
                displayText = ""
                if shouldAnimate {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        displayText = text
                    }
                } else {
                    displayText = text
                }
            }
    }
}
