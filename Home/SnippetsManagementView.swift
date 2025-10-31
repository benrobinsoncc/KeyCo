import SwiftUI

struct SnippetsManagementView: View {
    @StateObject private var store = SnippetsStore.shared
    @State private var showingAddSheet = false
    @State private var editingSnippet: Snippet?
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(store.getAll()) { snippet in
                    SnippetRow(snippet: snippet, onEdit: {
                        editingSnippet = $0
                    }, onDelete: { snippetToDelete in
                        store.delete(id: snippetToDelete.id)
                    })
                }
                .onDelete(perform: deleteSnippets)
            }
            .navigationTitle("Snippets")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                            Text("New")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddEditSnippetView(
                    mode: .add,
                    onSave: { title, text in
                        store.add(title: title, text: text)
                        showingAddSheet = false
                    },
                    onCancel: {
                        showingAddSheet = false
                    }
                )
            }
            .sheet(item: $editingSnippet) { snippet in
                AddEditSnippetView(
                    mode: .edit(snippet),
                    onSave: { title, text in
                        if let id = snippet.id as? UUID {
                            store.rename(id: id, newTitle: title)
                            store.updateText(id: id, newText: text)
                        }
                        editingSnippet = nil
                    },
                    onCancel: {
                        editingSnippet = nil
                    }
                )
            }
        }
    }
    
    private func deleteSnippets(at offsets: IndexSet) {
        let snippets = store.getAll()
        for index in offsets {
            if let id = snippets[index].id as? UUID {
                store.delete(id: id)
            }
        }
    }
}

struct SnippetRow: View {
    let snippet: Snippet
    let onEdit: (Snippet) -> Void
    let onDelete: (Snippet) -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(snippet.title)
                    .font(.headline)
                    .foregroundStyle(Color(uiColor: .label))
                
                Text(snippet.text)
                    .font(.subheadline)
                    .foregroundStyle(Color(uiColor: .secondaryLabel))
                    .lineLimit(2)
            }
            .padding(.vertical, 4)
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onEdit(snippet)
        }
        .contextMenu {
            Button(role: .destructive, action: {
                onDelete(snippet)
            }) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

enum AddEditMode {
    case add
    case edit(Snippet)
}

struct AddEditSnippetView: View {
    let mode: AddEditMode
    let onSave: (String, String) -> Void
    let onCancel: () -> Void
    
    @State private var title: String = ""
    @State private var text: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $title)
                    TextField("Text", text: $text, axis: .vertical)
                        .lineLimit(3...10)
                }
            }
            .navigationTitle(modeTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(title, text)
                    }
                    .disabled(title.isEmpty || text.isEmpty)
                }
            }
        }
        .onAppear {
            if case .edit(let snippet) = mode {
                title = snippet.title
                text = snippet.text
            }
        }
    }
    
    private var modeTitle: String {
        switch mode {
        case .add: return "New Snippet"
        case .edit: return "Edit Snippet"
        }
    }
}

#Preview {
    SnippetsManagementView()
}

