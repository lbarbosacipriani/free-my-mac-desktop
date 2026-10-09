import SwiftUI
import AppKit

struct DocumentationView: View {
    @State private var appDocuments: [AppDocument] = []
    @State private var selectedDocumentID: String?
    @State private var searchText = ""

    private let service = DocumentationService()

    private var selectedDocument: AppDocument? {
        appDocuments.first { $0.id == selectedDocumentID } ?? appDocuments.first
    }

    private var searchResults: [DocumentSearchResult] {
        service.search(searchText, in: appDocuments)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HeaderView(
                title: "Ajuda",
                subtitle: "Documentacao local usada para explicar regras, riscos e decisoes de limpeza."
            )

            HStack(spacing: 12) {
                List {
                    ForEach(Swift.Array<Int>(0..<appDocuments.count), id: \.self) { (index: Int) in
                        let document = appDocuments[index]
                        VStack(alignment: .leading, spacing: 3) {
                            Text(document.title)
                                .fontWeight(.medium)
                            Text(document.statusLabel)
                                .font(.caption)
                                .foregroundStyle(document.exists ? Color.secondary : Color.orange)
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedDocumentID = document.id
                        }
                    }
                }
                .frame(minWidth: 240, idealWidth: 280, maxWidth: 320)

                VStack(alignment: .leading, spacing: 12) {
                    TextField("Buscar nos docs", text: $searchText)
                        .textFieldStyle(.roundedBorder)

                    if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        SearchResultsView(results: searchResults)
                    } else if let selectedDocument {
                        DocumentReaderView(document: selectedDocument)
                    } else {
                        EmptyStateView(
                            "Nenhum documento",
                            systemImage: "doc.text.magnifyingglass",
                            description: Text("Os documentos esperados nao foram encontrados.")
                        )
                    }
                }
            }

            HStack {
                Spacer()
                Button {
                    if let selectedDocument {
                        NSWorkspace.shared.open(URL(fileURLWithPath: selectedDocument.path))
                    }
                } label: {
                    Label("Abrir arquivo", systemImage: "arrow.up.right.square")
                }
                .disabled(selectedDocument?.exists != true)
            }
        }
        .padding(24)
        .task {
            appDocuments = service.loadDocuments()
            selectedDocumentID = appDocuments.first(where: \.exists)?.id ?? appDocuments.first?.id
        }
    }
}

private struct DocumentReaderView: View {
    let document: AppDocument

    var body: some View {
        if !document.exists {
            EmptyStateView(
                "Documento ausente",
                systemImage: "exclamationmark.triangle",
                description: Text(document.path)
            )
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(document.sections) { section in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(section.title)
                                .font(section.level <= 1 ? .title2.weight(.semibold) : .headline)
                            if !section.body.isEmpty {
                                Text(section.body)
                                    .font(.callout)
                                    .textSelection(.enabled)
                            }
                        }
                        Divider()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.trailing, 8)
            }
        }
    }
}

private struct SearchResultsView: View {
    let results: [DocumentSearchResult]

    var body: some View {
        if results.isEmpty {
            EmptyStateView(
                "Nada encontrado",
                systemImage: "magnifyingglass",
                description: Text("Tente outro termo.")
            )
        } else {
            List(results) { result in
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.sectionTitle)
                        .fontWeight(.medium)
                    Text(result.documentTitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(result.excerpt)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
                .padding(.vertical, 4)
            }
        }
    }
}
