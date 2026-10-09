import Foundation

struct DocumentationService {
    private let expectedDocs: [(id: String, title: String, relativePath: String)] = [
        ("desktop-readme", "README do app desktop", "desktop-mac/README.md"),
        ("native-refinement", "Refinamento app nativo", "sprints/2026-10-apple-ux-redesign/native_app_only_refinement.md"),
        ("apple-ux-backlog", "Backlog Apple UX", "sprints/2026-10-apple-ux-redesign/apple_ux_backlog.md"),
        ("technical-plan", "Plano tecnico", "sprints/2026-10-apple-ux-redesign/technical_plan.md"),
        ("log-research", "Pesquisa de logs no macOS", "sprints/2026-09-clean-my-mac-roadmap/macos_log_cleanup_research.md"),
        ("acceptance", "Criterios de aceite", "sprints/2026-09-clean-my-mac-roadmap/acceptance_criteria.md")
    ]

    func loadDocuments() -> [AppDocument] {
        expectedDocs.map { entry in
            let url = FileSystemHelpers.projectRoot.appendingPathComponent(entry.relativePath)
            guard let text = try? String(contentsOf: url, encoding: .utf8) else {
                return AppDocument(
                    id: entry.id,
                    title: entry.title,
                    path: url.path,
                    exists: false,
                    sections: []
                )
            }

            return AppDocument(
                id: entry.id,
                title: entry.title,
                path: url.path,
                exists: true,
                sections: parseSections(text: text, fallbackTitle: entry.title)
            )
        }
    }

    func search(_ query: String, in documents: [AppDocument]) -> [DocumentSearchResult] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return [] }

        var results: [DocumentSearchResult] = []
        for document in documents where document.exists {
            for section in document.sections {
                let haystack = "\(section.title)\n\(section.body)"
                guard haystack.localizedCaseInsensitiveContains(needle) else { continue }
                results.append(DocumentSearchResult(
                    id: "\(document.id)-\(section.id)",
                    documentTitle: document.title,
                    sectionTitle: section.title,
                    excerpt: excerpt(from: haystack, matching: needle)
                ))
            }
        }
        return results
    }

    private func parseSections(text: String, fallbackTitle: String) -> [DocumentSection] {
        var sections: [DocumentSection] = []
        var currentTitle = fallbackTitle
        var currentLevel = 1
        var currentBody: [String] = []
        var index = 0

        func flush() {
            let body = currentBody.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            sections.append(DocumentSection(
                id: "\(index)-\(currentTitle)",
                level: currentLevel,
                title: currentTitle,
                body: body
            ))
            index += 1
        }

        for line in text.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("#") {
                flush()
                let hashes = trimmed.prefix { $0 == "#" }.count
                currentLevel = hashes
                currentTitle = trimmed.dropFirst(hashes).trimmingCharacters(in: .whitespaces)
                currentBody = []
            } else {
                currentBody.append(line)
            }
        }
        flush()

        return sections.filter { !$0.title.isEmpty || !$0.body.isEmpty }
    }

    private func excerpt(from text: String, matching query: String) -> String {
        let collapsed = text.replacingOccurrences(of: "\n", with: " ")
        guard let range = collapsed.range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) else {
            return String(collapsed.prefix(180))
        }
        let lower = collapsed.index(range.lowerBound, offsetBy: -80, limitedBy: collapsed.startIndex) ?? collapsed.startIndex
        let upper = collapsed.index(range.upperBound, offsetBy: 120, limitedBy: collapsed.endIndex) ?? collapsed.endIndex
        return String(collapsed[lower..<upper])
    }
}
