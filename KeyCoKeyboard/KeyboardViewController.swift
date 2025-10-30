import UIKit
import WebKit

class KeyboardViewController: UIInputViewController {

    // MARK: - Properties

    // Mode system
    private enum KeyboardMode {
        case home
        case write
        case google
        case chatgpt
        case snippets
    }

    private enum KeyboardHeight: CGFloat {
        case small = 255  // Aligned with default UK English keyboard
        case large = 500
    }

    private var currentMode: KeyboardMode = .home
    private var currentHeight: KeyboardHeight = .small

    // UI Components
    private var heightConstraint: NSLayoutConstraint!
    private var containerView: UIView!
    private var contentArea: UIView!
    // Content views for each mode
    private var homeView: UIView!
    private var writeView: UIView!
    private var googleView: UIView!
    private var chatgptView: UIView!
    private var snippetsView: UIView!

    private var writeContainer: ActionContainerView!
    private var googleContainer: ActionContainerView!
    private var chatgptContainer: ActionContainerView!
    private var snippetsContainer: ActionContainerView!
    private var googleWebView: WKWebView?
    private var currentGoogleURL: URL?

    // Write mode components
    private var toneMapView: ToneMapView!
    private var messagePreviewLabel: UILabel!
    private var emptyStateLabel: UILabel!
    private var loadingIndicator: UIActivityIndicatorView!
    private var isWriting: Bool = false
    private var lastPosition: (x: Float, y: Float)?
    private var debounceTimer: Timer?
    private var originalText: String = ""
    private var currentTask: URLSessionDataTask?

    // ChatGPT content view
    private var chatgptContentView: ResponseContentView!
    private var snippetsContentView: SnippetsContentView!

    private let containerMargin: CGFloat = 3
    private let cornerRadius: CGFloat = 20

    // ChatGPT API - stored securely in Keychain
    private var chatGPTAPIKey: String? {
        return KeychainHelper.retrieveAPIKey()
    }
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Restore state first
        restoreState()

        // Setup UI
        setupKeyboard()
        
        // Add notification observer for app becoming active
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func appDidBecomeActive() {
        // When the app becomes active (user returns from Safari), force a complete refresh
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.forceKeyboardRefresh()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        persistState()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Force refresh when view appears
        DispatchQueue.main.async { [weak self] in
            self?.forceKeyboardRefresh()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Additional refresh after view appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.forceKeyboardRefresh()
        }
    }
    
    // MARK: - Keyboard Extension Lifecycle
    
    override func textWillChange(_ textInput: UITextInput?) {
        super.textWillChange(textInput)
        // Called when keyboard is about to become active
        forceKeyboardRefresh()
    }
    
