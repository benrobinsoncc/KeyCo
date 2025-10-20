import UIKit
import WebKit

class KeyboardViewController: UIInputViewController {

    // MARK: - Properties

    // Mode system
    private enum KeyboardMode {
        case home
        case reply
        case rewrite
        case google
        case chatgpt
    }

    private enum KeyboardHeight: CGFloat {
        case small = 250
        case large = 650
    }

    private var currentMode: KeyboardMode = .home
    private var currentHeight: KeyboardHeight = .small

    // UI Components
    private var heightConstraint: NSLayoutConstraint!
    private var containerView: UIView!
    private var contentArea: UIView!
    // Content views for each mode
    private var homeView: UIView!
    private var replyView: UIView!
    private var rewriteView: UIView!
    private var googleView: UIView!
    private var chatgptView: UIView!

    private var replyContainer: ActionContainerView!
    private var rewriteContainer: ActionContainerView!
    private var googleContainer: ActionContainerView!
    private var chatgptContainer: ActionContainerView!
    private var googleWebView: WKWebView?
    private var currentGoogleURL: URL?

    private let containerMargin: CGFloat = 3
    private let cornerRadius: CGFloat = 20
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Restore state first
        restoreState()

        // Setup UI
        setupKeyboard()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        persistState()
    }

    // MARK: - Setup

    private func setupKeyboard() {
        // Set background
        view.backgroundColor = .clear

        // Set initial height
        heightConstraint = view.heightAnchor.constraint(equalToConstant: containerHeight(for: currentHeight))
        heightConstraint.priority = .required
        heightConstraint.isActive = true

        // Setup container
        setupContainer()

        // Setup content area
        setupContentArea()

        // Setup all mode views
        setupHomeView()
        setupReplyView()
        setupRewriteView()
        setupGoogleView()
        setupChatGPTView()

        // Show initial mode
        updateModeVisibility()
        if currentMode == .google {
            currentHeight = .large
            updateHeight(animated: false)
            loadGoogleSearchFromContext()
            updateContainerExpansionState()
        }
    }

    private func setupContainer() {
        containerView = UIView()
        containerView.backgroundColor = .systemGray4
        containerView.layer.cornerRadius = cornerRadius
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.topAnchor, constant: containerMargin),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: containerMargin),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -containerMargin),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -containerMargin)
        ])
    }

    private func setupContentArea() {
        contentArea = UIView()
        contentArea.backgroundColor = .clear
        contentArea.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(contentArea)

        NSLayoutConstraint.activate([
            contentArea.topAnchor.constraint(equalTo: containerView.topAnchor),
            contentArea.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            contentArea.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            contentArea.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }

    private func setupHomeView() {
        homeView = UIView()
        homeView.backgroundColor = .clear
        homeView.translatesAutoresizingMaskIntoConstraints = false
        contentArea.addSubview(homeView)

        NSLayoutConstraint.activate([
            homeView.topAnchor.constraint(equalTo: contentArea.topAnchor),
            homeView.leadingAnchor.constraint(equalTo: contentArea.leadingAnchor),
            homeView.trailingAnchor.constraint(equalTo: contentArea.trailingAnchor),
            homeView.bottomAnchor.constraint(equalTo: contentArea.bottomAnchor)
        ])

        // Create 2x2 grid of buttons
        let spacing: CGFloat = 2
        let padding: CGFloat = 3

        // Reply button (top-left)
        let replyButton = createActionButton(title: "Reply", color: .systemBlue)
        replyButton.addTarget(self, action: #selector(replyTapped), for: .touchUpInside)
        homeView.addSubview(replyButton)

        // Rewrite button (top-right)
        let rewriteButton = createActionButton(title: "Rewrite", color: .systemGreen)
        rewriteButton.addTarget(self, action: #selector(rewriteTapped), for: .touchUpInside)
        homeView.addSubview(rewriteButton)

        // Google button (bottom-left)
        let googleButton = createActionButton(title: "Google", color: .systemOrange)
        googleButton.addTarget(self, action: #selector(googleTapped), for: .touchUpInside)
        homeView.addSubview(googleButton)

        // ChatGPT button (bottom-right)
        let chatgptButton = createActionButton(title: "ChatGPT", color: .systemPurple)
        chatgptButton.addTarget(self, action: #selector(chatgptTapped), for: .touchUpInside)
        homeView.addSubview(chatgptButton)

        NSLayoutConstraint.activate([
            // Reply (top-left)
            replyButton.topAnchor.constraint(equalTo: homeView.topAnchor, constant: padding),
            replyButton.leadingAnchor.constraint(equalTo: homeView.leadingAnchor, constant: padding),
            // Rewrite (top-right)
            rewriteButton.topAnchor.constraint(equalTo: homeView.topAnchor, constant: padding),
            rewriteButton.trailingAnchor.constraint(equalTo: homeView.trailingAnchor, constant: -padding),

            // Google (bottom-left)
            googleButton.bottomAnchor.constraint(equalTo: homeView.bottomAnchor, constant: -padding),
            googleButton.leadingAnchor.constraint(equalTo: homeView.leadingAnchor, constant: padding),

            // ChatGPT (bottom-right)
            chatgptButton.bottomAnchor.constraint(equalTo: homeView.bottomAnchor, constant: -padding),
            chatgptButton.trailingAnchor.constraint(equalTo: homeView.trailingAnchor, constant: -padding),

            // Horizontal spacing
            rewriteButton.leadingAnchor.constraint(equalTo: replyButton.trailingAnchor, constant: spacing),
            chatgptButton.leadingAnchor.constraint(equalTo: googleButton.trailingAnchor, constant: spacing),

            // Vertical spacing
            googleButton.topAnchor.constraint(equalTo: replyButton.bottomAnchor, constant: spacing),
            chatgptButton.topAnchor.constraint(equalTo: rewriteButton.bottomAnchor, constant: spacing)
        ])

        // Equal sizing to keep grid uniform
        replyButton.widthAnchor.constraint(equalTo: rewriteButton.widthAnchor).isActive = true
        replyButton.widthAnchor.constraint(equalTo: googleButton.widthAnchor).isActive = true
        replyButton.widthAnchor.constraint(equalTo: chatgptButton.widthAnchor).isActive = true

        replyButton.heightAnchor.constraint(equalTo: replyButton.widthAnchor).isActive = true
        rewriteButton.heightAnchor.constraint(equalTo: rewriteButton.widthAnchor).isActive = true
        googleButton.heightAnchor.constraint(equalTo: googleButton.widthAnchor).isActive = true
        chatgptButton.heightAnchor.constraint(equalTo: chatgptButton.widthAnchor).isActive = true

        replyButton.heightAnchor.constraint(equalTo: googleButton.heightAnchor).isActive = true
        rewriteButton.heightAnchor.constraint(equalTo: chatgptButton.heightAnchor).isActive = true
    }

    private func createActionButton(title: String, color: UIColor) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.backgroundColor = color
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 16
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }

    private func setupReplyView() {
        replyView = UIView()
        replyView.backgroundColor = .clear
        replyView.translatesAutoresizingMaskIntoConstraints = false
        contentArea.addSubview(replyView)

        NSLayoutConstraint.activate([
            replyView.topAnchor.constraint(equalTo: contentArea.topAnchor),
            replyView.leadingAnchor.constraint(equalTo: contentArea.leadingAnchor),
            replyView.trailingAnchor.constraint(equalTo: contentArea.trailingAnchor),
            replyView.bottomAnchor.constraint(equalTo: contentArea.bottomAnchor)
        ])

        replyContainer = createActionContainer(
            title: "Reply Mode",
            buttonConfigs: [
                .init(style: .icon(symbolName: "xmark", accessibilityLabel: "Cancel"), action: { [weak self] in
                    self?.switchToMode(.home, height: .small)
                }),
                .init(style: .text(title: "Generate", symbolName: "sparkles", isPrimary: true), action: { [weak self] in
                    self?.handlePlaceholderAction(named: "Generate Reply")
                })
            ]
        )
        replyView.addSubview(replyContainer)
        pinContainer(replyContainer, to: replyView)
    }

    private func setupRewriteView() {
        rewriteView = UIView()
        rewriteView.backgroundColor = .clear
        rewriteView.translatesAutoresizingMaskIntoConstraints = false
        contentArea.addSubview(rewriteView)

        NSLayoutConstraint.activate([
            rewriteView.topAnchor.constraint(equalTo: contentArea.topAnchor),
            rewriteView.leadingAnchor.constraint(equalTo: contentArea.leadingAnchor),
            rewriteView.trailingAnchor.constraint(equalTo: contentArea.trailingAnchor),
            rewriteView.bottomAnchor.constraint(equalTo: contentArea.bottomAnchor)
        ])

        rewriteContainer = createActionContainer(
            title: "Rewrite Mode",
            buttonConfigs: [
                .init(style: .icon(symbolName: "xmark", accessibilityLabel: "Cancel"), action: { [weak self] in
                    self?.switchToMode(.home, height: .small)
                }),
                .init(style: .text(title: "Generate", symbolName: "sparkles", isPrimary: true), action: { [weak self] in
                    self?.handlePlaceholderAction(named: "Generate Rewrite")
                })
            ]
        )
        rewriteView.addSubview(rewriteContainer)
        pinContainer(rewriteContainer, to: rewriteView)
    }

    private func setupGoogleView() {
        googleView = UIView()
        googleView.backgroundColor = .clear
        googleView.translatesAutoresizingMaskIntoConstraints = false
        contentArea.addSubview(googleView)

        NSLayoutConstraint.activate([
            googleView.topAnchor.constraint(equalTo: contentArea.topAnchor),
            googleView.leadingAnchor.constraint(equalTo: contentArea.leadingAnchor),
            googleView.trailingAnchor.constraint(equalTo: contentArea.trailingAnchor),
            googleView.bottomAnchor.constraint(equalTo: contentArea.bottomAnchor)
        ])

        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.defaultWebpagePreferences.preferredContentMode = .mobile
        let webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        googleWebView = webView

        googleContainer = createActionContainer(
            title: nil,
            contentView: webView,
            buttonConfigs: [
                .init(style: .icon(symbolName: "xmark", accessibilityLabel: "Cancel"), action: { [weak self] in
                    self?.switchToMode(.home, height: .small)
                }),
                .init(style: .icon(symbolName: "arrow.clockwise", accessibilityLabel: "Reload"), action: { [weak self] in
                    self?.reloadGoogle()
                }),
                .init(style: .text(title: "Open", symbolName: "safari", isPrimary: false), action: { [weak self] in
                    self?.openGoogleResult()
                }),
                .init(style: .text(title: "Insert", symbolName: "arrow.up", isPrimary: true), action: { [weak self] in
                    self?.insertGoogleResult()
                })
            ],
            showsToggle: false,
            contentInsets: .zero
        )
        googleView.addSubview(googleContainer)
        pinContainer(googleContainer, to: googleView)
    }

    private func setupChatGPTView() {
        chatgptView = UIView()
        chatgptView.backgroundColor = .clear
        chatgptView.translatesAutoresizingMaskIntoConstraints = false
        contentArea.addSubview(chatgptView)

        NSLayoutConstraint.activate([
            chatgptView.topAnchor.constraint(equalTo: contentArea.topAnchor),
            chatgptView.leadingAnchor.constraint(equalTo: contentArea.leadingAnchor),
            chatgptView.trailingAnchor.constraint(equalTo: contentArea.trailingAnchor),
            chatgptView.bottomAnchor.constraint(equalTo: contentArea.bottomAnchor)
        ])

        chatgptContainer = createActionContainer(
            title: "ChatGPT Mode",
            buttonConfigs: [
                .init(style: .icon(symbolName: "xmark", accessibilityLabel: "Cancel"), action: { [weak self] in
                    self?.switchToMode(.home, height: .small)
                }),
                .init(style: .icon(symbolName: "arrow.clockwise", accessibilityLabel: "Reload"), action: { [weak self] in
                    self?.handlePlaceholderAction(named: "Reload ChatGPT")
                }),
                .init(style: .icon(symbolName: "doc.on.doc", accessibilityLabel: "Copy"), action: { [weak self] in
                    self?.handlePlaceholderAction(named: "Copy ChatGPT Output")
                }),
                .init(style: .text(title: "Insert", symbolName: "arrow.up", isPrimary: true), action: { [weak self] in
                    self?.handlePlaceholderAction(named: "Insert ChatGPT Output")
                })
            ]
        )
        chatgptView.addSubview(chatgptContainer)
        pinContainer(chatgptContainer, to: chatgptView)
    }

    // MARK: - Actions

    @objc private func replyTapped() {
        switchToMode(.reply, height: .small)
    }

    @objc private func rewriteTapped() {
        switchToMode(.rewrite, height: .small)
    }

    @objc private func googleTapped() {
        switchToMode(.google, height: .large)
    }

    @objc private func chatgptTapped() {
        switchToMode(.chatgpt, height: .small)
    }

    // MARK: - Mode Management

    private func switchToMode(_ mode: KeyboardMode, height: KeyboardHeight) {
        let previousMode = currentMode
        currentMode = mode

        let targetHeight: KeyboardHeight = mode == .google ? .large : height

        let shouldAnimateHeight: Bool
        if mode == .google {
            shouldAnimateHeight = false
        } else if previousMode == .google {
            shouldAnimateHeight = false
        } else {
            shouldAnimateHeight = true
        }

        if currentHeight != targetHeight {
            currentHeight = targetHeight
            updateHeight(animated: shouldAnimateHeight)
        } else if !shouldAnimateHeight {
            updateHeight(animated: false)
        }

        // Update UI
        updateModeVisibility()
        if mode == .google {
            loadGoogleSearchFromContext()
        }
        updateContainerExpansionState()
        persistState()
    }

    private func updateModeVisibility() {
        // Hide all views
        homeView.alpha = 0
        replyView.alpha = 0
        rewriteView.alpha = 0
        googleView.alpha = 0
        chatgptView.alpha = 0

        // Show current mode view
        switch currentMode {
        case .home:
            homeView.alpha = 1
        case .reply:
            replyView.alpha = 1
        case .rewrite:
            rewriteView.alpha = 1
        case .google:
            googleView.alpha = 1
        case .chatgpt:
            chatgptView.alpha = 1
        }
    }

    private func updateContainerExpansionState() {
        let isExpanded = currentHeight == .large
        replyContainer?.setExpanded(isExpanded)
        rewriteContainer?.setExpanded(isExpanded)
        googleContainer?.setExpanded(isExpanded)
        chatgptContainer?.setExpanded(isExpanded)
    }

    private func updateHeight(animated: Bool) {
        heightConstraint.constant = containerHeight(for: currentHeight)

        if animated {
            UIView.animate(
                withDuration: 0.3,
                delay: 0,
                usingSpringWithDamping: 0.8,
                initialSpringVelocity: 0.5,
                options: [.curveEaseInOut],
                animations: {
                    self.view.layoutIfNeeded()
                }
            )
        } else {
            view.layoutIfNeeded()
        }
    }

    // MARK: - State Persistence

    private func persistState() {
        let defaults = UserDefaults.standard

        let modeValue: Int
        switch currentMode {
        case .home: modeValue = 0
        case .reply: modeValue = 1
        case .rewrite: modeValue = 2
        case .google: modeValue = 3
        case .chatgpt: modeValue = 4
        }
        defaults.set(modeValue, forKey: "KeyCo_currentMode")
        defaults.set(currentHeight.rawValue, forKey: "KeyCo_currentHeight")
        defaults.synchronize()
    }

    private func restoreState() {
        let defaults = UserDefaults.standard

        // Restore mode
        if defaults.object(forKey: "KeyCo_currentMode") != nil {
            let modeValue = defaults.integer(forKey: "KeyCo_currentMode")
            switch modeValue {
            case 0: currentMode = .home
            case 1: currentMode = .reply
            case 2: currentMode = .rewrite
            case 3: currentMode = .google
            case 4: currentMode = .chatgpt
            default: currentMode = .home
            }
        }

        // Restore height
        if defaults.object(forKey: "KeyCo_currentHeight") != nil {
            let heightValue = defaults.double(forKey: "KeyCo_currentHeight")
            if abs(heightValue - KeyboardHeight.large.rawValue) < 0.5 || abs(heightValue - 500) < 0.5 {
                currentHeight = .large
            } else {
                currentHeight = .small
            }
        }

        if currentMode == .google {
            currentHeight = .large
        }

        updateContainerExpansionState()
    }

    // MARK: - Helpers

    private func createActionContainer(
        title: String?,
        contentView: UIView? = nil,
        buttonConfigs: [ActionContainerView.ActionButtonConfiguration],
        showsToggle: Bool = true,
        contentInsets: UIEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
    ) -> ActionContainerView {
        let container = ActionContainerView()
        if let contentView {
            container.setContentView(contentView)
        } else if let title {
            container.setContentView(createModePlaceholderContent(title: title))
        } else {
            container.setContentView(UIView())
        }
        let buttonTopSpacing: CGFloat = 12
        let dividerSpacing: CGFloat = contentInsets.bottom > 0 ? 12 : 0
        container.setContentLayout(
            insets: contentInsets,
            dividerSpacing: dividerSpacing,
            buttonTopSpacing: buttonTopSpacing,
            buttonSideInset: 12,
            buttonBottomInset: 12,
            buttonCornerRadius: 20
        )
        container.configureButtons(buttonConfigs)
        container.onToggle = showsToggle ? { [weak self] in
            self?.toggleHeight()
        } : nil
        container.setExpanded(currentHeight == .large)
        return container
    }

    private func pinContainer(_ container: UIView, to hostView: UIView) {
        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: hostView.leadingAnchor, constant: 3),
            container.trailingAnchor.constraint(equalTo: hostView.trailingAnchor, constant: -3),
            container.bottomAnchor.constraint(equalTo: hostView.bottomAnchor, constant: -3),
            container.topAnchor.constraint(equalTo: hostView.topAnchor, constant: 3)
        ])
    }

    private func containerHeight(for keyboardHeight: KeyboardHeight) -> CGFloat {
        keyboardHeight.rawValue + (containerMargin * 2)
    }

    private func createModePlaceholderContent(title: String) -> UIView {
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 20, weight: .semibold)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }

    // MARK: - Google Helpers

    private func loadGoogleSearchFromContext() {
        guard let webView = googleWebView else { return }
        let query = currentDocumentText()
        let url = googleURL(for: query)
        currentGoogleURL = url
        webView.load(URLRequest(url: url))
    }

    private func reloadGoogle() {
        guard let webView = googleWebView else { return }
        if webView.url == nil {
            loadGoogleSearchFromContext()
        } else {
            webView.reload()
        }
    }

    private func openGoogleResult() {
        guard let url = googleWebView?.url ?? currentGoogleURL else { return }
        DispatchQueue.main.async { [weak self] in
            self?.extensionContext?.open(url, completionHandler: nil)
        }
    }

    private func insertGoogleResult() {
        guard let url = googleWebView?.url ?? currentGoogleURL else { return }
        textDocumentProxy.insertText("\n\n\(url.absoluteString)\n\n")
    }

    private func currentDocumentText() -> String {
        let before = textDocumentProxy.documentContextBeforeInput ?? ""
        let after = textDocumentProxy.documentContextAfterInput ?? ""
        let combined = before + after
        return combined.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func googleURL(for query: String) -> URL {
        guard !query.isEmpty,
              let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://www.google.com/search?q=\(encoded)") else {
            return URL(string: "https://www.google.com/")!
        }
        return url
    }

    private func toggleHeight() {
        guard currentMode != .google else { return }
        let newHeight: KeyboardHeight = currentHeight == .small ? .large : .small
        currentHeight = newHeight
        updateHeight(animated: false)
        updateContainerExpansionState()
        persistState()
    }

    private func handlePlaceholderAction(named name: String) {
        NSLog("[KeyCoKeyboard] Action triggered: %@", name)
    }
}

extension KeyboardViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard let storedWebView = googleWebView, webView === storedWebView else { return }
        currentGoogleURL = webView.url
    }
}
