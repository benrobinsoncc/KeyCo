import UIKit

/// Configuration view for Reply mode with collapsible settings
final class ReplyConfigView: UIView {

    // MARK: - Types

    enum ReplyLength: String {
        case short = "Short"
        case medium = "Medium"
        case long = "Long"
    }

    enum ReplySentiment: String {
        case positive = "Positive"
        case neutral = "Neutral"
        case negative = "Negative"
    }

    enum ReplyTone: String {
        case professional = "Professional"
        case casual = "Casual"
        case friendly = "Friendly"
    }

    // MARK: - Properties

    var onGenerate: ((String, ReplyLength, ReplySentiment, ReplyTone) -> Void)?

    private let previewLabel = UILabel()
    private let lengthRow = SettingRow(title: "Length", value: "Medium")
    private let sentimentRow = SettingRow(title: "Sentiment", value: "Neutral")
    private let toneRow = SettingRow(title: "Tone", value: "Professional")
    private let generateButton = UIButton(type: .system)

    private var selectedLength: ReplyLength = .medium
    private var selectedSentiment: ReplySentiment = .neutral
    private var selectedTone: ReplyTone = .professional
    private var copiedText: String = ""

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupLayout()
        checkClipboard()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupViews() {
        backgroundColor = .clear

        // Preview label
        previewLabel.font = .systemFont(ofSize: 14)
        previewLabel.textColor = .secondaryLabel
        previewLabel.numberOfLines = 3
        previewLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(previewLabel)

        // Setting rows
        lengthRow.translatesAutoresizingMaskIntoConstraints = false
        lengthRow.onTap = { [weak self] in self?.showLengthOptions() }
        addSubview(lengthRow)

        sentimentRow.translatesAutoresizingMaskIntoConstraints = false
        sentimentRow.onTap = { [weak self] in self?.showSentimentOptions() }
        addSubview(sentimentRow)

        toneRow.translatesAutoresizingMaskIntoConstraints = false
        toneRow.onTap = { [weak self] in self?.showToneOptions() }
        addSubview(toneRow)

        // Generate button
        generateButton.setTitle("Generate Reply", for: .normal)
        generateButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        generateButton.backgroundColor = .label
        generateButton.setTitleColor(UIColor { trait in
            trait.userInterfaceStyle == .dark ? .black : .white
        }, for: .normal)
        generateButton.layer.cornerRadius = 20
        generateButton.translatesAutoresizingMaskIntoConstraints = false
        generateButton.addTarget(self, action: #selector(generateTapped), for: .touchUpInside)
        addSubview(generateButton)
    }

    private func setupLayout() {
        NSLayoutConstraint.activate([
            previewLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            previewLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            previewLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),

            lengthRow.topAnchor.constraint(equalTo: previewLabel.bottomAnchor, constant: 16),
            lengthRow.leadingAnchor.constraint(equalTo: leadingAnchor),
            lengthRow.trailingAnchor.constraint(equalTo: trailingAnchor),
            lengthRow.heightAnchor.constraint(equalToConstant: 36),

            sentimentRow.topAnchor.constraint(equalTo: lengthRow.bottomAnchor, constant: 8),
            sentimentRow.leadingAnchor.constraint(equalTo: leadingAnchor),
            sentimentRow.trailingAnchor.constraint(equalTo: trailingAnchor),
            sentimentRow.heightAnchor.constraint(equalToConstant: 36),

            toneRow.topAnchor.constraint(equalTo: sentimentRow.bottomAnchor, constant: 8),
            toneRow.leadingAnchor.constraint(equalTo: leadingAnchor),
            toneRow.trailingAnchor.constraint(equalTo: trailingAnchor),
            toneRow.heightAnchor.constraint(equalToConstant: 36),

            generateButton.topAnchor.constraint(equalTo: toneRow.bottomAnchor, constant: 20),
            generateButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            generateButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            generateButton.heightAnchor.constraint(equalToConstant: 44),
            generateButton.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -8)
        ])
    }

    // MARK: - Actions

    private func checkClipboard() {
        if let text = UIPasteboard.general.string, !text.isEmpty {
            copiedText = text
            previewLabel.text = "\"\(text.prefix(100))...\""
        } else {
            previewLabel.text = "Copy a message first, then tap Generate"
            generateButton.isEnabled = false
            generateButton.alpha = 0.5
        }
    }

    @objc private func generateTapped() {
        guard !copiedText.isEmpty else { return }
        onGenerate?(copiedText, selectedLength, selectedSentiment, selectedTone)
    }

    private func showLengthOptions() {
        // TODO: Show picker with Short/Medium/Long
        // For now, cycle through options
        switch selectedLength {
        case .short: selectedLength = .medium
        case .medium: selectedLength = .long
        case .long: selectedLength = .short
        }
        lengthRow.setValue(selectedLength.rawValue)
    }

    private func showSentimentOptions() {
        switch selectedSentiment {
        case .positive: selectedSentiment = .neutral
        case .neutral: selectedSentiment = .negative
        case .negative: selectedSentiment = .positive
        }
        sentimentRow.setValue(selectedSentiment.rawValue)
    }

    private func showToneOptions() {
        switch selectedTone {
        case .professional: selectedTone = .casual
        case .casual: selectedTone = .friendly
        case .friendly: selectedTone = .professional
        }
        toneRow.setValue(selectedTone.rawValue)
    }
}

// MARK: - Setting Row

private class SettingRow: UIView {

    var onTap: (() -> Void)?

    private let titleLabel = UILabel()
    private let valueLabel = UILabel()
    private let editButton = UIButton(type: .system)

    init(title: String, value: String) {
        super.init(frame: .zero)

        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 15)
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)

        valueLabel.text = value
        valueLabel.font = .systemFont(ofSize: 15)
        valueLabel.textColor = .secondaryLabel
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(valueLabel)

        editButton.setTitle("Edit", for: .normal)
        editButton.titleLabel?.font = .systemFont(ofSize: 13)
        editButton.translatesAutoresizingMaskIntoConstraints = false
        editButton.addTarget(self, action: #selector(editTapped), for: .touchUpInside)
        addSubview(editButton)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            editButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            editButton.centerYAnchor.constraint(equalTo: centerYAnchor),

            valueLabel.trailingAnchor.constraint(equalTo: editButton.leadingAnchor, constant: -8),
            valueLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setValue(_ value: String) {
        valueLabel.text = value
    }

    @objc private func editTapped() {
        onTap?()
    }
}
