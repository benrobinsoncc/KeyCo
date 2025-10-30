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
        headerLabel.text = "PASTE"
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(headerLabel)

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(Cell.self, forCellReuseIdentifier: Cell.reuseId)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorInset = .zero
        tableView.separatorInsetReference = .fromCellEdges
        tableView.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        tableView.verticalScrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        tableView.layoutMargins = .zero
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
            headerLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            headerLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),

            tableView.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 6),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
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
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        onInsert?(item)
    }
}

// MARK: - Cell
private final class Cell: UITableViewCell {
    static let reuseId = "SnippetCell"

    let titleLabel = UILabel()
    let previewLabel = UILabel()

    var onInsert: (() -> Void)?
    var onCopy: (() -> Void)?
    var onRename: (() -> Void)?
    var onDelete: (() -> Void)?
    // Pin removed

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
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
        titleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        titleLabel.numberOfLines = 1
        previewLabel.font = .systemFont(ofSize: 13, weight: .regular)
        previewLabel.numberOfLines = 1

        // No explicit insert button; tapping the row inserts

        let titleStack = UIStackView(arrangedSubviews: [titleLabel, UIView()])
        titleStack.axis = .horizontal
        titleStack.alignment = .center
        titleStack.spacing = 8

        let v = UIStackView(arrangedSubviews: [titleStack, previewLabel])
        v.axis = .vertical
        v.alignment = .fill
        v.spacing = 1

        v.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(v)
        NSLayoutConstraint.activate([
            v.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            v.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 0),
            v.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 0),
            v.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        ])

        preservesSuperviewLayoutMargins = false
        layoutMargins = .zero
        separatorInset = .zero

        // No context menu; host app will manage snippet actions
    }

    @objc private func insertTapped() { onInsert?() }
    @objc private func copyTapped() { onCopy?() }
}

// Subtle press state similar to action bar: reduce text opacity when highlighted/selected
extension Cell {
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        let alpha: CGFloat = highlighted ? 0.4 : 1.0
        if animated {
            UIView.animate(withDuration: 0.15) {
                self.titleLabel.alpha = alpha
                self.previewLabel.alpha = alpha
            }
        } else {
            titleLabel.alpha = alpha
            previewLabel.alpha = alpha
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        let alpha: CGFloat = selected ? 0.4 : 1.0
        if animated {
            UIView.animate(withDuration: 0.15) {
                self.titleLabel.alpha = alpha
                self.previewLabel.alpha = alpha
            }
        } else {
            titleLabel.alpha = alpha
            previewLabel.alpha = alpha
        }
    }
}


