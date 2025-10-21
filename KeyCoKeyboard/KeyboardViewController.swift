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
        case large = 800
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

    // Reply mode views
    private var replyEmptyStateView: ReplyEmptyStateView!
    private var replyMessageView: ReplyMessageView!
    private var replyCurrentStep: ReplyStep = .empty
    private var replySettings = ReplySettings()
    private var pastedMessage: String = ""

    private let replySentimentOptions = ["Positive", "Neutral", "Negative"]
    private let replyToneOptions = ["Professional", "Casual", "Friendly"]
    private let replyLengthOptions = ["Short", "Medium", "Long"]

    private enum ReplyStep {
        case empty
        case preview
        case generated
    }

    private struct ReplySettings {
        var sentiment: String = "Neutral"
        var tone: String = "Professional"
        var length: String = "Medium"
    }

    // Response content views
    private var rewriteContentView: ResponseContentView!
    private var chatgptContentView: ResponseContentView!

    private let containerMargin: CGFloat = 3
    private let cornerRadius: CGFloat = 20

    // ChatGPT API
    private let chatGPTAPIKey = "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"
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
        containerView.backgroundColor = .clear
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
        let spacing: CGFloat = 8
        let padding: CGFloat = 3

        // Reply button (top-left)
        let replyButton = createActionButton(title: "Reply", color: .white)
        replyButton.addTarget(self, action: #selector(replyTapped), for: .touchUpInside)
        homeView.addSubview(replyButton)

        // Rewrite button (top-right)
        let rewriteButton = createActionButton(title: "Rewrite", color: .white)
        rewriteButton.addTarget(self, action: #selector(rewriteTapped), for: .touchUpInside)
        homeView.addSubview(rewriteButton)

        // Google button (bottom-left)
        let googleButton = createActionButton(title: "Google", color: .white)
        googleButton.addTarget(self, action: #selector(googleTapped), for: .touchUpInside)
        homeView.addSubview(googleButton)

        // ChatGPT button (bottom-right)
        let chatgptButton = createActionButton(title: "ChatGPT", color: .white)
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
        button.setTitleColor(.label, for: .normal)
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

        // Create empty state view
        replyEmptyStateView = ReplyEmptyStateView()

        // Create message view for preview and generated reply
        replyMessageView = ReplyMessageView()

        // Initially show empty state (Step 1)
        replyContainer = createActionContainer(
            title: nil,
            contentView: replyEmptyStateView,
            buttonConfigs: replyInitialButtons(),
            showsToggle: true,
            contentInsets: UIEdgeInsets(top: 12, left: 12, bottom: 0, right: 12)
        )
        replyView.addSubview(replyContainer)
        pinContainer(replyContainer, to: replyView)
    }

    private func replyInitialButtons() -> [ActionContainerView.ActionButtonConfiguration] {
        [
            .init(style: .icon(symbolName: "xmark", accessibilityLabel: "Cancel"), action: { [weak self] in
                self?.cancelReplyFlow()
            }),
            .init(style: .text(title: "Paste", symbolName: nil, isPrimary: true), action: { [weak self] in
                self?.handleReplyPaste()
            })
        ]
    }

    private func resetReplyFlow() {
        replyCurrentStep = .empty
        replySettings = ReplySettings()
        pastedMessage = ""
        replyMessageView.message = ""

        guard replyContainer != nil else { return }
        replyContainer.setContentView(replyEmptyStateView)
        replyContainer.configureButtons(replyInitialButtons())
    }

    private func cancelReplyFlow() {
        resetReplyFlow()
        switchToMode(.home, height: .small)
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

        // Create response content view
        rewriteContentView = ResponseContentView()
        rewriteContentView.title = "REWRITE"
        rewriteContentView.responseText = ""

        rewriteContainer = createActionContainer(
            title: nil,
            contentView: rewriteContentView,
            buttonConfigs: [
                .init(style: .icon(symbolName: "xmark", accessibilityLabel: "Cancel"), action: { [weak self] in
                    self?.switchToMode(.home, height: .small)
                }),
                .init(style: .text(title: "Generate", symbolName: "sparkles", isPrimary: true), action: { [weak self] in
                    self?.handlePlaceholderAction(named: "Generate Rewrite")
                })
            ],
            showsToggle: true,
            contentInsets: UIEdgeInsets(top: 12, left: 12, bottom: 0, right: 12)
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

        // Create response content view
        chatgptContentView = ResponseContentView()
        chatgptContentView.title = "CHATGPT"
        chatgptContentView.responseText = ""

        chatgptContainer = createActionContainer(
            title: nil,
            contentView: chatgptContentView,
            buttonConfigs: [
                .init(style: .icon(symbolName: "xmark", accessibilityLabel: "Cancel"), action: { [weak self] in
                    self?.switchToMode(.home, height: .small)
                }),
                .init(style: .icon(symbolName: "arrow.clockwise", accessibilityLabel: "Reload"), action: { [weak self] in
                    self?.reloadChatGPT()
                }),
                .init(style: .icon(symbolName: "doc.on.doc", accessibilityLabel: "Copy"), action: { [weak self] in
                    self?.copyChatGPTOutput()
                }),
                .init(style: .text(title: "Insert", symbolName: "arrow.up", isPrimary: true), action: { [weak self] in
                    self?.insertChatGPTOutput()
                })
            ],
            showsToggle: true,
            contentInsets: UIEdgeInsets(top: 12, left: 12, bottom: 0, right: 12)
        )
        chatgptView.addSubview(chatgptContainer)
        pinContainer(chatgptContainer, to: chatgptView)
    }

    // MARK: - Actions

    @objc private func replyTapped() {
        resetReplyFlow()
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
        queryChatGPT()
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
            if abs(heightValue - KeyboardHeight.large.rawValue) < 0.5 {
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
        let dividerSpacing: CGFloat = 0
        container.setContentLayout(
            insets: contentInsets,
            dividerSpacing: dividerSpacing,
            buttonTopSpacing: buttonTopSpacing,
            buttonSideInset: 12,
            buttonBottomInset: 12,
            buttonCornerRadius: 16
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
        guard let url = googleWebView?.url ?? currentGoogleURL else {
            NSLog("[KeyCo] No URL available to open")
            return
        }

        NSLog("[KeyCo] Attempting to open URL: %@", url.absoluteString)

        // Check if extensionContext exists
        guard let context = extensionContext else {
            NSLog("[KeyCo] Extension context is nil")
            return
        }

        // Try to open the URL
        context.open(url) { success in
            NSLog("[KeyCo] Open URL result: %@", success ? "SUCCESS" : "FAILED")
            if !success {
                // If opening fails, copy URL to clipboard as fallback
                DispatchQueue.main.async {
                    UIPasteboard.general.string = url.absoluteString
                    NSLog("[KeyCo] Copied URL to clipboard: %@", url.absoluteString)
                }
            }
        }
    }

    private func insertGoogleResult() {
        guard let url = googleWebView?.url ?? currentGoogleURL else { return }
        textDocumentProxy.insertText("\n\n\(url.absoluteString)")
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

    // MARK: - ChatGPT Helpers

    private func queryChatGPT() {
        let query = currentDocumentText()
        guard !query.isEmpty else {
            chatgptContentView.responseText = "No text to query. Type something first."
            return
        }

        chatgptContentView.responseText = "Loading..."

        // Make API request
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(chatGPTAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody: [String: Any] = [
            "model": "gpt-4",
            "messages": [
                ["role": "user", "content": query]
            ],
            "max_tokens": 500
        ]

        guard let httpBody = try? JSONSerialization.data(withJSONObject: requestBody) else {
            chatgptContentView.responseText = "Error: Failed to create request"
            return
        }

        request.httpBody = httpBody

        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }

                if let error = error {
                    self.chatgptContentView.responseText = "Error: \(error.localizedDescription)"
                    NSLog("[KeyCo] ChatGPT API error: %@", error.localizedDescription)
                    return
                }

                guard let data = data else {
                    self.chatgptContentView.responseText = "Error: No data received"
                    return
                }

                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let choices = json["choices"] as? [[String: Any]],
                       let firstChoice = choices.first,
                       let message = firstChoice["message"] as? [String: Any],
                       let content = message["content"] as? String {
                        self.chatgptContentView.responseText = content.trimmingCharacters(in: .whitespacesAndNewlines)
                    } else {
                        // Try to parse error response
                        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let error = json["error"] as? [String: Any],
                           let message = error["message"] as? String {
                            self.chatgptContentView.responseText = "API Error: \(message)"
                            NSLog("[KeyCo] ChatGPT API error: %@", message)
                        } else {
                            self.chatgptContentView.responseText = "Error: Invalid response format"
                        }
                    }
                } catch {
                    self.chatgptContentView.responseText = "Error: Failed to parse response"
                    NSLog("[KeyCo] ChatGPT parse error: %@", error.localizedDescription)
                }
            }
        }

        task.resume()
    }

    private func reloadChatGPT() {
        queryChatGPT()
    }

    private func copyChatGPTOutput() {
        let text = chatgptContentView.responseText
        guard !text.isEmpty, text != "Loading...", !text.hasPrefix("Error:") else { return }
        UIPasteboard.general.string = text
        NSLog("[KeyCo] Copied ChatGPT output to clipboard")
    }

    private func insertChatGPTOutput() {
        let text = chatgptContentView.responseText
        guard !text.isEmpty, text != "Loading...", !text.hasPrefix("Error:") else { return }
        textDocumentProxy.insertText("\n\n\(text)")
    }

    // MARK: - Reply Mode Handlers

    private func handleReplyPaste() {
        // Read clipboard
        guard let clipboardText = UIPasteboard.general.string, !clipboardText.isEmpty else {
            // Show error in content area
            showReplyEmptyClipboardError()
            return
        }

        pastedMessage = clipboardText
        replyCurrentStep = .preview
        showReplyPreview()
    }

    private func showReplyEmptyClipboardError() {
        // Create error view (reuse empty state but with error message)
        let errorView = UIView()
        errorView.backgroundColor = .clear

        let label = UILabel()
        label.text = "Clipboard is empty. Copy a message first."
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.textColor = .systemRed
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        errorView.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: errorView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: errorView.centerYAnchor),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: errorView.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(lessThanOrEqualTo: errorView.trailingAnchor, constant: -20)
        ])

        replyContainer.setContentView(errorView)

        // Reset back to empty state after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.replyContainer.setContentView(self!.replyEmptyStateView)
        }
    }

    private func showReplyPreview() {
        // Show Step 2: message preview with settings buttons
        replyMessageView.message = pastedMessage

        replyCurrentStep = .preview

        replyContainer.setContentView(replyMessageView)
        replyContainer.configureButtons([
            .init(style: .icon(symbolName: "xmark", accessibilityLabel: "Cancel"), action: { [weak self] in
                self?.cancelReplyFlow()
            }),
            .init(
                style: .text(title: replyFilterSummaryTitle(), symbolName: "chevron.down", isPrimary: false),
                menu: makeFilterMenu(),
                showsMenuAsPrimaryAction: true
            ),
            .init(style: .text(title: "Generate", symbolName: "sparkles", isPrimary: true), action: { [weak self] in
                self?.generateReply()
            })
        ])
    }

    private func makeFilterMenu() -> UIMenu {
        UIMenu(title: "Reply Style", children: [
            makeSentimentMenu(),
            makeLengthMenu(),
            makeToneMenu()
        ])
    }

    private func makeSentimentMenu() -> UIMenu {
        let actions = replySentimentOptions.map { option in
            UIAction(title: option, state: option == replySettings.sentiment ? .on : .off) { [weak self] _ in
                self?.setReplySentiment(option)
            }
        }
        return UIMenu(title: "Sentiment", options: .displayInline, children: actions)
    }

    private func makeToneMenu() -> UIMenu {
        let actions = replyToneOptions.map { option in
            UIAction(title: option, state: option == replySettings.tone ? .on : .off) { [weak self] _ in
                self?.setReplyTone(option)
            }
        }
        return UIMenu(title: "Tone", options: .displayInline, children: actions)
    }

    private func makeLengthMenu() -> UIMenu {
        let actions = replyLengthOptions.map { option in
            UIAction(title: option, state: option == replySettings.length ? .on : .off) { [weak self] _ in
                self?.setReplyLength(option)
            }
        }
        return UIMenu(title: "Length", options: .displayInline, children: actions)
    }

    private func replyFilterSummaryTitle() -> String {
        "\(replySettings.sentiment), \(replySettings.length), \(replySettings.tone)"
    }

    private func setReplySentiment(_ option: String) {
        replySettings.sentiment = option
        refreshReplyButtonsForCurrentStep()
    }

    private func setReplyTone(_ option: String) {
        replySettings.tone = option
        refreshReplyButtonsForCurrentStep()
    }

    private func setReplyLength(_ option: String) {
        replySettings.length = option
        refreshReplyButtonsForCurrentStep()
    }

    private func refreshReplyButtonsForCurrentStep() {
        switch replyCurrentStep {
        case .preview:
            showReplyPreview()
        case .generated:
            updateReplyGeneratedButtons()
        case .empty:
            replyContainer.configureButtons(replyInitialButtons())
        }
    }

    private func updateReplyGeneratedButtons() {
        // Helper to update buttons in Step 3 without regenerating
        replyContainer.configureButtons([
            .init(style: .icon(symbolName: "xmark", accessibilityLabel: "Cancel"), action: { [weak self] in
                self?.cancelReplyFlow()
            }),
            .init(
                style: .text(title: replyFilterSummaryTitle(), symbolName: "chevron.down", isPrimary: false),
                menu: makeFilterMenu(),
                showsMenuAsPrimaryAction: true
            ),
            .init(style: .icon(symbolName: "arrow.clockwise", accessibilityLabel: "Reload"), action: { [weak self] in
                self?.generateReply()
            }),
            .init(style: .text(title: "Insert", symbolName: "arrow.up", isPrimary: true), action: { [weak self] in
                self?.insertReply()
            })
        ])
    }

    private func generateReply() {
        // Show loading state
        replyMessageView.message = "Loading..."
        replyCurrentStep = .generated
        updateReplyGeneratedButtons()

        // Build prompt based on settings
        let lengthInstruction = switch replySettings.length {
        case "Short": "Keep your reply brief (1-2 sentences)."
        case "Long": "Write a detailed, thorough reply (4+ sentences)."
        default: "Write a medium-length reply (2-4 sentences)."
        }

        let sentimentInstruction = switch replySettings.sentiment {
        case "Positive": "Be positive, upbeat, and enthusiastic."
        case "Negative": "Be critical or express concerns appropriately."
        default: "Maintain a neutral, balanced tone."
        }

        let toneInstruction = switch replySettings.tone {
        case "Casual": "Use casual, relaxed language."
        case "Friendly": "Be warm, friendly, and personable."
        default: "Use professional, formal language."
        }

        let prompt = """
        Generate a reply to the following message. \(lengthInstruction) \(sentimentInstruction) \(toneInstruction)

        Message to reply to:
        \(pastedMessage)

        Reply:
        """

        // Make API request
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(chatGPTAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody: [String: Any] = [
            "model": "gpt-4",
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "max_tokens": 500
        ]

        guard let httpBody = try? JSONSerialization.data(withJSONObject: requestBody) else {
            replyMessageView.message = "Error: Failed to create request"
            return
        }

        request.httpBody = httpBody

        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }

                if let error = error {
                    self.replyMessageView.message = "Error: \(error.localizedDescription)"
                    NSLog("[KeyCo] Reply generation error: %@", error.localizedDescription)
                    return
                }

                guard let data = data else {
                    self.replyMessageView.message = "Error: No data received"
                    return
                }

                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let choices = json["choices"] as? [[String: Any]],
                       let firstChoice = choices.first,
                       let message = firstChoice["message"] as? [String: Any],
                       let content = message["content"] as? String {
                        self.replyMessageView.message = content.trimmingCharacters(in: .whitespacesAndNewlines)
                        self.showReplyGenerated()
                    } else {
                        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let error = json["error"] as? [String: Any],
                           let message = error["message"] as? String {
                            self.replyMessageView.message = "API Error: \(message)"
                            NSLog("[KeyCo] Reply generation API error: %@", message)
                        } else {
                            self.replyMessageView.message = "Error: Unexpected response format"
                        }
                    }
                } catch {
                    self.replyMessageView.message = "Error: Failed to parse response"
                    NSLog("[KeyCo] Reply generation parse error: %@", error.localizedDescription)
                }
            }
        }

        task.resume()
    }

    private func showReplyGenerated() {
        // Update buttons for Step 3: show Reload and Insert
        replyCurrentStep = .generated
        updateReplyGeneratedButtons()
    }

    private func insertReply() {
        let text = replyMessageView.message
        guard !text.isEmpty, text != "Loading...", !text.hasPrefix("Error:") else { return }
        textDocumentProxy.insertText(text)
        resetReplyFlow()
        switchToMode(.home, height: .small)
    }
}

extension KeyboardViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard let storedWebView = googleWebView, webView === storedWebView else { return }
        currentGoogleURL = webView.url
    }
}
