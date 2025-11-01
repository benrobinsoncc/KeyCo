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

        // Allow compression so we don't push action bar down
        setContentHuggingPriority(.defaultLow, for: .vertical)
        setContentCompressionResistancePriority(.defaultLow - 1, for: .vertical)
    }
    
    private var hasSetupConstraints = false
    private var hasLoggedLayout = false
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // DEBUG: Log actual layout once per view lifecycle
        if !hasLoggedLayout && frame.width > 0 && frame.height > 0 {
            hasLoggedLayout = true
            logLayoutFrames()
        }
    }
    
    override func updateConstraints() {
        if !hasSetupConstraints {
            hasSetupConstraints = true
            setupLayout()
        }
        super.updateConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupViews() {
        backgroundColor = .clear
        
        // Ensure layout margins don't interfere (matching PASTE mode approach)
        preservesSuperviewLayoutMargins = false
        layoutMargins = .zero

        // Setup title label (fixed, not scrollable) - matching PASTE mode style
        titleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        titleLabel.textColor = .systemGray
        titleLabel.numberOfLines = 1
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        // CRITICAL: Minimize height to prevent extra vertical space
        titleLabel.setContentHuggingPriority(.required, for: .vertical)
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
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

    private var hostingViewConstraintsSet = false
    
    private func setupLayout() {
        // Set up title label constraints first (matching PASTE mode exactly)
        // CRITICAL: Constrain height to font line height to prevent extra vertical space
        let font = titleLabel.font ?? .systemFont(ofSize: 13, weight: .semibold)
        let lineHeight = font.lineHeight
        let titleHeight = titleLabel.heightAnchor.constraint(equalToConstant: lineHeight)
        let titleTop = titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 14)
        let titleLeading = titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor)
        let titleTrailing = titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor)
        
        titleHeight.isActive = true
        titleTop.isActive = true
        titleLeading.isActive = true
        titleTrailing.isActive = true
        
        // Set up response container constraints (matching PASTE mode spacing)
        // CRITICAL: Ensure responseContainer fills remaining space to push header up
        let responseTop = responseContainer.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6)
        let responseLeading = responseContainer.leadingAnchor.constraint(equalTo: leadingAnchor)
        let responseTrailing = responseContainer.trailingAnchor.constraint(equalTo: trailingAnchor)
        let responseBottom = responseContainer.bottomAnchor.constraint(equalTo: bottomAnchor)
        
        responseTop.isActive = true
        responseLeading.isActive = true
        responseTrailing.isActive = true
        responseBottom.isActive = true
        
        // DEBUG: Log constraint setup
        NSLog("[ResponseContentView] Constraints set - titleLabel top: 14pt, responseContainer top: titleLabel.bottom + 6pt")
        
        // Set up hosting view constraints when available
        if let hostingView = hostingController?.view, !hostingViewConstraintsSet {
            hostingView.topAnchor.constraint(equalTo: responseContainer.topAnchor).isActive = true
            hostingView.leadingAnchor.constraint(equalTo: responseContainer.leadingAnchor).isActive = true
            hostingView.trailingAnchor.constraint(equalTo: responseContainer.trailingAnchor).isActive = true
            hostingView.bottomAnchor.constraint(equalTo: responseContainer.bottomAnchor).isActive = true
            hostingViewConstraintsSet = true
        }
        
        // DEBUG: Schedule layout logging after layout
        DispatchQueue.main.async { [weak self] in
            self?.logLayoutFrames()
        }
    }
    
    private func logLayoutFrames() {
        NSLog("[ResponseContentView] === LAYOUT DEBUG ===")
        NSLog("[ResponseContentView] Self frame: \(frame)")
        NSLog("[ResponseContentView] titleLabel frame: \(titleLabel.frame)")
        NSLog("[ResponseContentView] titleLabel height: \(titleLabel.frame.height)pt (font lineHeight: \(titleLabel.font.lineHeight)pt)")
        NSLog("[ResponseContentView] responseContainer frame: \(responseContainer.frame)")
        NSLog("[ResponseContentView] titleLabel top: \(titleLabel.frame.minY - frame.minY)pt from self.top")
        NSLog("[ResponseContentView] responseContainer top: \(responseContainer.frame.minY - frame.minY)pt from self.top")
        NSLog("[ResponseContentView] responseContainer height: \(responseContainer.frame.height)pt")
        NSLog("[ResponseContentView] Available space: \(frame.height - titleLabel.frame.maxY - 6)pt")
        NSLog("[ResponseContentView] ====================")
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

        // Ensure hosting view constraints are set up if they weren't before
        if let hostingView = hostingController?.view,
           hostingView.superview == responseContainer,
           !hostingViewConstraintsSet {
            hostingView.topAnchor.constraint(equalTo: responseContainer.topAnchor).isActive = true
            hostingView.leadingAnchor.constraint(equalTo: responseContainer.leadingAnchor).isActive = true
            hostingView.trailingAnchor.constraint(equalTo: responseContainer.trailingAnchor).isActive = true
            hostingView.bottomAnchor.constraint(equalTo: responseContainer.bottomAnchor).isActive = true
            hostingViewConstraintsSet = true
        }

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
