import UIKit

/// Reusable action container that mirrors the styling from the Keyboard Copilot project.
/// Contains a content area, a divider, a configurable action bar, and an expand/collapse toggle.
final class ActionContainerView: UIView {

    // MARK: - Nested Types

    struct ActionButtonConfiguration {
        enum DisplayStyle {
            case icon(symbolName: String, accessibilityLabel: String)
            case text(title: String, symbolName: String? = nil, isPrimary: Bool)
            case spacer
        }

        let style: DisplayStyle
        let action: (() -> Void)?
        let menu: UIMenu?
        let showsMenuAsPrimaryAction: Bool

        init(
            style: DisplayStyle,
            action: (() -> Void)? = nil,
            menu: UIMenu? = nil,
            showsMenuAsPrimaryAction: Bool = false
        ) {
            self.style = style
            self.action = action
            self.menu = menu
            self.showsMenuAsPrimaryAction = showsMenuAsPrimaryAction
        }
    }

    // MARK: - Properties

    var onToggle: (() -> Void)? {
        didSet {
            toggleButton.isHidden = onToggle == nil
        }
    }

    private let backgroundView = UIView()
    private let contentContainer = UIView()
    private let dividerView = UIView()
    private let buttonStack = UIStackView()
    private let bottomBar = UIView()
    private let toggleButton = UIButton(type: .system)

    private var buttonActions: [UIButton: () -> Void] = [:]

    private var isExpanded = false
    private var contentInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
    private var dividerSpacing: CGFloat = 12
    private var buttonTopSpacing: CGFloat = 12
    private var buttonBottomInset: CGFloat = 12
    private var buttonSideInset: CGFloat = 12
    private var buttonCornerRadius: CGFloat = 18
    private var contentTopConstraint: NSLayoutConstraint!
    private var contentLeadingConstraint: NSLayoutConstraint!
    private var contentTrailingConstraint: NSLayoutConstraint!
    private var contentBottomConstraint: NSLayoutConstraint!
    private var dividerTopConstraint: NSLayoutConstraint!
    private var buttonTopConstraint: NSLayoutConstraint!
    private var buttonLeadingConstraint: NSLayoutConstraint!
    private var buttonTrailingConstraint: NSLayoutConstraint!
    private var buttonBottomConstraint: NSLayoutConstraint!
    private var bottomBarHeightConstraint: NSLayoutConstraint!
    private var bottomBarTopConstraint: NSLayoutConstraint!

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViewHierarchy()
        setupLayout()
        configureAppearance()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupViewHierarchy() {
        translatesAutoresizingMaskIntoConstraints = false

        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(backgroundView)

        contentContainer.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.setContentHuggingPriority(.defaultLow, for: .vertical)
        contentContainer.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        backgroundView.addSubview(contentContainer)

        toggleButton.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.addSubview(toggleButton)

        dividerView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.addSubview(dividerView)

        bottomBar.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.addSubview(bottomBar)

        buttonStack.axis = .horizontal
        buttonStack.alignment = .center
        buttonStack.distribution = .fill
        buttonStack.spacing = 0
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        buttonStack.setContentHuggingPriority(.required, for: .vertical)
        buttonStack.setContentCompressionResistancePriority(.required, for: .vertical)
        bottomBar.addSubview(buttonStack)
    }

    private func setupLayout() {
        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),

