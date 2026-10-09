import Foundation

struct CleanupHistoryService {
    private var historyURL: URL {
        FileSystemHelpers.reportsRoot.appendingPathComponent("cleanup-history.json")
    }

    func load() -> [CleanupHistoryEntry] {
        guard let data = try? Data(contentsOf: historyURL),
              let entries = try? JSONDecoder().decode([CleanupHistoryEntry].self, from: data) else {
            return []
        }
        return entries.sorted { $0.date > $1.date }
    }

    func append(action: String, itemCount: Int, bytes: Int, detail: String) {
        var entries = load()
        entries.append(CleanupHistoryEntry(
            id: UUID().uuidString,
            date: FileSystemHelpers.isoFormatter.string(from: Date()),
            action: action,
            itemCount: itemCount,
            bytes: bytes,
            detail: detail
        ))
        save(entries.sorted { $0.date > $1.date })
    }

    private func save(_ entries: [CleanupHistoryEntry]) {
        do {
            try FileSystemHelpers.ensureDirectory(FileSystemHelpers.reportsRoot)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(entries)
            try data.write(to: historyURL, options: .atomic)
        } catch {
            // Historico e auxiliar; falha nele nao deve bloquear limpeza/quarentena.
        }
    }
}