    override func textDidChange(_ textInput: UITextInput?) {
        super.textDidChange(textInput)
        // Called when keyboard becomes active
        forceKeyboardRefresh()
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
        setupWriteView()
        setupGoogleView()
        setupChatGPTView()
        setupSnippetsView()

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

        // Create 2x2 grid of buttons (Write/Snippets on top, Google/ChatGPT bottom)
        let spacing: CGFloat = 8
        let padding: CGFloat = 3

        let writeButton = createActionButton(title: "Write", color: .white)
        writeButton.addTarget(self, action: #selector(writeTapped), for: .touchUpInside)
        homeView.addSubview(writeButton)

        let snippetsButton = createActionButton(title: "Paste", color: .white)
        snippetsButton.addTarget(self, action: #selector(snippetsTapped), for: .touchUpInside)
        homeView.addSubview(snippetsButton)

        let googleButton = createActionButton(title: "Google", color: .white)
        googleButton.addTarget(self, action: #selector(googleTapped), for: .touchUpInside)
        homeView.addSubview(googleButton)

        let chatgptButton = createActionButton(title: "ChatGPT", color: .white)
        chatgptButton.addTarget(self, action: #selector(chatgptTapped), for: .touchUpInside)
        homeView.addSubview(chatgptButton)

        NSLayoutConstraint.activate([
            // Top row
            writeButton.topAnchor.constraint(equalTo: homeView.topAnchor, constant: padding),
            writeButton.leadingAnchor.constraint(equalTo: homeView.leadingAnchor, constant: padding),
            snippetsButton.topAnchor.constraint(equalTo: homeView.topAnchor, constant: padding),
            snippetsButton.trailingAnchor.constraint(equalTo: homeView.trailingAnchor, constant: -padding),
            snippetsButton.leadingAnchor.constraint(equalTo: writeButton.trailingAnchor, constant: spacing),

            // Bottom row
            googleButton.bottomAnchor.constraint(equalTo: homeView.bottomAnchor, constant: -padding),
            googleButton.leadingAnchor.constraint(equalTo: homeView.leadingAnchor, constant: padding),
            chatgptButton.bottomAnchor.constraint(equalTo: homeView.bottomAnchor, constant: -padding),
            chatgptButton.trailingAnchor.constraint(equalTo: homeView.trailingAnchor, constant: -padding),
            chatgptButton.leadingAnchor.constraint(equalTo: googleButton.trailingAnchor, constant: spacing),

            // Vertical spacing between rows
            googleButton.topAnchor.constraint(equalTo: writeButton.bottomAnchor, constant: spacing),
            chatgptButton.topAnchor.constraint(equalTo: snippetsButton.bottomAnchor, constant: spacing)
        ])

        // Equal sizing
        writeButton.widthAnchor.constraint(equalTo: snippetsButton.widthAnchor).isActive = true
        googleButton.widthAnchor.constraint(equalTo: chatgptButton.widthAnchor).isActive = true
        writeButton.heightAnchor.constraint(equalTo: writeButton.widthAnchor).isActive = true
        snippetsButton.heightAnchor.constraint(equalTo: snippetsButton.widthAnchor).isActive = true
        googleButton.heightAnchor.constraint(equalTo: googleButton.widthAnchor).isActive = true
        chatgptButton.heightAnchor.constraint(equalTo: chatgptButton.widthAnchor).isActive = true
        // Ensure both rows keep equal heights even under constraint pressure
        googleButton.heightAnchor.constraint(equalTo: writeButton.heightAnchor).isActive = true
        chatgptButton.heightAnchor.constraint(equalTo: snippetsButton.heightAnchor).isActive = true
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

    private func setupWriteView() {
        writeView = UIView()
        writeView.backgroundColor = .clear
        writeView.translatesAutoresizingMaskIntoConstraints = false
        contentArea.addSubview(writeView)

        NSLayoutConstraint.activate([
            writeView.topAnchor.constraint(equalTo: contentArea.topAnchor),
            writeView.leadingAnchor.constraint(equalTo: contentArea.leadingAnchor),
            writeView.trailingAnchor.constraint(equalTo: contentArea.trailingAnchor),
            writeView.bottomAnchor.constraint(equalTo: contentArea.bottomAnchor)
        ])

        // Create container for write mode UI
        let writeContentView = UIView()
        writeContentView.backgroundColor = .clear
        writeContentView.translatesAutoresizingMaskIntoConstraints = false
        
        // Setup tone map
        toneMapView = ToneMapView()
        toneMapView.translatesAutoresizingMaskIntoConstraints = false
        
        // While dragging - just update coordinates (no API call)
        toneMapView.onPositionChanged = { [weak self] x, y in
            NSLog("[Write Mode] Dragging - x=\(x), y=\(y)")
            // Don't update preview label - tone map fills entire space now
        }
        
        // When released - trigger AI call immediately
        toneMapView.onGestureEnded = { [weak self] x, y in
            NSLog("[Write Mode] Gesture ended - calling AI with x=\(x), y=\(y)")
            
            let currentText = self?.currentDocumentText() ?? ""
            guard !currentText.isEmpty else {
                NSLog("[Write Mode] No text to rewrite")
                return
            }
            
            // Visual feedback is now shown in the tone map selector loading spinner
            
            // Call AI immediately
            self?.regenerateTextWithTone(tone: x, length: y, originalText: currentText)
        }
        
        writeContentView.addSubview(toneMapView)
        NSLog("[Write Mode] Tone map view initialized")
        
        // Setup message preview label
        messagePreviewLabel = UILabel()
        messagePreviewLabel.font = .systemFont(ofSize: 11, weight: .regular)
        messagePreviewLabel.textColor = .secondaryLabel
        messagePreviewLabel.textAlignment = .center
        messagePreviewLabel.numberOfLines = 4
        messagePreviewLabel.translatesAutoresizingMaskIntoConstraints = false
        writeContentView.addSubview(messagePreviewLabel)
        
        // Setup empty state label (hidden by default)
        emptyStateLabel = UILabel()
        emptyStateLabel.isHidden = true
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
        writeContentView.addSubview(emptyStateLabel)
        
        // Setup loading indicator
        loadingIndicator = UIActivityIndicatorView(style: .medium)
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.hidesWhenStopped = true
        writeContentView.addSubview(loadingIndicator)

        NSLayoutConstraint.activate([
            // Tone map with 1pt margin on all sides
            toneMapView.topAnchor.constraint(equalTo: writeContentView.topAnchor, constant: 1),
            toneMapView.leadingAnchor.constraint(equalTo: writeContentView.leadingAnchor, constant: 1),
            toneMapView.trailingAnchor.constraint(equalTo: writeContentView.trailingAnchor, constant: -1),
            toneMapView.bottomAnchor.constraint(equalTo: writeContentView.bottomAnchor),
            
            // Empty state label (centered, hidden by default)
            emptyStateLabel.centerXAnchor.constraint(equalTo: writeContentView.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: writeContentView.centerYAnchor),
            emptyStateLabel.leadingAnchor.constraint(equalTo: writeContentView.leadingAnchor, constant: 20),
            emptyStateLabel.trailingAnchor.constraint(equalTo: writeContentView.trailingAnchor, constant: -20),
            
            // Loading indicator centered on tone map
            loadingIndicator.centerXAnchor.constraint(equalTo: toneMapView.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: toneMapView.centerYAnchor),
            
            // Message preview label (hidden when tone map is shown, but still needs constraints)
            messagePreviewLabel.centerXAnchor.constraint(equalTo: writeContentView.centerXAnchor),
            messagePreviewLabel.centerYAnchor.constraint(equalTo: writeContentView.centerYAnchor),
            messagePreviewLabel.leadingAnchor.constraint(equalTo: writeContentView.leadingAnchor, constant: 12),
            messagePreviewLabel.trailingAnchor.constraint(equalTo: writeContentView.trailingAnchor, constant: -12)
        ])

        writeContainer = createActionContainer(
            title: nil,
            contentView: writeContentView,
            buttonConfigs: [
                .init(style: .icon(symbolName: "xmark", accessibilityLabel: "Cancel"), action: { [weak self] in
                    self?.switchToMode(.home, height: .small)
                }),
                .init(style: .icon(symbolName: "arrow.uturn.backward", accessibilityLabel: "Undo"), action: { [weak self] in
                    self?.undoWriteMode()
                }),
                .init(style: .spacer),
                .init(style: .text(title: "Done", symbolName: nil, isPrimary: false), action: { [weak self] in
                    self?.dismissWriteMode()
                })
            ],
            showsToggle: false,
            contentInsets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        )
        // Hide divider for write mode only
        writeContainer.setDividerHidden(true)
        writeView.addSubview(writeContainer)
        pinContainer(writeContainer, to: writeView)
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
                .init(style: .spacer),
                .init(style: .text(title: "Open", symbolName: "safari", isPrimary: false), action: { [weak self] in
                    self?.openGoogleResult()
                }),
                .init(style: .text(title: "Insert", symbolName: "arrow.up", isPrimary: false), action: { [weak self] in
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
            contentInsets: UIEdgeInsets(top: 0, left: 12, bottom: 12, right: 3)
        )
        chatgptView.addSubview(chatgptContainer)
        pinContainer(chatgptContainer, to: chatgptView)
    }

    private func setupSnippetsView() {
        snippetsView = UIView()
        snippetsView.backgroundColor = .clear
        snippetsView.translatesAutoresizingMaskIntoConstraints = false
        contentArea.addSubview(snippetsView)

        NSLayoutConstraint.activate([
            snippetsView.topAnchor.constraint(equalTo: contentArea.topAnchor),
            snippetsView.leadingAnchor.constraint(equalTo: contentArea.leadingAnchor),
            snippetsView.trailingAnchor.constraint(equalTo: contentArea.trailingAnchor),
            snippetsView.bottomAnchor.constraint(equalTo: contentArea.bottomAnchor)
        ])

        let content = SnippetsContentView()
        content.translatesAutoresizingMaskIntoConstraints = false
        content.onInsert = { [weak self] snippet in
            self?.insertSnippet(snippet)
        }
        content.onCopy = { [weak self] snippet in
            UIPasteboard.general.string = snippet.text
            self?.markSnippetUsed(snippet)
        }
        content.onAdd = { [weak self] in
            self?.presentAddSnippet()
        }
        content.onRename = { [weak self] snippet in
            self?.presentRename(snippet)
        }
        content.onDelete = { [weak self] snippet in
            self?.presentDelete(snippet)
        }
        // Pinning removed
        snippetsContentView = content

        snippetsContainer = createActionContainer(
            title: nil,
            contentView: content,
            buttonConfigs: [
                .init(style: .icon(symbolName: "xmark", accessibilityLabel: "Cancel"), action: { [weak self] in
                    self?.switchToMode(.home, height: .small)
                }),
                .init(style: .spacer),
                .init(style: .text(title: "Done", symbolName: nil, isPrimary: false), action: { [weak self] in
                    // Switch back to the default system keyboard
                    self?.advanceToNextInputMode()
                })
            ],
            showsToggle: true,
            contentInsets: UIEdgeInsets(top: 0, left: 14, bottom: 12, right: 12)
        )
        snippetsView.addSubview(snippetsContainer)
        pinContainer(snippetsContainer, to: snippetsView)
    }

    // MARK: - Snippets Actions
    private func presentAddSnippet() {
        // Keyboard extensions should avoid presenting alerts or text fields.
        // Use clipboard or current document text.
        let clipboard = UIPasteboard.general.string?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let docText = currentDocumentText()
        let text = !clipboard.isEmpty ? clipboard : docText
        guard !text.isEmpty else { return }
        let titleCandidate = text.split(separator: "\n").first.map(String.init) ?? text
        let title = String(titleCandidate.prefix(40))
        _ = SnippetsStore.shared.add(title: title, text: text)
        snippetsContentView.reloadData()
    }

    private func presentRename(_ snippet: Snippet) {
        // Rename from clipboard text only
        let candidate = UIPasteboard.general.string?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !candidate.isEmpty else { return }
        let newTitle = String(candidate.prefix(60))
        SnippetsStore.shared.rename(id: snippet.id, newTitle: newTitle)
        snippetsContentView.reloadData()
    }

    private func presentDelete(_ snippet: Snippet) {
        let alert = UIAlertController(title: "Delete Snippet", message: "This cannot be undone.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { [weak self] _ in
            SnippetsStore.shared.delete(id: snippet.id)
            self?.snippetsContentView.reloadData()
        }))
        present(alert, animated: true)
    }

    private func insertSnippet(_ snippet: Snippet) {
        // Simple insertion; could add heuristics for newlines if desired
        textDocumentProxy.insertText(snippet.text)
    }

    private func markSnippetUsed(_ snippet: Snippet) {
        // No-op: keep ordering stable, do not resort on insert
    }

    // MARK: - Actions

    @objc private func writeTapped() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        switchToMode(.write, height: .small)
        
        // Delay update to ensure views are rendered
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.updateWriteViewState()
        }
    }

    @objc private func googleTapped() {
        switchToMode(.google, height: .large)
    }

    @objc private func chatgptTapped() {
        switchToMode(.chatgpt, height: .small)
        queryChatGPT()
    }

    @objc private func snippetsTapped() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        switchToMode(.snippets, height: .small)
        // Ensure latest data
        snippetsContentView?.reloadData()
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
        writeView.alpha = 0
        googleView.alpha = 0
        chatgptView.alpha = 0
        snippetsView.alpha = 0

        // Show current mode view
        switch currentMode {
        case .home:
            homeView.alpha = 1
        case .write:
            writeView.alpha = 1
        case .google:
            googleView.alpha = 1
        case .chatgpt:
            chatgptView.alpha = 1
        case .snippets:
            snippetsView.alpha = 1
        }
    }

    private func updateContainerExpansionState() {
        let isExpanded = currentHeight == .large
        writeContainer?.setExpanded(isExpanded)
        googleContainer?.setExpanded(isExpanded)
        chatgptContainer?.setExpanded(isExpanded)
        snippetsContainer?.setExpanded(isExpanded)
    }

    private func updateHeight(animated: Bool) {
        let newHeight = containerHeight(for: currentHeight)
        heightConstraint.constant = newHeight
        
        // Force the view controller to recognize the new size
        view.setNeedsLayout()
        
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
        case .write: modeValue = 1
        case .google: modeValue = 2
        case .chatgpt: modeValue = 3
        case .snippets: modeValue = 4
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
            case 1: currentMode = .write
            case 2: currentMode = .google
            case 3: currentMode = .chatgpt
            case 4: currentMode = .snippets
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
    
    private func forceKeyboardRefresh() {
        NSLog("[KeyCo] Force refreshing keyboard extension")
        
        // Force complete layout refresh
        let targetHeight = containerHeight(for: currentHeight)
        
        // Update height constraint
        heightConstraint?.constant = targetHeight
        
        // Force all views to update their layouts
        view.setNeedsLayout()
        view.layoutIfNeeded()
        
        // Update container states
        updateContainerExpansionState()
        
        // Force the input view to recognize the new size
        if let inputView = view.superview {
            inputView.setNeedsLayout()
            inputView.layoutIfNeeded()
        }
        
        // Additional refresh after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }
            
            // Force another layout pass
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
            
            // Update mode visibility to ensure everything is correct
            self.updateModeVisibility()
            
            NSLog("[KeyCo] Keyboard refresh completed")
        }
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
        let buttonTopSpacing: CGFloat = 8
        let dividerSpacing: CGFloat = 0
        container.setContentLayout(
            insets: contentInsets,
            dividerSpacing: dividerSpacing,
            buttonTopSpacing: buttonTopSpacing,
            buttonSideInset: 12,
            buttonBottomInset: 8,
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

        // Try multiple methods to open the URL
        
        // Method 1: Try using responder chain to get to UIApplication
        var responder: UIResponder? = self
        while responder != nil {
            if let application = responder as? UIApplication {
                application.open(url, options: [:]) { success in
                    NSLog("[KeyCo] UIApplication.open result: %@", success ? "SUCCESS" : "FAILED")
                }
                return
            }
            responder = responder?.next
        }
        
        // Method 2: Try using selector-based approach (works in some iOS versions)
        let selector = NSSelectorFromString("openURL:")
        var openResponder: UIResponder? = self
        while openResponder != nil {
            if openResponder?.responds(to: selector) == true {
                openResponder?.perform(selector, with: url)
                NSLog("[KeyCo] Opened URL via responder chain")
                return
            }
            openResponder = openResponder?.next
        }
        
        // Method 3: Try extensionContext.open as fallback
        if let context = extensionContext {
            context.open(url) { success in
                NSLog("[KeyCo] extensionContext.open result: %@", success ? "SUCCESS" : "FAILED")
                if !success {
                    // If opening fails, copy URL to clipboard as final fallback
                    DispatchQueue.main.async {
                        UIPasteboard.general.string = url.absoluteString
                        NSLog("[KeyCo] Copied URL to clipboard as fallback: %@", url.absoluteString)
                    }
                }
            }
        } else {
            // No extension context, copy to clipboard
            UIPasteboard.general.string = url.absoluteString
            NSLog("[KeyCo] No extension context, copied URL to clipboard: %@", url.absoluteString)
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

    // MARK: - Write Mode Helpers
    
    private func updateWriteViewState() {
        guard let previewLabel = messagePreviewLabel, let emptyLabel = emptyStateLabel, let toneMap = toneMapView else { 
            NSLog("[Write Mode] Cannot update state - views not ready")
            return
        }

        let text = currentDocumentText()
        NSLog("[Write Mode] Current text from document: '\(text)'")
        
        if text.isEmpty {
            // Empty state
            previewLabel.isHidden = true
            emptyLabel.isHidden = false
            toneMap.isEnabled = false
            toneMap.alpha = 0.3
            originalText = ""
            NSLog("[Write Mode] Text is empty - showing empty state")
        } else {
            // Active state - tone map fills entire space
            originalText = text
            previewLabel.isHidden = true
            emptyLabel.isHidden = true
            toneMap.isEnabled = true
            toneMap.alpha = 1.0
            NSLog("[Write Mode] Text captured: '\(originalText)' - tone map enabled")
        }
    }
    
    
    private func regenerateTextWithTone(tone: Float, length: Float, originalText: String? = nil) {
        let textToUse = originalText ?? self.originalText
        
        NSLog("[Write Mode] regenerateTextWithTone called with tone=\(tone), length=\(length), text: '\(textToUse)'")
        
        guard !textToUse.isEmpty else {
            NSLog("[Write Mode] Cannot regenerate - text is empty")
            return
        }
        
        // Cancel any existing API task
        currentTask?.cancel()
        
        NSLog("[Write Mode] Starting AI regeneration for text: '\(textToUse)'")
        isWriting = true
        
        // Show spinner in the selector knob
        DispatchQueue.main.async { [weak self] in
            self?.toneMapView?.setLoading(true)
        }
        
        // Visual feedback is shown via the loading spinner in the tone map selector
        
        // Add a configuration with extended timeout and logging
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        let session = URLSession(configuration: config)
        
        // Build prompt based on position with explicit constraints
        let toneDescription = describeTone(tone)
        let lengthDescription = describeLength(length)
        let (maxWords, maxSentences) = getLengthConstraints(length)
        
        let prompt = """
        Rewrite the following message with STRICTLY the following requirements:
        
        TONE: \(toneDescription)
        LENGTH: \(lengthDescription)
        
        CRITICAL CONSTRAINTS:
        - Maximum word count: \(maxWords) words
        - Maximum sentences: \(maxSentences)
        - You MUST stay within these limits
        - Do not include any explanations, just the rewritten message
        - Preserve the core meaning and intent
        
        Original message: \(textToUse)
        
        Rewritten message (strictly within limits):
        """

        // Make API request
        guard let apiKey = chatGPTAPIKey else {
            handleWriteError("API key not configured. Please set it in Keychain.")
            return
        }
        
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            handleWriteError("Invalid URL")
            return
        }
        
        NSLog("[Write Mode] URL: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        // Calculate dynamic max_tokens based on length
        // Brief responses need fewer tokens, detailed need more
        let maxTokens = calculateMaxTokens(for: length)
        
        let requestBody: [String: Any] = [
            "model": "gpt-3.5-turbo",  // Using cheaper model
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "max_tokens": maxTokens
        ]

        guard let httpBody = try? JSONSerialization.data(withJSONObject: requestBody) else {
            handleWriteError("Failed to create request")
            return
        }

        request.httpBody = httpBody

        NSLog("[Write Mode] Creating URLSession task with URL: \(request.url?.absoluteString ?? "nil")")

        let task = session.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                // Clear the current task reference
                self?.currentTask = nil
                
                guard let self = self else { return }
                
                self.isWriting = false
                
                // Hide spinner in selector knob
                self.toneMapView?.setLoading(false)

                NSLog("[Write Mode] Response received. Error: \(error?.localizedDescription ?? "none"), Data: \(data != nil ? "present" : "nil")")

                if let error = error {
                    // Ignore cancellation errors
                    if (error as NSError).code != NSURLErrorCancelled {
                        NSLog("[Write Mode] Network error: \(error.localizedDescription)")
                        self.handleWriteError(error.localizedDescription)
                    }
                    return
                }

                guard let data = data else {
                    self.handleWriteError("No data received")
                    return
                }

                // Log the raw response for debugging
                if let rawString = String(data: data, encoding: .utf8) {
                    NSLog("[Write Mode] Raw API response: \(rawString)")
                }

                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        NSLog("[Write Mode] Parsed JSON keys: \(json.keys)")
                        
                        // Check for API errors first
                        if let error = json["error"] as? [String: Any],
                           let errorMessage = error["message"] as? String {
                            NSLog("[Write Mode] API Error: \(errorMessage)")
                            self.handleWriteError("API Error: \(errorMessage)")
                            return
                        }
                        
                        if let choices = json["choices"] as? [[String: Any]],
                           let firstChoice = choices.first {
                            NSLog("[Write Mode] First choice: \(firstChoice)")
                            
                            if let message = firstChoice["message"] as? [String: Any],
                       let content = message["content"] as? String {
                                let newText = content.trimmingCharacters(in: .whitespacesAndNewlines)
                                NSLog("[Write Mode] Got AI response: '\(newText)'")
                                
                                // Try to replace text
                                self.replaceTextFieldContent(with: newText)
                    } else {
                                NSLog("[Write Mode] Failed to parse message or content")
                                self.handleWriteError("Invalid message format")
                            }
                        } else {
                            NSLog("[Write Mode] Failed to parse choices")
                            self.handleWriteError("Invalid choices format")
                        }
                    } else {
                        NSLog("[Write Mode] Failed to parse JSON")
                        self.handleWriteError("Invalid JSON format")
                    }
                } catch {
                    NSLog("[Write Mode] JSON parsing error: \(error)")
                    self.handleWriteError("Failed to parse response: \(error.localizedDescription)")
                }
            }
        }

        currentTask = task
        task.resume()
    }

