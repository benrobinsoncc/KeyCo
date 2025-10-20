import UIKit

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
        case large = 500
    }

    private var currentMode: KeyboardMode = .home
    private var currentHeight: KeyboardHeight = .small

    // UI Components
    private var heightConstraint: NSLayoutConstraint!
    private var containerView: UIView!
    private var contentArea: UIView!
    private var actionBar: UIView!
    private var backButton: UIButton!

    // Content views for each mode
    private var homeView: UIView!
    private var replyView: UIView!
    private var rewriteView: UIView!
    private var googleView: UIView!
    private var chatgptView: UIView!

    private let containerMargin: CGFloat = 8
    private let cornerRadius: CGFloat = 20
    private let actionBarHeight: CGFloat = 44

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
        heightConstraint = view.heightAnchor.constraint(equalToConstant: currentHeight.rawValue)
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

        // Setup action bar
        setupActionBar()

        // Show initial mode
        updateModeVisibility()
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
            contentArea.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -actionBarHeight)
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
        let buttonSize: CGFloat = 100
        let spacing: CGFloat = 12
        let padding: CGFloat = 20

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
            replyButton.widthAnchor.constraint(equalToConstant: buttonSize),
            replyButton.heightAnchor.constraint(equalToConstant: buttonSize),

            // Rewrite (top-right)
            rewriteButton.topAnchor.constraint(equalTo: homeView.topAnchor, constant: padding),
            rewriteButton.trailingAnchor.constraint(equalTo: homeView.trailingAnchor, constant: -padding),
            rewriteButton.widthAnchor.constraint(equalToConstant: buttonSize),
            rewriteButton.heightAnchor.constraint(equalToConstant: buttonSize),

            // Google (bottom-left)
            googleButton.bottomAnchor.constraint(equalTo: homeView.bottomAnchor, constant: -padding),
            googleButton.leadingAnchor.constraint(equalTo: homeView.leadingAnchor, constant: padding),
            googleButton.widthAnchor.constraint(equalToConstant: buttonSize),
            googleButton.heightAnchor.constraint(equalToConstant: buttonSize),

            // ChatGPT (bottom-right)
            chatgptButton.bottomAnchor.constraint(equalTo: homeView.bottomAnchor, constant: -padding),
            chatgptButton.trailingAnchor.constraint(equalTo: homeView.trailingAnchor, constant: -padding),
            chatgptButton.widthAnchor.constraint(equalToConstant: buttonSize),
            chatgptButton.heightAnchor.constraint(equalToConstant: buttonSize)
        ])
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
        replyView = createPlaceholderView(title: "Reply Mode", color: .systemBlue)
    }

    private func setupRewriteView() {
        rewriteView = createPlaceholderView(title: "Rewrite Mode", color: .systemGreen)
    }

    private func setupGoogleView() {
        googleView = createPlaceholderView(title: "Google Mode", color: .systemOrange)
    }

    private func setupChatGPTView() {
        chatgptView = createPlaceholderView(title: "ChatGPT Mode", color: .systemPurple)
    }

    private func createPlaceholderView(title: String, color: UIColor) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        view.alpha = 0
        contentArea.addSubview(view)

        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: contentArea.topAnchor),
            view.leadingAnchor.constraint(equalTo: contentArea.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: contentArea.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: contentArea.bottomAnchor)
        ])

        let label = UILabel()
        label.text = title
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textColor = color
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        return view
    }

    private func setupActionBar() {
        actionBar = UIView()
        actionBar.backgroundColor = .clear
        actionBar.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(actionBar)

        NSLayoutConstraint.activate([
            actionBar.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            actionBar.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            actionBar.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            actionBar.heightAnchor.constraint(equalToConstant: actionBarHeight)
        ])

        // Back button (hidden in home mode)
        backButton = UIButton(type: .system)
        backButton.setTitle("← Back", for: .normal)
        backButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.alpha = 0
        actionBar.addSubview(backButton)

        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(equalTo: actionBar.leadingAnchor, constant: 16),
            backButton.centerYAnchor.constraint(equalTo: actionBar.centerYAnchor)
        ])
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

    @objc private func backTapped() {
        switchToMode(.home, height: .small)
    }

    // MARK: - Mode Management

    private func switchToMode(_ mode: KeyboardMode, height: KeyboardHeight) {
        currentMode = mode

        // Update height if needed
        if currentHeight != height {
            currentHeight = height
            updateHeight(animated: true)
        }

        // Update UI
        updateModeVisibility()
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
            backButton.alpha = 0
        case .reply:
            replyView.alpha = 1
            backButton.alpha = 1
        case .rewrite:
            rewriteView.alpha = 1
            backButton.alpha = 1
        case .google:
            googleView.alpha = 1
            backButton.alpha = 1
        case .chatgpt:
            chatgptView.alpha = 1
            backButton.alpha = 1
        }
    }

    private func updateHeight(animated: Bool) {
        heightConstraint.constant = currentHeight.rawValue

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
            currentHeight = heightValue == KeyboardHeight.large.rawValue ? .large : .small
        }
    }
}