            toggleButton.topAnchor.constraint(equalTo: backgroundView.topAnchor, constant: 6),
            toggleButton.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor, constant: -6),
            toggleButton.widthAnchor.constraint(equalToConstant: 30),
            toggleButton.heightAnchor.constraint(equalToConstant: 30)
        ])

        contentTopConstraint = contentContainer.topAnchor.constraint(equalTo: backgroundView.topAnchor, constant: contentInsets.top)
        contentLeadingConstraint = contentContainer.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor, constant: contentInsets.left)
        contentTrailingConstraint = contentContainer.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor, constant: -contentInsets.right)
        dividerTopConstraint = dividerView.topAnchor.constraint(equalTo: contentContainer.bottomAnchor, constant: dividerSpacing)
        contentBottomConstraint = contentContainer.bottomAnchor.constraint(equalTo: dividerView.topAnchor, constant: -dividerSpacing)
        buttonTopConstraint = buttonStack.topAnchor.constraint(equalTo: bottomBar.topAnchor, constant: 8)

        buttonLeadingConstraint = buttonStack.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor, constant: buttonSideInset)
        buttonTrailingConstraint = buttonStack.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor, constant: -buttonSideInset)
        buttonBottomConstraint = buttonStack.bottomAnchor.constraint(equalTo: bottomBar.bottomAnchor, constant: -8)
        bottomBarHeightConstraint = bottomBar.heightAnchor.constraint(equalToConstant: 8 + 8 + 32)

        NSLayoutConstraint.activate([
            contentTopConstraint,
            contentLeadingConstraint,
            contentTrailingConstraint,
            dividerTopConstraint,
            dividerView.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor),
            dividerView.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor),
            dividerView.heightAnchor.constraint(equalToConstant: 1),
            contentBottomConstraint
        ])
        
        // Bottom bar can connect to either divider or content container
        bottomBarTopConstraint = bottomBar.topAnchor.constraint(equalTo: dividerView.bottomAnchor)
        NSLayoutConstraint.activate([
            bottomBarTopConstraint,
            bottomBar.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor),
            bottomBar.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor),
            buttonTopConstraint,
            buttonLeadingConstraint,
            buttonTrailingConstraint,
            buttonBottomConstraint,
            bottomBarHeightConstraint
        ])
    }

    private func configureAppearance() {
        backgroundColor = .clear

        backgroundView.backgroundColor = UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor.secondarySystemBackground : UIColor.systemBackground
        }
        backgroundView.layer.cornerRadius = 16
        backgroundView.layer.masksToBounds = true
        backgroundView.layer.borderWidth = 0
        backgroundView.layer.borderColor = nil

        contentContainer.backgroundColor = .clear

        dividerView.backgroundColor = UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor.separator.withAlphaComponent(0.35)
                : UIColor.separator.withAlphaComponent(0.1)
        }

        toggleButton.setImage(UIImage(systemName: "arrow.up.left.and.arrow.down.right"), for: .normal)
        toggleButton.tintColor = .systemGray
        toggleButton.backgroundColor = .clear
        toggleButton.layer.cornerRadius = 15
        toggleButton.setPreferredSymbolConfiguration(
            UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold),
            forImageIn: .normal
        )
        toggleButton.addTarget(self, action: #selector(toggleTapped), for: .touchUpInside)
        toggleButton.isHidden = true
    }

    // MARK: - Public API

    func setContentView(_ view: UIView) {
        // Remove previous content
        contentContainer.subviews.forEach { $0.removeFromSuperview() }

        view.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.addSubview(view)

        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            view.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor)
        ])
    }

    func setContentLayout(
        insets: UIEdgeInsets,
        dividerSpacing: CGFloat,
        buttonTopSpacing: CGFloat,
        buttonSideInset: CGFloat = 12,
        buttonBottomInset: CGFloat = 12,
        buttonCornerRadius: CGFloat = 18
    ) {
        contentInsets = insets
        self.dividerSpacing = dividerSpacing
        self.buttonTopSpacing = buttonTopSpacing
        self.buttonSideInset = buttonSideInset
        self.buttonBottomInset = buttonBottomInset
        self.buttonCornerRadius = buttonCornerRadius
        contentTopConstraint.constant = insets.top
        contentLeadingConstraint.constant = insets.left
        contentTrailingConstraint.constant = -insets.right
        contentBottomConstraint.constant = -dividerSpacing
        dividerTopConstraint.constant = dividerSpacing
        buttonTopConstraint.constant = 8
        buttonLeadingConstraint.constant = buttonSideInset
        buttonTrailingConstraint.constant = -buttonSideInset
        buttonBottomConstraint.constant = -8
        bottomBarHeightConstraint.constant = 8 + 8 + 32
        layoutIfNeeded()
    }
    
    func setDividerHidden(_ hidden: Bool) {
        dividerView.isHidden = hidden
        dividerView.alpha = hidden ? 0 : 1
        
        // Update content container bottom constraint
        contentBottomConstraint.isActive = false
        if hidden {
            // When divider is hidden, content container bottom connects directly to bottom bar
            contentBottomConstraint = contentContainer.bottomAnchor.constraint(equalTo: bottomBar.topAnchor)
        } else {
            // When divider is visible, content container bottom is above divider
            contentBottomConstraint = contentContainer.bottomAnchor.constraint(equalTo: dividerView.topAnchor, constant: -dividerSpacing)
        }
        contentBottomConstraint.isActive = true
        
        // Update bottom bar constraint - connect to divider or directly to content
        bottomBarTopConstraint.isActive = false
        if hidden {
            bottomBarTopConstraint = bottomBar.topAnchor.constraint(equalTo: contentContainer.bottomAnchor)
        } else {
            bottomBarTopConstraint = bottomBar.topAnchor.constraint(equalTo: dividerView.bottomAnchor)
        }
        bottomBarTopConstraint.isActive = true
        layoutIfNeeded()
    }

    func configureButtons(_ configurations: [ActionButtonConfiguration]) {
        buttonStack.arrangedSubviews.forEach { subview in
            buttonStack.removeArrangedSubview(subview)
            subview.removeFromSuperview()
        }
        buttonActions.removeAll()

        guard !configurations.isEmpty else { return }

        let firstPrimaryIndex = configurations.firstIndex { config in
            if case .text(_, _, let isPrimary) = config.style {
                return isPrimary
            }
            return false
        }

        var previousWasFlexibleSpacer = false

        for (index, configuration) in configurations.enumerated() {
            // Check if this is an explicit spacer or auto-spacer before primary button
            if case .spacer = configuration.style {
                // Explicit flexible spacer
                let flexibleSpacer = UIView()
                flexibleSpacer.translatesAutoresizingMaskIntoConstraints = false
                flexibleSpacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
                flexibleSpacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
                buttonStack.addArrangedSubview(flexibleSpacer)
                previousWasFlexibleSpacer = true
                continue
            } else if let primaryIndex = firstPrimaryIndex, index == primaryIndex {
                // Auto-spacer before first primary button
                let flexibleSpacer = UIView()
                flexibleSpacer.translatesAutoresizingMaskIntoConstraints = false
                flexibleSpacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
                flexibleSpacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
                buttonStack.addArrangedSubview(flexibleSpacer)
                previousWasFlexibleSpacer = true
            } else if !buttonStack.arrangedSubviews.isEmpty && !previousWasFlexibleSpacer {
                // Fixed spacer between regular buttons
                let spacer = UIView()
                spacer.translatesAutoresizingMaskIntoConstraints = false
                spacer.widthAnchor.constraint(equalToConstant: 8).isActive = true
                buttonStack.addArrangedSubview(spacer)
            }

            let button: UIButton

            switch configuration.style {
            case let .icon(symbolName, accessibilityLabel):
                button = createIconButton(symbolName: symbolName, accessibilityLabel: accessibilityLabel)
            case let .text(title, symbolName, isPrimary):
                button = createTextButton(
                    title: title,
                    symbolName: symbolName,
                    isPrimary: isPrimary
                )
            case .spacer:
                // Already handled above
                continue
            }

            if let menu = configuration.menu {
                button.menu = menu
                button.showsMenuAsPrimaryAction = configuration.showsMenuAsPrimaryAction
            }

            if let action = configuration.action {
                button.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
                buttonActions[button] = action
            }

            buttonStack.addArrangedSubview(button)
            previousWasFlexibleSpacer = false
        }
    }

    func setExpanded(_ expanded: Bool) {
        guard isExpanded != expanded else { return }
        isExpanded = expanded
        let symbolName = expanded ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right"
        toggleButton.setImage(UIImage(systemName: symbolName), for: .normal)
    }

    // MARK: - Actions

    @objc private func toggleTapped() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        onToggle?()
    }

    @objc private func actionButtonTapped(_ sender: UIButton) {
        guard let action = buttonActions[sender] else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        action()
    }

    // MARK: - Helpers

    private func createIconButton(symbolName: String, accessibilityLabel: String) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor.tertiarySystemBackground : UIColor.secondarySystemBackground
        }
        button.tintColor = .label
        button.layer.cornerRadius = 15
        button.layer.cornerCurve = .continuous
        button.clipsToBounds = true
        button.setImage(UIImage(systemName: symbolName), for: .normal)
        button.widthAnchor.constraint(equalToConstant: 30).isActive = true
        button.heightAnchor.constraint(equalToConstant: 30).isActive = true
        button.setPreferredSymbolConfiguration(
            UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold),
            forImageIn: .normal
        )
        button.accessibilityLabel = accessibilityLabel
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        return button
    }

    private func createTextButton(title: String, symbolName: String?, isPrimary: Bool) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 32).isActive = true
        // Use fixed corner radius of 16 for fully rounded appearance
        button.layer.cornerRadius = 16
        button.layer.cornerCurve = .continuous
        button.clipsToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: isPrimary ? 15 : 13, weight: isPrimary ? .semibold : .medium)
        button.titleLabel?.lineBreakMode = .byTruncatingTail
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        button.setTitle(title, for: .normal)

        if let symbolName, let image = UIImage(systemName: symbolName) {
            button.setImage(image, for: .normal)
            button.setPreferredSymbolConfiguration(
                UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold),
                forImageIn: .normal
            )
            let secondaryBackground = UIColor { trait in
                trait.userInterfaceStyle == .dark ? UIColor.secondarySystemBackground : UIColor.systemGray5
            }
            button.tintColor = isPrimary ? UIColor { trait in
                trait.userInterfaceStyle == .dark ? UIColor.black : UIColor.white
            } : .label
            if symbolName == "chevron.down" {
                button.semanticContentAttribute = .forceRightToLeft
                button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
                // Add more space between label and chevron
                button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 0)
                button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 4)
            } else {
                button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: 4)
                button.semanticContentAttribute = .forceLeftToRight
                button.titleEdgeInsets = .zero
            }
        }

        if isPrimary {
            button.backgroundColor = .label
            button.setTitleColor(UIColor { trait in
                trait.userInterfaceStyle == .dark ? UIColor.black : UIColor.white
            }, for: .normal)
        } else {
            // Use same grey as icon buttons for consistency
            button.backgroundColor = UIColor { trait in
                trait.userInterfaceStyle == .dark ? UIColor.tertiarySystemBackground : UIColor.secondarySystemBackground
            }
            button.setTitleColor(.label, for: .normal)
        }

        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        
        // Add minimum width constraint to prevent excessive compression
        button.widthAnchor.constraint(greaterThanOrEqualToConstant: 60).isActive = true
        
        return button
    }
}