    private func describeTone(_ value: Float) -> String {
        // X-axis: 0 = Friendly/Casual (left), 1 = Formal (right)
        // Use smooth interpolation for more granular control
        if value < 0.15 {
            return "very casual and friendly, use contractions like 'you're' and 'I'll', keep it conversational"
        } else if value < 0.35 {
            return "friendly and warm, conversational but slightly more polished"
        } else if value < 0.50 {
            return "professional yet approachable, balanced between friendly and formal"
        } else if value < 0.70 {
            return "professional and clear, use standard business language"
        } else if value < 0.85 {
            return "formal and professional, avoid contractions, use proper business etiquette"
        } else {
            return "very formal and professional, use formal language, avoid casual expressions entirely"
        }
    }
    
    private func describeLength(_ value: Float) -> String {
        // Y-axis: 0 = Detailed (top), 1 = Brief (bottom)
        // Provide clearer instructions with specific constraints
        if value < 0.20 {
            return "detailed and comprehensive - include all important points and context"
        } else if value < 0.40 {
            return "moderately detailed - include key points with some context"
        } else if value < 0.60 {
            return "concise and focused - include only essential information"
        } else if value < 0.80 {
            return "brief and to-the-point - essential information only, no extra details"
        } else {
            return "extremely brief - absolute minimum words, single thought only"
        }
    }
    
