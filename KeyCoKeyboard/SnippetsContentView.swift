import UIKit

final class SnippetsContentView: UIView {
    // MARK: - Public callbacks
    var onInsert: ((Snippet) -> Void)?
    var onCopy: ((Snippet) -> Void)?
    var onAdd: (() -> Void)?
    var onRename: ((Snippet) -> Void)?
    var onDelete: ((Snippet) -> Void)?
    var onTogglePin: ((Snippet) -> Void)?

    // MARK: - UI
    private let headerLabel = UILabel()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyLabel = UILabel()

    // MARK: - Data
    private var allSnippets: [Snippet] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
        reloadData()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public
    func reloadData() {
        allSnippets = SnippetsStore.shared.getAll()
        emptyLabel.isHidden = !allSnippets.isEmpty
        tableView.reloadData()
    }

    // MARK: - Setup
    private func setup() {
        backgroundColor = .clear

        headerLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        headerLabel.textColor = .systemGray
        headerLabel.text = "SNIPPETS"
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(headerLabel)

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(Cell.self, forCellReuseIdentifier: Cell.reuseId)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        tableView.keyboardDismissMode = .onDrag
        addSubview(tableView)

        emptyLabel.text = "Add your first snippet"
        emptyLabel.textColor = .secondaryLabel
        emptyLabel.font = .systemFont(ofSize: 15, weight: .regular)
        emptyLabel.textAlignment = .center
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyLabel.isHidden = true
        addSubview(emptyLabel)

        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            headerLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            headerLabel.trailingAnchor.constraint(equalTo: trailingAnchor),

            tableView.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 6),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor),

            emptyLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    // No search; table shows all snippets
}

// MARK: - Table
extension SnippetsContentView: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allSnippets.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Cell.reuseId, for: indexPath) as! Cell
        let item = allSnippets[indexPath.row]
        cell.configure(with: item)
        cell.onInsert = { [weak self] in self?.onInsert?(item) }
        cell.onCopy = { [weak self] in self?.onCopy?(item) }
        cell.onRename = { [weak self] in self?.onRename?(item) }
        cell.onDelete = { [weak self] in self?.onDelete?(item) }
        // Pinning removed
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = allSnippets[indexPath.row]
        onInsert?(item)
    }
}

// MARK: - Cell
private final class Cell: UITableViewCell {
    static let reuseId = "SnippetCell"

    let titleLabel = UILabel()
    let previewLabel = UILabel()
    let insertButton = UIButton(type: .system)

    var onInsert: (() -> Void)?
    var onCopy: (() -> Void)?
    var onRename: (() -> Void)?
    var onDelete: (() -> Void)?
    // Pin removed

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .default
        setup()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(with item: Snippet) {
        titleLabel.text = item.title
        previewLabel.text = item.text.replacingOccurrences(of: "\n", with: " ")
        previewLabel.textColor = .secondaryLabel
        accessibilityHint = "Double-tap to insert"
    }

    private func setup() {
        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        titleLabel.numberOfLines = 1
        previewLabel.font = .systemFont(ofSize: 13, weight: .regular)
        previewLabel.numberOfLines = 1

        // Circular grey insert button with arrow icon
        insertButton.backgroundColor = UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor.tertiarySystemBackground : UIColor.secondarySystemBackground
        }
        insertButton.tintColor = .label
        insertButton.setImage(UIImage(systemName: "arrow.up"), for: .normal)
        insertButton.translatesAutoresizingMaskIntoConstraints = false
        insertButton.layer.cornerRadius = 16
        insertButton.layer.cornerCurve = .continuous
        insertButton.widthAnchor.constraint(equalToConstant: 32).isActive = true
        insertButton.heightAnchor.constraint(equalToConstant: 32).isActive = true
        insertButton.addTarget(self, action: #selector(insertTapped), for: .touchUpInside)

        let titleStack = UIStackView(arrangedSubviews: [titleLabel, UIView()])
        titleStack.axis = .horizontal
        titleStack.alignment = .center
        titleStack.spacing = 8

        let rowStack = UIStackView()
        rowStack.axis = .horizontal
        rowStack.alignment = .center
        rowStack.spacing = 8
        rowStack.addArrangedSubview(titleStack)
        rowStack.addArrangedSubview(UIView()) // spacer
        rowStack.addArrangedSubview(insertButton)

        let v = UIStackView(arrangedSubviews: [rowStack, previewLabel])
        v.axis = .vertical
        v.alignment = .fill
        v.spacing = 4

        v.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(v)
        NSLayoutConstraint.activate([
            v.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            v.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            v.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            v.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        ])

        let interaction = UIContextMenuInteraction(delegate: self)
        contentView.addInteraction(interaction)
    }

    @objc private func insertTapped() { onInsert?() }
    @objc private func copyTapped() { onCopy?() }
}

extension Cell: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            guard let self = self else { return nil }
            return UIMenu(children: [
                UIAction(title: "Insert", image: UIImage(systemName: "arrow.up")) { _ in self.onInsert?() },
                UIAction(title: "Rename", image: UIImage(systemName: "pencil")) { _ in self.onRename?() },
                UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { _ in self.onDelete?() }
            ])
        }
    }
}


