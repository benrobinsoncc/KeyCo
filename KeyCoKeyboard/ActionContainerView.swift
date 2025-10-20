import UIKit

/// Reusable action container that mirrors the styling from the Keyboard Copilot project.
/// Contains a content area, a divider, a configurable action bar, and an expand/collapse toggle.
final class ActionContainerView: UIView {

    // MARK: - Nested Types

    struct ActionButtonConfiguration {
        enum DisplayStyle {
            case icon(symbolName: String, accessibilityLabel: String)
            case text(title: String, symbolName: String? = nil, isPrimary: Bool)
        }

        let style: DisplayStyle
        let action: () -> Void
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
    private let toggleButton = UIButton(type: .system)

    private var buttonActions: [UIButton: () -> Void] = [:]

    private var isExpanded = false
    private var contentInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
    private var dividerSpacing: CGFloat = 12
    private var buttonTopSpacing: CGFloat = 12
    private var buttonBottomInset: CGFloat = 12
    private var buttonSideInset: CGFloat = 12
    private var buttonCornerRadius: CGFloat = 20
    private var contentTopConstraint: NSLayoutConstraint!
    private var contentLeadingConstraint: NSLayoutConstraint!
    private var contentTrailingConstraint: NSLayoutConstraint!
    private var dividerTopConstraint: NSLayoutConstraint!
    private var buttonTopConstraint: NSLayoutConstraint!
    private var buttonLeadingConstraint: NSLayoutConstraint!
    private var buttonTrailingConstraint: NSLayoutConstraint!
    private var buttonBottomConstraint: NSLayoutConstraint!

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

        buttonStack.axis = .horizontal
        buttonStack.alignment = .center
        buttonStack.distribution = .fill
        buttonStack.spacing = 8
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        buttonStack.setContentHuggingPriority(.required, for: .vertical)
        buttonStack.setContentCompressionResistancePriority(.required, for: .vertical)
        backgroundView.addSubview(buttonStack)
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
        buttonTopConstraint = buttonStack.topAnchor.constraint(equalTo: dividerView.bottomAnchor, constant: buttonTopSpacing)

        buttonLeadingConstraint = buttonStack.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor, constant: buttonSideInset)
        buttonTrailingConstraint = buttonStack.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor, constant: -buttonSideInset)
        buttonBottomConstraint = buttonStack.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor, constant: -buttonBottomInset)

        NSLayoutConstraint.activate([
            contentTopConstraint,
            contentLeadingConstraint,
            contentTrailingConstraint,
            dividerTopConstraint,
            dividerView.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor),
            dividerView.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor),
            dividerView.heightAnchor.constraint(equalToConstant: 1),
            buttonTopConstraint,
            buttonLeadingConstraint,
            buttonTrailingConstraint,
            buttonBottomConstraint
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
        buttonCornerRadius: CGFloat = 20
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
        dividerTopConstraint.constant = dividerSpacing
        buttonTopConstraint.constant = buttonTopSpacing
        buttonLeadingConstraint.constant = buttonSideInset
        buttonTrailingConstraint.constant = -buttonSideInset
        buttonBottomConstraint.constant = -buttonBottomInset
        buttonStack.arrangedSubviews.forEach { view in
            if let button = view as? UIButton {
                button.layer.cornerRadius = buttonCornerRadius
            }
        }
        layoutIfNeeded()
    }

    func configureButtons(_ configurations: [ActionButtonConfiguration]) {
        buttonStack.arrangedSubviews.forEach { subview in
            buttonStack.removeArrangedSubview(subview)
            subview.removeFromSuperview()
        }
        buttonActions.removeAll()

        var needsSpacer = true

        for configuration in configurations {
            switch configuration.style {
            case let .icon(symbolName, accessibilityLabel):
                let button = createIconButton(symbolName: symbolName, accessibilityLabel: accessibilityLabel)
                buttonStack.addArrangedSubview(button)
                buttonActions[button] = configuration.action
            case let .text(title, symbolName, isPrimary):
                if needsSpacer {
                    let spacer = UIView()
                    spacer.translatesAutoresizingMaskIntoConstraints = false
                    spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
                    spacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
                    buttonStack.addArrangedSubview(spacer)
                    needsSpacer = false
                }
                let button = createTextButton(
                    title: title,
                    symbolName: symbolName,
                    isPrimary: isPrimary
                )
                buttonStack.addArrangedSubview(button)
                buttonActions[button] = configuration.action
            }
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
        button.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
        return button
    }

    private func createTextButton(title: String, symbolName: String?, isPrimary: Bool) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 32).isActive = true
        button.layer.cornerRadius = buttonCornerRadius
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: isPrimary ? .semibold : .medium)
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        button.setTitle(title, for: .normal)

        if let symbolName, let image = UIImage(systemName: symbolName) {
            button.setImage(image, for: .normal)
            button.setPreferredSymbolConfiguration(
                UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold),
                forImageIn: .normal
            )
            button.tintColor = isPrimary ? UIColor { trait in
                trait.userInterfaceStyle == .dark ? UIColor.black : UIColor.white
            } : .label
            button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: 4)
            button.semanticContentAttribute = .forceLeftToRight
        }

        if isPrimary {
            button.backgroundColor = .label
            button.setTitleColor(UIColor { trait in
                trait.userInterfaceStyle == .dark ? UIColor.black : UIColor.white
            }, for: .normal)
        } else {
            button.backgroundColor = UIColor { trait in
                trait.userInterfaceStyle == .dark ? UIColor.secondarySystemBackground : UIColor.systemGray5
            }
            button.setTitleColor(.label, for: .normal)
        }

        button.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        return button
    }
}