    /// Returns (maxWords, maxSentences) based on length value
    private func getLengthConstraints(_ value: Float) -> (Int, Int) {
        // Y-axis: 0 = Detailed (top), 1 = Brief (bottom)
        if value < 0.20 {
            return (100, 3)  // Detailed: up to 100 words, 3 sentences
        } else if value < 0.40 {
            return (60, 2)   // Moderately detailed: up to 60 words, 2 sentences
        } else if value < 0.60 {
            return (40, 2)   // Concise: up to 40 words, 2 sentences
        } else if value < 0.80 {
            return (25, 1)   // Brief: up to 25 words, 1 sentence
        } else {
            return (15, 1)   // Extremely brief: up to 15 words, 1 sentence
        }
    }
    
    /// Calculates max_tokens based on length preference
    private func calculateMaxTokens(for length: Float) -> Int {
        // Scale tokens: brief responses need fewer tokens, detailed need more
        // Base calculation: roughly 4 characters per token, plus some buffer
        let (maxWords, _) = getLengthConstraints(length)
        // Average word length ~5 chars, so: maxWords * 5 / 4 = tokens
        // Add 50% buffer for safety, then round up
        let calculated = Int(Double(maxWords) * 5.0 / 4.0 * 1.5)
        // Ensure reasonable bounds
        return min(max(calculated, 30), 200)  // Between 30 and 200 tokens
    }
    
