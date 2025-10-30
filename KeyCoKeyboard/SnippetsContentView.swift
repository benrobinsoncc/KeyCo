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
    private let searchField = UISearchBar()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyLabel = UILabel()

    // MARK: - Data
    private var allSnippets: [Snippet] = []
    private var filteredSnippets: [Snippet] = []

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
        applyFilter()
    }

    func focusSearch() {
        searchField.becomeFirstResponder()
    }

    // MARK: - Setup
    private func setup() {
        backgroundColor = .clear

        searchField.placeholder = "Search snippets"
        searchField.searchBarStyle = .minimal
        searchField.translatesAutoresizingMaskIntoConstraints = false
        searchField.delegate = self
        addSubview(searchField)

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
            searchField.topAnchor.constraint(equalTo: topAnchor),
            searchField.leadingAnchor.constraint(equalTo: leadingAnchor),
            searchField.trailingAnchor.constraint(equalTo: trailingAnchor),

            tableView.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 4),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor),

            emptyLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    private func applyFilter() {
        let q = searchField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if q.isEmpty {
            filteredSnippets = allSnippets
        } else {
            filteredSnippets = SnippetsStore.shared.search(q)
        }
        emptyLabel.isHidden = !filteredSnippets.isEmpty
        tableView.reloadData()
    }
}

// MARK: - Table
extension SnippetsContentView: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredSnippets.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Cell.reuseId, for: indexPath) as! Cell
        let item = filteredSnippets[indexPath.row]
        cell.configure(with: item)
        cell.onInsert = { [weak self] in self?.onInsert?(item) }
        cell.onCopy = { [weak self] in self?.onCopy?(item) }
        cell.onRename = { [weak self] in self?.onRename?(item) }
        cell.onDelete = { [weak self] in self?.onDelete?(item) }
        cell.onTogglePin = { [weak self] in self?.onTogglePin?(item) }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = filteredSnippets[indexPath.row]
        onInsert?(item)
    }
}

// MARK: - Search
extension SnippetsContentView: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        applyFilter()
    }
}

// MARK: - Cell
private final class Cell: UITableViewCell {
    static let reuseId = "SnippetCell"

    let titleLabel = UILabel()
    let previewLabel = UILabel()
    let pinButton = UIButton(type: .system)
    let insertButton = UIButton(type: .system)
    let copyButton = UIButton(type: .system)

    var onInsert: (() -> Void)?
    var onCopy: (() -> Void)?
    var onRename: (() -> Void)?
    var onDelete: (() -> Void)?
    var onTogglePin: (() -> Void)?

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
        pinButton.setImage(UIImage(systemName: item.pinned ? "pin.fill" : "pin"), for: .normal)
        accessibilityHint = "Double-tap to insert"
    }

    private func setup() {
        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        titleLabel.numberOfLines = 1
        previewLabel.font = .systemFont(ofSize: 13, weight: .regular)
        previewLabel.numberOfLines = 1

        pinButton.tintColor = .label
        pinButton.addTarget(self, action: #selector(pinTapped), for: .touchUpInside)

        insertButton.setTitle("Insert", for: .normal)
        insertButton.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
        insertButton.addTarget(self, action: #selector(insertTapped), for: .touchUpInside)

        copyButton.setTitle("Copy", for: .normal)
        copyButton.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
        copyButton.addTarget(self, action: #selector(copyTapped), for: .touchUpInside)

        let titleStack = UIStackView(arrangedSubviews: [titleLabel, UIView() , pinButton])
        titleStack.axis = .horizontal
        titleStack.alignment = .center
        titleStack.spacing = 8

        let actionStack = UIStackView(arrangedSubviews: [insertButton, copyButton])
        actionStack.axis = .horizontal
        actionStack.alignment = .center
        actionStack.spacing = 12

        let v = UIStackView(arrangedSubviews: [titleStack, previewLabel, actionStack])
        v.axis = .vertical
        v.alignment = .fill
        v.spacing = 4

        v.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(v)
        NSLayoutConstraint.activate([
            v.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            v.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            v.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            v.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        ])

        let interaction = UIContextMenuInteraction(delegate: self)
        contentView.addInteraction(interaction)
    }

    @objc private func insertTapped() { onInsert?() }
    @objc private func copyTapped() { onCopy?() }
    @objc private func pinTapped() { onTogglePin?() }
}

extension Cell: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            guard let self = self else { return nil }
            return UIMenu(children: [
                UIAction(title: "Insert", image: UIImage(systemName: "arrow.up")) { _ in self.onInsert?() },
                UIAction(title: "Copy", image: UIImage(systemName: "doc.on.doc")) { _ in self.onCopy?() },
                UIAction(title: "Rename", image: UIImage(systemName: "pencil")) { _ in self.onRename?() },
                UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { _ in self.onDelete?() }
            ])
        }
    }
}


