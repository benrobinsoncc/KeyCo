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
        case large = 650
    }
    
    private enum WritePreset {
        case fixGrammar
        case polishWriting
        case rephraseAsTweet
    }

    private var currentMode: KeyboardMode = .home
    private var currentHeight: KeyboardHeight = .small
    
    // Store the desired preferredContentSize
    private var _preferredContentSize: CGSize = CGSize(width: 0, height: 0)
    
    // Override preferredContentSize to ensure Google mode gets correct height
    override var preferredContentSize: CGSize {
        get {
            // If we have a stored value and we're in Google mode with large height, use it
            if currentMode == .google && currentHeight == .large && _preferredContentSize.height > 0 {
                return _preferredContentSize
            }
            // Otherwise use super's value or calculate
            if _preferredContentSize.height > 0 {
                return _preferredContentSize
            }
            return super.preferredContentSize
        }
        set {
            _preferredContentSize = newValue
            super.preferredContentSize = newValue
        }
    }

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
    private var googleBackButton: UIButton?
    private var googleForwardButton: UIButton?
    private var googleNavigationTransitionView: UIView?
    private var googleNavigationSnapshotView: UIView?
    private var isGoogleNavigating: Bool = false

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
    private var loadingTimeoutTimer: Timer?

    // ChatGPT content view
    private var chatgptContentView: ResponseContentView!
    private var chatgptCopyButton: UIButton?
    private var snippetsContentView: SnippetsContentView!

    private let containerMargin: CGFloat = 3
    private let cornerRadius: CGFloat = 20

    // Backend API configuration - API key is stored server-side
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Mark that keyboard extension is active (for onboarding detection)
        if let appGroupDefaults = UserDefaults(suiteName: "group.com.keyco") {
            appGroupDefaults.set("true", forKey: "__keyco_keyboard_extension_active__")
            appGroupDefaults.synchronize()
        }

        // Test network connectivity
        NetworkTestHelper.testConnectivity()
        
        // Proactively check backend health
        APIClient.checkBackendStatus { [weak self] isHealthy, errorMessage in
            if !isHealthy {
                NSLog("[KeyCo] Backend health check failed: \(errorMessage ?? "Unknown")")
                // Don't show error to user proactively - wait for them to try using it
                // This just helps us know if backend is down before they try
            }
        }
        
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
        
        // Add Darwin notification observer for snippet updates
        let notificationCenter = CFNotificationCenterGetDarwinNotifyCenter()
        let notificationName = SnippetsStore.snippetsUpdatedNotification.rawValue as CFString
        NSLog("[KeyCo] Registering Darwin notification observer for: \(SnippetsStore.snippetsUpdatedNotification.rawValue)")
        CFNotificationCenterAddObserver(
            notificationCenter,
            Unmanaged.passUnretained(self).toOpaque(),
            { (center, observer, name, object, userInfo) in
                guard let observer = observer else { return }
                let instance = Unmanaged<KeyboardViewController>.fromOpaque(observer).takeUnretainedValue()
                NSLog("[KeyCo] Darwin notification received for snippet update")
                // Small delay to allow UserDefaults to sync between processes
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    instance.reloadSnippets()
                }
            },
            notificationName,
            nil,
            .deliverImmediately
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        // Remove Darwin notification observer
        let notificationCenter = CFNotificationCenterGetDarwinNotifyCenter()
        let notificationName = CFNotificationName(SnippetsStore.snippetsUpdatedNotification.rawValue as CFString)
        CFNotificationCenterRemoveObserver(
            notificationCenter,
            Unmanaged.passUnretained(self).toOpaque(),
            notificationName,
            nil
        )
    }
    
    @objc private func appDidBecomeActive() {
        // When the app becomes active (user returns from Safari), ensure we're in home mode
        // and force a complete refresh to fix layout issues
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }
            
            // If we're in Google mode (user opened browser), switch back to home mode
            if self.currentMode == .google {
                NSLog("[KeyCo] appDidBecomeActive - Switching from Google mode to home mode")
                // Force height update first
                self.currentHeight = .small
                self.updateHeight(animated: false)
                // Then switch mode
                self.currentMode = .home
                self.updateModeVisibility()
            }
            
            // Force complete layout refresh with aggressive updates
            self.forceKeyboardRefresh()
            
            // Additional aggressive refresh after delay to ensure iOS picks up the changes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                guard let self = self else { return }
                self.forceAggressiveLayoutRefresh()
            }
        }
    }
    
    private func forceAggressiveLayoutRefresh() {
        NSLog("[KeyCo] Force aggressive layout refresh")
        
        // Ensure we're in home mode with small height
        if currentMode != .home {
            currentMode = .home
            updateModeVisibility()
        }
        if currentHeight != .small {
            currentHeight = .small
            updateHeight(animated: false)
        }
        
        // Force view bounds update
        let targetHeight = containerHeight(for: .small)
        let width = view.bounds.width > 0 ? view.bounds.width : UIScreen.main.bounds.width
        preferredContentSize = CGSize(width: width, height: targetHeight)
        heightConstraint?.constant = targetHeight
        
        // Force all views to update
        view.setNeedsUpdateConstraints()
        view.updateConstraintsIfNeeded()
        view.setNeedsLayout()
        view.layoutIfNeeded()
        
        // Force contentArea and homeView to update
        contentArea.setNeedsLayout()
        contentArea.layoutIfNeeded()
        homeView.setNeedsLayout()
        homeView.layoutIfNeeded()
        
        // Force input view to update
        if let inputView = view.superview {
            inputView.setNeedsUpdateConstraints()
            inputView.updateConstraintsIfNeeded()
            inputView.setNeedsLayout()
            inputView.layoutIfNeeded()
        }
        
        // Update mode visibility again
        updateModeVisibility()
        
        NSLog("[KeyCo] Aggressive layout refresh completed - view bounds: \(view.bounds), contentArea bounds: \(contentArea.bounds), homeView bounds: \(homeView.bounds)")
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Clean up any pending operations when keyboard disappears
        currentTask?.cancel()
        currentTask = nil
        loadingTimeoutTimer?.invalidate()
        loadingTimeoutTimer = nil
        toneMapView?.setLoading(false)
        // Reset selector when leaving write mode (so it's ready when returning)
        if currentMode == .write {
            toneMapView?.reset()
        }
        persistState()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Force refresh when view appears
        // If we're in snippets mode, reload from storage to get latest changes
        if currentMode == .snippets {
            NSLog("[KeyCo] viewWillAppear - reloading snippets from storage")
            SnippetsStore.shared.reload()
        }
        
        // Update preferredContentSize when view appears
        let targetHeight = containerHeight(for: currentHeight)
        let width = view.bounds.width > 0 ? view.bounds.width : UIScreen.main.bounds.width
        preferredContentSize = CGSize(width: width, height: targetHeight)
        NSLog("[KeyCo] viewWillAppear - Setting preferredContentSize to width: \(width), height: \(targetHeight)")
        
        DispatchQueue.main.async { [weak self] in
            self?.forceKeyboardRefresh()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // If we're returning from Google mode (after opening browser), ensure we're in home mode
        if currentMode == .google {
            NSLog("[KeyCo] viewDidAppear - Detected Google mode, switching to home mode")
            currentHeight = .small
            currentMode = .home
            updateModeVisibility()
        }
        
        // Update preferredContentSize when view appears - this is critical for iOS to recognize the height
        let targetHeight = containerHeight(for: currentHeight)
        let width = view.bounds.width > 0 ? view.bounds.width : UIScreen.main.bounds.width
        preferredContentSize = CGSize(width: width, height: targetHeight)
        heightConstraint?.constant = targetHeight
        NSLog("[KeyCo] viewDidAppear - Mode: \(currentMode), Setting preferredContentSize to width: \(width), height: \(targetHeight), actual view height: \(view.bounds.height), preferredContentSize after: \(preferredContentSize)")
        
        // Force immediate layout update
        view.setNeedsUpdateConstraints()
        view.updateConstraintsIfNeeded()
        view.setNeedsLayout()
        view.layoutIfNeeded()
        
        // For Google mode, aggressively force the height multiple times
        if currentMode == .google && currentHeight == .large {
            let googleHeight = containerHeight(for: .large)
            preferredContentSize = CGSize(width: width, height: googleHeight)
            heightConstraint?.constant = googleHeight
            view.setNeedsLayout()
            view.layoutIfNeeded()
            NSLog("[KeyCo] viewDidAppear(google) - Force setting preferredContentSize to height: \(googleHeight)")
            
            // Force another update after delays to ensure iOS picks it up
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                guard let self = self, self.currentMode == .google, self.currentHeight == .large else { return }
                let width = self.view.bounds.width > 0 ? self.view.bounds.width : UIScreen.main.bounds.width
                self.preferredContentSize = CGSize(width: width, height: googleHeight)
                self.heightConstraint?.constant = googleHeight
                self.view.setNeedsLayout()
                self.view.layoutIfNeeded()
            }
        } else if currentMode == .home {
            // For home mode, ensure layout is properly refreshed
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                guard let self = self, self.currentMode == .home else { return }
                self.forceAggressiveLayoutRefresh()
            }
        }
        
        // Additional refresh after view appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.forceKeyboardRefresh()
        }
    }
    
    // MARK: - Keyboard Extension Lifecycle
    
    override func textWillChange(_ textInput: UITextInput?) {
        // Set preferredContentSize BEFORE calling super - this is critical
        let targetHeight = containerHeight(for: currentHeight)
        let width = view.bounds.width > 0 ? view.bounds.width : UIScreen.main.bounds.width
        super.preferredContentSize = CGSize(width: width, height: targetHeight)
        heightConstraint?.constant = targetHeight
        
        super.textWillChange(textInput)
        
        NSLog("[KeyCo] textWillChange - Mode: \(currentMode), Height: \(currentHeight.rawValue), Set preferredContentSize to height: \(targetHeight)")
        forceKeyboardRefresh()
    }
    
    override func textDidChange(_ textInput: UITextInput?) {
        // Set preferredContentSize BEFORE calling super - this is critical
        let targetHeight = containerHeight(for: currentHeight)
        let width = view.bounds.width > 0 ? view.bounds.width : UIScreen.main.bounds.width
        super.preferredContentSize = CGSize(width: width, height: targetHeight)
        heightConstraint?.constant = targetHeight
        
        super.textDidChange(textInput)
        
        NSLog("[KeyCo] textDidChange - Mode: \(currentMode), Height: \(currentHeight.rawValue), Set preferredContentSize to height: \(targetHeight)")
        
        // For Google mode, force another update after a brief delay
        if currentMode == .google && currentHeight == .large {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                guard let self = self, self.currentMode == .google, self.currentHeight == .large else { return }
                let googleHeight = self.containerHeight(for: .large)
                let width = self.view.bounds.width > 0 ? self.view.bounds.width : UIScreen.main.bounds.width
                self.preferredContentSize = CGSize(width: width, height: googleHeight)
                self.heightConstraint?.constant = googleHeight
                self.view.setNeedsLayout()
                self.view.layoutIfNeeded()
                NSLog("[KeyCo] textDidChange(google) - Delayed preferredContentSize update to height: \(googleHeight)")
            }
        }
        
        forceKeyboardRefresh()
    }
    

    // MARK: - Setup

    private func setupKeyboard() {
        // Set background
        view.backgroundColor = .clear

        // Set initial height
        let initialHeight = containerHeight(for: currentHeight)
        
        // Set initial height constraint
        heightConstraint = view.heightAnchor.constraint(equalToConstant: initialHeight)
        heightConstraint.priority = .required
        heightConstraint.isActive = true
        
        // Set preferredContentSize so iOS recognizes the keyboard height
        let width = view.bounds.width > 0 ? view.bounds.width : UIScreen.main.bounds.width
        preferredContentSize = CGSize(width: width, height: initialHeight)
        NSLog("[KeyCo] setupKeyboard - Setting preferredContentSize to width: \(width), height: \(initialHeight)")

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
        let spacing: CGFloat = 6
        let padding: CGFloat = 3

        // Use dynamic color that matches the selector background (same as action bar background)
        let tileColor = UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor.secondarySystemBackground : UIColor.systemBackground
        }
        
        let writeButton = createActionButton(title: "Write", color: tileColor)
        writeButton.addTarget(self, action: #selector(writeTapped), for: .touchUpInside)
        homeView.addSubview(writeButton)

        let snippetsButton = createActionButton(title: "Snippets", color: tileColor)
        snippetsButton.addTarget(self, action: #selector(snippetsTapped), for: .touchUpInside)
        homeView.addSubview(snippetsButton)

        let googleButton = createActionButton(title: "Google", color: tileColor)
        googleButton.addTarget(self, action: #selector(googleTapped), for: .touchUpInside)
        homeView.addSubview(googleButton)

        let chatgptButton = createActionButton(title: "ChatGPT", color: tileColor)
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
        // Uppercase title to match CHATGPT header style
        button.setTitle(title.uppercased(), for: .normal)
        // Match CHATGPT header font (13pt, semibold)
        button.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
        button.backgroundColor = color
        // Black text color
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
        toneMapView.onPositionChanged = { x, y in
            NSLog("[Write Mode] Dragging - x=\(x), y=\(y)")
            // Don't update preview label - tone map fills entire space now
        }
        
        // When released - trigger AI call immediately
        toneMapView.onGestureEnded = { [weak self] x, y in
            NSLog("[Write Mode] Gesture ended - calling AI with x=\(x), y=\(y)")
            
            let currentText = self?.currentDocumentText() ?? ""
            guard !currentText.isEmpty else {
                NSLog("[Write Mode] No text to rewrite")
                // Hide status label - only show errors
                self?.messagePreviewLabel?.isHidden = true
                return
            }
            
            // Hide status label - only show errors
            self?.messagePreviewLabel?.isHidden = true
            
            // Call AI immediately
            self?.regenerateTextWithTone(tone: x, length: y, originalText: currentText)
        }
        
        writeContentView.addSubview(toneMapView)
        NSLog("[Write Mode] Tone map view initialized")
        
        // Setup message preview label (hidden by default, only shown for errors)
        messagePreviewLabel = UILabel()
        messagePreviewLabel.font = .systemFont(ofSize: 11, weight: .regular)
        messagePreviewLabel.textColor = .secondaryLabel
        messagePreviewLabel.textAlignment = .center
        messagePreviewLabel.numberOfLines = 4
        messagePreviewLabel.isHidden = true  // Hidden by default, only show errors
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
            // Max width constraint to prevent overlap with axis labels (Friendly/Formal on left/right)
            // Labels are 8pt padding + 70pt width = 78pt from each edge, so max width should account for this
            messagePreviewLabel.centerXAnchor.constraint(equalTo: writeContentView.centerXAnchor),
            messagePreviewLabel.centerYAnchor.constraint(equalTo: writeContentView.centerYAnchor),
            messagePreviewLabel.widthAnchor.constraint(lessThanOrEqualTo: writeContentView.widthAnchor, multiplier: 0.6),
            messagePreviewLabel.leadingAnchor.constraint(greaterThanOrEqualTo: writeContentView.leadingAnchor, constant: 85),
            messagePreviewLabel.trailingAnchor.constraint(lessThanOrEqualTo: writeContentView.trailingAnchor, constant: -85)
        ])

        // Create presets menu (iOS displays bottom-to-top, so reverse order)
        let presetsMenu = UIMenu(title: "", children: [
            UIAction(title: "Rephrase as Tweet", handler: { [weak self] _ in
                self?.applyPreset(.rephraseAsTweet)
            }),
            UIAction(title: "Polish writing", handler: { [weak self] _ in
                self?.applyPreset(.polishWriting)
            }),
            UIAction(title: "Fix grammar & spelling", handler: { [weak self] _ in
                self?.applyPreset(.fixGrammar)
            })
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
                .init(style: .text(title: "Presets", symbolName: "arrowtriangle.down.fill", isPrimary: false), menu: presetsMenu, showsMenuAsPrimaryAction: true)
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
                .init(style: .icon(symbolName: "chevron.left", accessibilityLabel: "Back"), action: { [weak self] in
                    self?.goBackGoogle()
                }),
                .init(style: .icon(symbolName: "chevron.right", accessibilityLabel: "Forward"), action: { [weak self] in
                    self?.goForwardGoogle()
                }),
                .init(style: .icon(symbolName: "arrow.clockwise", accessibilityLabel: "Reload"), action: { [weak self] in
                    self?.reloadGoogle()
                }),
                .init(style: .icon(symbolName: "arrow.up.right.square", accessibilityLabel: "Open"), action: { [weak self] in
                    self?.openGoogleResult()
                }),
                .init(style: .spacer),
                .init(style: .text(title: "Insert", symbolName: nil, isPrimary: false), action: { [weak self] in
                    self?.insertGoogleResult()
                })
            ],
            showsToggle: false,
            contentInsets: .zero
        )
        googleView.addSubview(googleContainer)
        pinContainer(googleContainer, to: googleView)
        
        // Store references to navigation buttons for state updates
        googleBackButton = googleContainer.getButton(accessibilityLabel: "Back")
        googleForwardButton = googleContainer.getButton(accessibilityLabel: "Forward")
        
        // Add swipe gestures for navigation
        setupGoogleWebViewGestures(webView)
        
        // Update initial button states
        updateGoogleNavigationButtons()
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
                .init(style: .spacer),
                .init(style: .text(title: "Insert", symbolName: nil, isPrimary: false), action: { [weak self] in
                    self?.insertChatGPTOutput()
                })
            ],
            showsToggle: true,
            contentInsets: UIEdgeInsets(top: 0, left: 14, bottom: 12, right: 12)
        )
        chatgptView.addSubview(chatgptContainer)
        pinContainer(chatgptContainer, to: chatgptView)
        chatgptCopyButton = chatgptContainer.getButton(accessibilityLabel: "Copy")
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
                .init(style: .spacer)
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
        // Note: Reloading happens automatically in updateModeVisibility() when switching to snippets mode
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
            
            // For Google mode, aggressively set preferredContentSize multiple times
            if mode == .google {
                let googleHeight = containerHeight(for: .large)
                let width = view.bounds.width > 0 ? view.bounds.width : UIScreen.main.bounds.width
                preferredContentSize = CGSize(width: width, height: googleHeight)
                NSLog("[KeyCo] switchToMode(google) - Force setting preferredContentSize to height: \(googleHeight)")
                
                // Force another update after a short delay to ensure iOS picks it up
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                    guard let self = self, self.currentMode == .google else { return }
                    self.preferredContentSize = CGSize(width: width, height: googleHeight)
                    self.heightConstraint?.constant = googleHeight
                    self.view.setNeedsLayout()
                    self.view.layoutIfNeeded()
                    NSLog("[KeyCo] switchToMode(google) - Delayed preferredContentSize update to height: \(googleHeight)")
                }
            }
        } else if !shouldAnimateHeight {
            updateHeight(animated: false)
        }

        // Update UI
        updateModeVisibility()
        if mode == .google {
            loadGoogleSearchFromContext()
            updateGoogleNavigationButtons()
        }
        // Reset selector when leaving write mode (so it's ready when returning)
        if previousMode == .write && mode != .write {
            toneMapView?.reset()
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
            // Always reload snippets when showing snippets view to get latest from host app
            NSLog("[KeyCo] Showing snippets view - reloading from storage")
            SnippetsStore.shared.reload()
            snippetsContentView?.reloadData()
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
        
        // Update constraint first
        heightConstraint.constant = newHeight
        
        // Set preferredContentSize so iOS recognizes the keyboard height
        let width = view.bounds.width > 0 ? view.bounds.width : UIScreen.main.bounds.width
        preferredContentSize = CGSize(width: width, height: newHeight)
        NSLog("[KeyCo] updateHeight - Mode: \(currentMode), Height: \(currentHeight.rawValue), Setting preferredContentSize to width: \(width), height: \(newHeight), actual preferredContentSize: \(preferredContentSize)")
        
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
        
        // Reload snippets to get latest data (only if in snippets mode or if switching to it)
        if currentMode == .snippets {
            SnippetsStore.shared.reload()
            snippetsContentView?.reloadData()
        }
        
        // Force complete layout refresh
        let targetHeight = containerHeight(for: currentHeight)
        
        // Set preferredContentSize and constraint to match current mode
        let width = view.bounds.width > 0 ? view.bounds.width : UIScreen.main.bounds.width
        preferredContentSize = CGSize(width: width, height: targetHeight)
        heightConstraint?.constant = targetHeight
        NSLog("[KeyCo] forceKeyboardRefresh - Mode: \(currentMode), Height: \(currentHeight.rawValue), Setting preferredContentSize to height: \(targetHeight)")
        
        // Update mode visibility first to ensure correct view is shown
        updateModeVisibility()
        
        // Force all views to update their layouts
        view.setNeedsLayout()
        view.layoutIfNeeded()
        
        // Explicitly refresh home view layout if in home mode
        if currentMode == .home {
            homeView.setNeedsLayout()
            homeView.layoutIfNeeded()
        }
        
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
            
            // Explicitly refresh home view layout again if in home mode
            if self.currentMode == .home {
                self.homeView.setNeedsLayout()
                self.homeView.layoutIfNeeded()
            }
            
            // Update mode visibility to ensure everything is correct
            self.updateModeVisibility()
            
            NSLog("[KeyCo] Keyboard refresh completed")
        }
    }
    
    private func reloadSnippets() {
        NSLog("[KeyCo] Reloading snippets from Darwin notification")
        // Reload from UserDefaults to get latest changes from host app
        SnippetsStore.shared.reload()
        let count = SnippetsStore.shared.getAll().count
        NSLog("[KeyCo] Loaded \(count) snippets from storage")
        snippetsContentView?.reloadData()
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

    private func setupGoogleWebViewGestures(_ webView: WKWebView) {
        // For now, let's simplify and just use simple swipe gestures
        // Remove all gesture recognizers first to avoid conflicts
        webView.gestureRecognizers?.forEach { webView.removeGestureRecognizer($0) }
        
        // Use simple swipe gestures
        let swipeRightGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeRight))
        swipeRightGesture.direction = .right
        swipeRightGesture.numberOfTouchesRequired = 1
        webView.addGestureRecognizer(swipeRightGesture)
        
        let swipeLeftGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeLeft))
        swipeLeftGesture.direction = .left
        swipeLeftGesture.numberOfTouchesRequired = 1
        webView.addGestureRecognizer(swipeLeftGesture)
    }
    
    @objc private func handleSwipeRight(_ gesture: UISwipeGestureRecognizer) {
        NSLog("[KeyCo] Swipe right detected")
        goBackGoogle()
    }
    
    @objc private func handleSwipeLeft(_ gesture: UISwipeGestureRecognizer) {
        NSLog("[KeyCo] Swipe left detected")
        goForwardGoogle()
    }
    
    private enum GoogleNavigationDirection {
        case back
        case forward
    }
    
    private var googleNavigationDirection: GoogleNavigationDirection?
    
    private func startGoogleNavigationTransition(direction: GoogleNavigationDirection, webView: WKWebView) {
        isGoogleNavigating = true
        googleNavigationDirection = direction
        
        // Disable horizontal scrolling during transition
        webView.scrollView.isScrollEnabled = false
        
        // Get the content container from ActionContainerView
        guard let superview = webView.superview else { return }
        
        // Create snapshot of current view
        let snapshot = webView.snapshotView(afterScreenUpdates: false) ?? UIView()
        snapshot.frame = webView.bounds
        superview.addSubview(snapshot)
        googleNavigationSnapshotView = snapshot
        
        // Position webview off-screen initially (it will slide in as we drag)
        let initialOffset = direction == .back ? -webView.bounds.width : webView.bounds.width
        webView.transform = CGAffineTransform(translationX: initialOffset, y: 0)
    }
    
    private func updateGoogleNavigationTransition(progress: CGFloat, translation: CGFloat) {
        guard let snapshot = googleNavigationSnapshotView,
              let webView = googleWebView,
              let direction = googleNavigationDirection else { return }
        
        let normalizedProgress = min(max(progress, 0), 1)
        
        // Animate snapshot sliding out
        snapshot.transform = CGAffineTransform(translationX: translation, y: 0)
        
        // Add subtle fade
        snapshot.alpha = 1.0 - normalizedProgress * 0.3
        
        // Webview slides in from opposite side
        let webviewOffset = direction == .back ? translation - webView.bounds.width : translation + webView.bounds.width
        webView.transform = CGAffineTransform(translationX: webviewOffset, y: 0)
    }
    
    private func completeGoogleNavigationTransition() {
        guard let snapshot = googleNavigationSnapshotView,
              let webView = googleWebView,
              let direction = googleNavigationDirection else {
            cleanupGoogleNavigationTransition()
            return
        }
        
        // Trigger navigation
        if direction == .back {
            webView.goBack()
        } else {
            webView.goForward()
        }
        
        let width = webView.bounds.width
        let finalOffset = direction == .back ? width : -width
        
        UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseOut], animations: {
            snapshot.transform = CGAffineTransform(translationX: finalOffset, y: 0)
            snapshot.alpha = 0
            webView.transform = .identity
        }) { _ in
            self.updateGoogleNavigationButtons()
            self.cleanupGoogleNavigationTransition()
        }
    }
    
    private func cancelGoogleNavigationTransition() {
        guard let snapshot = googleNavigationSnapshotView,
              let webView = googleWebView else {
            cleanupGoogleNavigationTransition()
            return
        }
        
        UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseOut], animations: {
            snapshot.transform = .identity
            snapshot.alpha = 1
            webView.transform = .identity
        }) { _ in
            self.cleanupGoogleNavigationTransition()
        }
    }
    
    private func cleanupGoogleNavigationTransition() {
        googleNavigationSnapshotView?.removeFromSuperview()
        googleNavigationTransitionView?.removeFromSuperview()
        googleNavigationSnapshotView = nil
        googleNavigationTransitionView = nil
        googleNavigationDirection = nil
        isGoogleNavigating = false
        
        // Ensure webview transform is reset and scrolling is re-enabled
        googleWebView?.transform = .identity
        googleWebView?.scrollView.isScrollEnabled = true
    }

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
            // Update button states after reload
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.updateGoogleNavigationButtons()
            }
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

    private func goBackGoogle() {
        guard let webView = googleWebView, webView.canGoBack else { return }
        NSLog("[KeyCo] goBackGoogle called - canGoBack: \(webView.canGoBack)")
        webView.goBack()
        // Update button states after a short delay to ensure navigation state is updated
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.updateGoogleNavigationButtons()
        }
    }

    private func goForwardGoogle() {
        guard let webView = googleWebView, webView.canGoForward else { return }
        NSLog("[KeyCo] goForwardGoogle called - canGoForward: \(webView.canGoForward)")
        webView.goForward()
        // Update button states after a short delay to ensure navigation state is updated
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.updateGoogleNavigationButtons()
        }
    }

    private func updateGoogleNavigationButtons() {
        DispatchQueue.main.async { [weak self] in
            guard let webView = self?.googleWebView else {
                self?.googleBackButton?.isEnabled = false
                self?.googleForwardButton?.isEnabled = false
                return
            }
            self?.googleBackButton?.isEnabled = webView.canGoBack
            self?.googleForwardButton?.isEnabled = webView.canGoForward
        }
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
    
    
    private func regenerateTextWithTone(tone: Float, length: Float, originalText: String? = nil, preset: String? = nil) {
        let textToUse = originalText ?? self.originalText
        
        NSLog("[Write Mode] regenerateTextWithTone called with tone=\(tone), length=\(length), preset=\(preset ?? "none"), text: '\(textToUse)'")
        
        guard !textToUse.isEmpty else {
            NSLog("[Write Mode] Cannot regenerate - text is empty")
            // Clear loading state if it was set
            DispatchQueue.main.async { [weak self] in
                self?.toneMapView?.setLoading(false)
            }
            return
        }
        
        // Cancel any existing API task and cleanup
        currentTask?.cancel()
        currentTask = nil
        loadingTimeoutTimer?.invalidate()
        loadingTimeoutTimer = nil
        
        // Fast preflight: check network only (don't gate on backend health)
        APIClient.checkNetworkConnectivity { [weak self] isOnline in
            guard let self = self else { return }
            
            if !isOnline {
                DispatchQueue.main.async {
                    self.toneMapView?.setLoading(false)
                    self.isWriting = false
                    self.handleWriteError("No network or Full Access disabled. Enable in Settings → Keyboard Copilot → Allow Full Access.")
                }
                return
            }
            
            NSLog("[Write Mode] Starting AI regeneration for text: '\(textToUse)'")
            self.isWriting = true
            
            // Show spinner in the selector knob
            DispatchQueue.main.async { [weak self] in
                self?.toneMapView?.setLoading(true)
                
                // Hide status label - only show errors
                self?.messagePreviewLabel?.isHidden = true
                
                // Set a timeout to ensure loading state is cleared if callback never fires
                // Extended timeout to account for retries (max 3 retries with delays)
                self?.loadingTimeoutTimer?.invalidate()
                self?.loadingTimeoutTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: false) { [weak self] _ in
                    NSLog("[Write Mode] TIMEOUT: API call timed out, clearing loading state")
                    self?.toneMapView?.setLoading(false)
                    self?.isWriting = false
                    self?.currentTask = nil
                    self?.handleWriteError("Request timed out. Please try again.")
                }
            }
            
            // Apply transformations to amplify extremes before sending to API
            let transformedTone = self.transformToneForExtremes(tone)
            let transformedLength = self.transformLengthForExtremes(length)
            
            NSLog("[Write Mode] Transformed values - tone: \(tone) -> \(transformedTone), length: \(length) -> \(transformedLength)")
            
            // Use APIClient with retry logic
            let request = APIClient.RewriteRequest(text: textToUse, tone: transformedTone, length: transformedLength, preset: preset)
            
            APIClient.rewriteText(request: request, onProgress: { [weak self] _ in
                // Silent retries, no progress UI
            }) { [weak self] result in
                // Cancel timeout timer since we got a response
                self?.loadingTimeoutTimer?.invalidate()
                self?.loadingTimeoutTimer = nil
                
                // Clear the current task reference
                self?.currentTask = nil
                
                guard let self = self else { return }
                
                self.isWriting = false
                
                // Hide spinner in selector knob
                self.toneMapView?.setLoading(false)
                
                switch result {
                case .success(let response):
                    NSLog("[Write Mode] Got AI response: '\(response.text)'")
                    
                    // Replace text in the text field
                    self.replaceTextFieldContent(with: response.text)
                    
                    // Ensure label stays hidden on success
                    self.messagePreviewLabel?.isHidden = true
                    
                case .failure(let error):
                    NSLog("[Write Mode] API Error: \(error.localizedDescription ?? "Unknown error")")
                    self.handleWriteError(error.localizedDescription ?? "Unknown error occurred")
                }
            }
        }
    }
    
    /// Apply a preset transformation to the current text
    private func applyPreset(_ preset: WritePreset) {
        let currentText = currentDocumentText()
        guard !currentText.isEmpty else {
            NSLog("[Write Mode] Cannot apply preset - text is empty")
            return
        }
        
        // Store original text for undo
        originalText = currentText
        
        // Map preset to tone/length values and preset identifier
        let (tone, length, presetId): (Float, Float, String)
        switch preset {
        case .fixGrammar:
            // Neutral tone, keep similar length - only fixes grammar/spelling, respects original text
            tone = 0.5
            length = 0.5
            presetId = "fix_grammar"
        case .polishWriting:
            // Neutral tone, keep similar length - polishes text including grammar/spelling improvements
            tone = 0.5
            length = 0.5
            presetId = "polish"
        case .rephraseAsTweet:
            // Neutral tone, very brief (tweet length ~280 chars)
            tone = 0.5
            length = 0.95
            presetId = "tweet"
        }
        
        NSLog("[Write Mode] Applying preset: \(preset), presetId=\(presetId), tone=\(tone), length=\(length)")
        
        // Call regenerate with preset values and identifier
        regenerateTextWithTone(tone: tone, length: length, originalText: currentText, preset: presetId)
    }

    /// Transforms tone value with asymmetric curve: amplifies friendly side more, keeps formal side moderate
    /// Friendly side (0-0.5): More extreme compression toward 0 for super casual
    /// Formal side (0.5-1.0): Gentler transformation to avoid extreme formality
    private func transformToneForExtremes(_ value: Float) -> Float {
        // Clamp value to [0, 1]
        let clamped = max(0, min(1, value))
        
        if clamped < 0.5 {
            // Friendly side: use aggressive curve to push toward super casual
            // pow(value * 2, 0.4) / 2 creates steeper curve for friendly extreme
            let normalized = clamped * 2.0 // Scale to [0, 1]
            let transformed = pow(Double(normalized), 0.4) // Aggressive curve
            return Float(transformed / 2.0) // Scale back to [0, 0.5]
        } else {
            // Formal side: use gentler transformation to avoid extreme formality
            // Linear interpolation with slight compression to keep it moderate
            let normalized = (clamped - 0.5) * 2.0 // Scale to [0, 1]
            let transformed = pow(Double(normalized), 0.85) // Gentler curve
            return Float(0.5 + transformed / 2.0) // Scale back to [0.5, 1.0]
        }
    }
    
    /// Transforms length value to amplify extremes using exponential curve
    /// Lower exponent (e.g., 0.6) makes brief extreme more extreme
    private func transformLengthForExtremes(_ value: Float) -> Float {
        // Clamp value to [0, 1]
        let clamped = max(0, min(1, value))
        // Apply power curve: pow(value, 0.6) makes brief extreme more extreme
        // For value near 0: stays near 0 (detailed)
        // For value near 1: stays near 1 (brief extreme)
        // For middle values: compressed toward extremes
        return Float(pow(Double(clamped), 0.6))
    }
    
    private func describeTone(_ value: Float) -> String {
        // X-axis: 0 = Friendly/Casual (left), 1 = Formal (right)
        // Recalibrated: friendly side can be super casual/slang, formal side is quite formal but not extreme
        if value < 0.1 {
            return "super casual and unbelievably informal, like texting slang - use casual slang, abbreviations, very relaxed, super friendly, texting speak"
        } else if value < 0.2 {
            return "extremely casual and informal, like texting a close friend - use slang, contractions, very relaxed, emojis optional, super friendly"
        } else if value < 0.3 {
            return "very casual and friendly, use contractions like 'you're' and 'I'll', keep it conversational and relaxed"
        } else if value < 0.4 {
            return "casual and warm, conversational with a friendly tone, use contractions naturally"
        } else if value < 0.5 {
            return "friendly and approachable, conversational but slightly more polished, warm tone"
        } else if value < 0.6 {
            return "professional yet approachable, balanced between friendly and formal, personable but respectful"
        } else if value < 0.7 {
            return "professional and clear, use standard business language, polite and direct"
        } else if value < 0.8 {
            return "professional and formal, use proper business language, avoid casual expressions"
        } else if value < 0.9 {
            return "formal and professional, avoid contractions, use proper business etiquette, respectful tone"
        } else {
            return "quite formal and professional, use formal language appropriately, avoid casual expressions, but keep it natural and not overly formal"
        }
    }
    
    private func describeLength(_ value: Float) -> String {
        // Y-axis: 0 = Detailed (top), 1 = Brief (bottom)
        // Expanded to 10 ranges for more granular control and distinct positions
        if value < 0.1 {
            return "comprehensive and detailed - include all important points with context, but keep it concise (not an essay), well-structured"
        } else if value < 0.2 {
            return "detailed and thorough - include all important points and context, provide necessary details"
        } else if value < 0.3 {
            return "moderately detailed - include key points with some context and supporting information"
        } else if value < 0.4 {
            return "moderately concise - include key points with minimal context, focus on essentials"
        } else if value < 0.5 {
            return "concise and focused - include only essential information, skip unnecessary details"
        } else if value < 0.6 {
            return "brief and direct - essential information only, no extra context or details"
        } else if value < 0.7 {
            return "very brief - minimal words, only the core message, skip all non-essential information"
        } else if value < 0.8 {
            return "extremely brief - absolute minimum words, single thought only, strip everything unnecessary"
        } else if value < 0.9 {
            return "ultra-brief - absolute minimum, single phrase if possible, remove all filler words"
        } else {
            return "ultra-brief - absolute minimum words, single phrase or word if possible, maximum compression"
        }
    }
    
    /// Returns (maxWords, maxSentences) based on length value
    private func getLengthConstraints(_ value: Float) -> (Int, Int) {
        // Y-axis: 0 = Detailed (top), 1 = Brief (bottom)
        // Expanded to 10 ranges matching describeLength() for consistency
        if value < 0.1 {
            return (120, 4)  // Comprehensive: up to 120 words, 4 sentences
        } else if value < 0.2 {
            return (100, 3)  // Detailed: up to 100 words, 3 sentences
        } else if value < 0.3 {
            return (75, 3)   // Moderately detailed: up to 75 words, 3 sentences
        } else if value < 0.4 {
            return (60, 2)   // Moderately concise: up to 60 words, 2 sentences
        } else if value < 0.5 {
            return (45, 2)   // Concise: up to 45 words, 2 sentences
        } else if value < 0.6 {
            return (35, 2)   // Brief: up to 35 words, 2 sentences
        } else if value < 0.7 {
            return (25, 1)   // Very brief: up to 25 words, 1 sentence
        } else if value < 0.8 {
            return (18, 1)   // Extremely brief: up to 18 words, 1 sentence
        } else if value < 0.9 {
            return (12, 1)   // Ultra-brief: up to 12 words, 1 sentence
        } else {
            return (8, 1)    // Ultra-brief extreme: up to 8 words, 1 sentence
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
        messagePreviewLabel?.text = message
        messagePreviewLabel?.textColor = .systemRed
        messagePreviewLabel?.isHidden = false
        // Always clear loading state when there's an error
        toneMapView?.setLoading(false)
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
        
        // Fast preflight: check network only (don't gate on backend health)
        APIClient.checkNetworkConnectivity { [weak self] isOnline in
            guard let self = self else { return }
            
            if !isOnline {
                DispatchQueue.main.async {
                    self.chatgptContentView.responseText = "No network or Full Access disabled. Enable in Settings → Keyboard Copilot → Allow Full Access."
                }
                return
            }
            
            // Use APIClient with retry logic
            let request = APIClient.ChatRequest(query: query)
            
            APIClient.chatQuery(request: request, onProgress: { [weak self] _ in
                // Silent retries, no progress UI
            }) { [weak self] result in
                guard let self = self else { return }
                
                switch result {
                case .success(let response):
                    self.chatgptContentView.responseText = response.text
                    
                case .failure(let error):
                    let errorMessage = error.localizedDescription ?? "Unknown error occurred"
                    self.chatgptContentView.responseText = "Error: \(errorMessage)"
                    NSLog("[KeyCo] ChatGPT API error: %@", errorMessage)
                }
            }
        }
    }

    private func reloadChatGPT() {
        queryChatGPT()
    }
    
    private func createColoredSymbolImage(systemName: String, color: UIColor, pointSize: CGFloat = 12, weight: UIImage.SymbolWeight = .semibold) -> UIImage? {
        let config = UIImage.SymbolConfiguration(pointSize: pointSize, weight: weight)
        guard let templateImage = UIImage(systemName: systemName, withConfiguration: config)?.withRenderingMode(.alwaysTemplate) else {
            return nil
        }
        
        // Render the image with the specified color
        let renderer = UIGraphicsImageRenderer(size: templateImage.size)
        return renderer.image { context in
            color.set()
            templateImage.draw(in: CGRect(origin: .zero, size: templateImage.size))
        }.withRenderingMode(.alwaysOriginal)
    }

    private func copyChatGPTOutput() {
        let text = chatgptContentView.responseText
        guard !text.isEmpty, text != "Loading...", !text.hasPrefix("Error:") else { return }
        
        guard let button = chatgptCopyButton, button.isEnabled else { return }
        
        UIPasteboard.general.string = text
        NSLog("[KeyCo] Copied ChatGPT output to clipboard")
        
        // Disable button and keep tint color black
        button.isEnabled = false
        button.tintColor = .label
        
        // Create checkmark image with black color baked in
        let checkmarkImage = createColoredSymbolImage(systemName: "checkmark", color: .label)
        
        // Use crossfade transition for smooth icon change
        UIView.transition(with: button, duration: 0.2, options: [.transitionCrossDissolve, .allowUserInteraction], animations: {
            button.setImage(checkmarkImage, for: .normal)
            button.setImage(checkmarkImage, for: .disabled)
        })
        
        // After delay, animate back to copy icon
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) { [weak self] in
            guard let button = self?.chatgptCopyButton else { return }
            guard let self = self else { return }
            
            // Create copy image with black color baked in
            let copyImage = self.createColoredSymbolImage(systemName: "doc.on.doc", color: .label)
            
            // Use crossfade transition for smooth icon change back
            UIView.transition(with: button, duration: 0.2, options: [.transitionCrossDissolve, .allowUserInteraction], animations: {
                button.setImage(copyImage, for: .normal)
                button.setImage(copyImage, for: .disabled)
            }) { _ in
                button.isEnabled = true
            }
        }
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
        // Update button states after navigation finishes
        updateGoogleNavigationButtons()
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        guard let storedWebView = googleWebView, webView === storedWebView else { return }
        // Update button states when navigation starts
        updateGoogleNavigationButtons()
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        guard let storedWebView = googleWebView, webView === storedWebView else { return }
        // Update button states when navigation commits (most reliable time)
        updateGoogleNavigationButtons()
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        guard let storedWebView = googleWebView, webView === storedWebView else { return }
        // Update button states even if navigation fails
        updateGoogleNavigationButtons()
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        guard let storedWebView = googleWebView, webView === storedWebView else { return }
        // Update button states even if provisional navigation fails
        updateGoogleNavigationButtons()
    }
}

// MARK: - UIGestureRecognizerDelegate

extension KeyboardViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Allow swipe gestures to work alongside webview scrolling
        return true
    }
}