    private func handleWriteError(_ message: String) {
        NSLog("[KeyCoKeyboard] Write error: %@", message)
        messagePreviewLabel?.text = "Error: \(message)"
        messagePreviewLabel?.textColor = .systemRed
    }
    
    private func replaceTextFieldContent(with newText: String) {
        NSLog("[Write Mode] ════════════════════════════════")
        NSLog("[Write Mode] REPLACING TEXT - '\(newText)'")
        NSLog("[Write Mode] ════════════════════════════════")
        
        // Get current text BEFORE deletion
        let beforeText = textDocumentProxy.documentContextBeforeInput ?? ""
        let afterText = textDocumentProxy.documentContextAfterInput ?? ""
        let totalTextBefore = beforeText + afterText
        
        NSLog("[Write Mode] BEFORE: '\(totalTextBefore)' (before: \(beforeText.count), after: \(afterText.count))")
        
        // Clear all text by calling deleteBackward enough times
        let totalCharsToDelete = totalTextBefore.count
        NSLog("[Write Mode] Deleting all \(totalCharsToDelete) characters")
        
        for i in 0..<totalCharsToDelete {
            textDocumentProxy.deleteBackward()
            if (i + 1) % 20 == 0 || i == totalCharsToDelete - 1 {
                NSLog("[Write Mode] Deleted \(i + 1)/\(totalCharsToDelete) chars")
            }
        }
        
        NSLog("[Write Mode] All text cleared, now inserting new text")
        
        // Insert new text
        textDocumentProxy.insertText(newText)
        
        // Verify immediately
        let verifyBefore = textDocumentProxy.documentContextBeforeInput ?? ""
        let verifyAfter = textDocumentProxy.documentContextAfterInput ?? ""
        let verifyText = verifyBefore + verifyAfter
        
        NSLog("[Write Mode] AFTER: '\(verifyText)'")
        
        if verifyText == newText {
            NSLog("[Write Mode] ✓ SUCCESS - Text replaced correctly!")
        } else {
            NSLog("[Write Mode] ✗ FAILED - Expected '\(newText)' but got '\(verifyText)'")
        }
        
        // Text replacement feedback is handled by the tone map loading state
    }
    
    private func undoWriteMode() {
        guard !originalText.isEmpty else {
            NSLog("[Write Mode] No original text to undo")
            return
        }
        
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        // Restore original text
        replaceTextFieldContent(with: originalText)
        
        NSLog("[Write Mode] Undo - restored original text: '\(originalText)'")
    }
    
    
    private func dismissWriteMode() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        // Dismiss keyboard extension and return to default keyboard
        advanceToNextInputMode()
        
        NSLog("[Write Mode] Dismissed - returning to default keyboard")
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
        guard let apiKey = chatGPTAPIKey else {
            chatgptContentView.responseText = "Error: API key not configured. Please set it in Keychain."
            return
        }
        
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
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
}

// MARK: - WKWebView Delegate

extension KeyboardViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard let storedWebView = googleWebView, webView === storedWebView else { return }
        currentGoogleURL = webView.url
    }
}

