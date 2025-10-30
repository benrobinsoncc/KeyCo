import Foundation

struct Snippet: Codable, Equatable, Identifiable {
    let id: UUID
    var title: String
    var text: String
    var pinned: Bool
    var lastUsed: Date?
}

/// Lightweight local store for snippets. Backed by UserDefaults with an in-memory cache.
final class SnippetsStore {
    static let shared = SnippetsStore()

    private let storageKey = "KeyCo_Snippets_v1"
    private let userDefaults: UserDefaults
    private var cache: [Snippet] = []
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        load()
        seedDefaultsIfNeeded()
    }

    // MARK: - Public API

    func getAll() -> [Snippet] {
        // Preserve insertion order; no automatic resorting
        return cache
    }

    func search(_ query: String) -> [Snippet] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return getAll() }
        let lower = trimmed.lowercased()
        // Preserve original order; no sorting
        return cache.filter { $0.title.lowercased().contains(lower) || $0.text.lowercased().contains(lower) }
    }

    @discardableResult
    func add(title: String, text: String, pinned: Bool = false) -> Snippet {
        let item = Snippet(id: UUID(), title: title, text: text, pinned: pinned, lastUsed: nil)
        cache.append(item)
        persist()
        return item
    }

    func rename(id: UUID, newTitle: String) {
        guard let index = cache.firstIndex(where: { $0.id == id }) else { return }
        cache[index].title = newTitle
        persist()
    }

    func updateText(id: UUID, newText: String) {
        guard let index = cache.firstIndex(where: { $0.id == id }) else { return }
        cache[index].text = newText
        persist()
    }

    func togglePin(id: UUID) {
        guard let index = cache.firstIndex(where: { $0.id == id }) else { return }
        cache[index].pinned.toggle()
        persist()
    }

    func delete(id: UUID) {
        cache.removeAll { $0.id == id }
        persist()
    }

    func markUsed(id: UUID) { /* intentionally no-op to keep ordering stable */ }

    // MARK: - Private

    private func load() {
        guard let data = userDefaults.data(forKey: storageKey) else {
            cache = []
            return
        }
        do {
            cache = try decoder.decode([Snippet].self, from: data)
        } catch {
            // Corrupt data; reset
            cache = []
        }
    }

    private func persist() {
        do {
            let data = try encoder.encode(cache)
            userDefaults.set(data, forKey: storageKey)
            userDefaults.synchronize()
        } catch {
            // Ignore persist errors in extension context
        }
    }

    private func seedDefaultsIfNeeded() {
        guard cache.isEmpty else { return }
        var seeded: [Snippet] = []
        func make(_ title: String, _ text: String, _ pinned: Bool = false) {
            seeded.append(Snippet(id: UUID(), title: title, text: text, pinned: pinned, lastUsed: nil))
        }

        // Minimal helpful defaults; replace values as needed later
        make("Email", "ben@benrobinson.cc", true)
        make("Website", "https://www.benrobinson.cc")
        make("Phone", "+44 0000 000000")
        make("Address", "123 Example Street, London, UK")
        make("Not interested", "Thanks for reaching out. I’m not interested in this role right now.")

        cache = seeded
        persist()
    }

    // No sorting; maintain insertion order
}


