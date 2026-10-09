import Foundation

struct NativeQuarantineService {
    private let fileManager = FileManager.default
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    func quarantine(candidates: [Candidate]) async -> QuarantineResult {
        await Task.detached(priority: .userInitiated) {
            moveToQuarantine(candidates: candidates)
        }.value
    }

    func sessions() async -> [QuarantineSession] {
        await Task.detached(priority: .utility) {
            listSessions()
        }.value
    }

    func restore(session: String, ids: [String]?, all: Bool) async -> RestoreResult {
        await Task.detached(priority: .userInitiated) {
            restoreItems(session: session, ids: ids, all: all)
        }.value
    }

    func purge(olderThanDays: Int, execute: Bool) async -> [QuarantineSession] {
        await Task.detached(priority: .userInitiated) {
            purgeSessions(olderThanDays: olderThanDays, execute: execute)
        }.value
    }

    private func moveToQuarantine(candidates: [Candidate]) -> QuarantineResult {
        guard !candidates.isEmpty else {
            return QuarantineResult(moved: 0, session: nil, manifest: nil, errors: [])
        }

        let session = sessionName()
        let sessionRoot = FileSystemHelpers.quarantineRoot.appendingPathComponent(session, isDirectory: true)
        let payloadRoot = sessionRoot.appendingPathComponent("payload", isDirectory: true)
        let manifestURL = sessionRoot.appendingPathComponent("manifest.jsonl")

        var moved = 0
        var errors: [String] = []
        var manifestLines: [String] = []

        do {
            try FileSystemHelpers.ensureDirectory(payloadRoot)
        } catch {
            return QuarantineResult(moved: 0, session: nil, manifest: nil, errors: [error.localizedDescription])
        }

        for candidate in candidates {
            let source = URL(fileURLWithPath: candidate.path)
            guard fileManager.fileExists(atPath: source.path) else {
                errors.append("Nao encontrado: \(candidate.path)")
                continue
            }

            var destination = payloadRoot
            for component in source.pathComponents where component != "/" {
                destination.appendPathComponent(component)
            }
            destination = FileSystemHelpers.uniqueDestination(for: destination)

            do {
                try FileSystemHelpers.ensureDirectory(destination.deletingLastPathComponent())
                try fileManager.moveItem(at: source, to: destination)
                moved += 1

                let item = QuarantineItem(
                    id: candidate.id,
                    kind: candidate.kind,
                    originalPath: candidate.path,
                    quarantinePath: destination.path,
                    sizeBytes: candidate.sizeBytes,
                    reason: candidate.reason,
                    sha256: nil,
                    movedAt: FileSystemHelpers.isoFormatter.string(from: Date())
                )
                if let data = try? encoder.encode(item), let line = String(data: data, encoding: .utf8) {
                    manifestLines.append(line)
                }
            } catch {
                errors.append("\(candidate.path): \(error.localizedDescription)")
            }
        }

        do {
            try manifestLines.joined(separator: "\n").appending("\n").write(to: manifestURL, atomically: true, encoding: .utf8)
        } catch {
            errors.append("Manifesto: \(error.localizedDescription)")
        }

        return QuarantineResult(moved: moved, session: session, manifest: manifestURL.path, errors: errors)
    }

    private func listSessions() -> [QuarantineSession] {
        guard fileManager.fileExists(atPath: FileSystemHelpers.quarantineRoot.path) else { return [] }
        guard let directories = try? fileManager.contentsOfDirectory(
            at: FileSystemHelpers.quarantineRoot,
            includingPropertiesForKeys: [.isDirectoryKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        return directories.compactMap { url in
            guard let values = try? url.resourceValues(forKeys: [.isDirectoryKey, .contentModificationDateKey]),
                  values.isDirectory == true else {
                return nil
            }

            let items = readManifest(sessionRoot: url)
            let modified = values.contentModificationDate ?? Date()
            let size = FileSystemHelpers.directorySize(url)

            return QuarantineSession(
                session: url.lastPathComponent,
                path: url.path,
                ageDays: FileSystemHelpers.ageDays(for: modified),
                sizeBytes: size,
                itemCount: items.count,
                items: items
            )
        }
        .sorted { $0.session > $1.session }
    }

    private func restoreItems(session: String, ids: [String]?, all: Bool) -> RestoreResult {
        let sessionRoot = FileSystemHelpers.quarantineRoot.appendingPathComponent(session, isDirectory: true)
        let items = readManifest(sessionRoot: sessionRoot)
        let allowed = Set(ids ?? [])
        var restored = 0
        var errors: [String] = []

        for item in items {
            guard all || allowed.contains(item.id) else { continue }

            let source = URL(fileURLWithPath: item.quarantinePath)
            let destination = URL(fileURLWithPath: item.originalPath)

            guard fileManager.fileExists(atPath: source.path) else {
                errors.append("Nao encontrado na quarentena: \(item.quarantinePath)")
                continue
            }

            guard !fileManager.fileExists(atPath: destination.path) else {
                errors.append("Destino ja existe: \(item.originalPath)")
                continue
            }

            do {
                try FileSystemHelpers.ensureDirectory(destination.deletingLastPathComponent())
                try fileManager.moveItem(at: source, to: destination)
                restored += 1
            } catch {
                errors.append("\(item.originalPath): \(error.localizedDescription)")
            }
        }

        return RestoreResult(restored: restored, errors: errors)
    }

    private func purgeSessions(olderThanDays: Int, execute: Bool) -> [QuarantineSession] {
        let targets = listSessions().filter { $0.ageDays >= olderThanDays }
        guard execute else { return targets }

        for session in targets {
            try? fileManager.removeItem(atPath: session.path)
        }
        return targets
    }

    private func readManifest(sessionRoot: URL) -> [QuarantineItem] {
        let manifestURL = sessionRoot.appendingPathComponent("manifest.jsonl")
        guard let contents = try? String(contentsOf: manifestURL, encoding: .utf8) else { return [] }

        return contents
            .split(separator: "\n")
            .compactMap { line in
                try? decoder.decode(QuarantineItem.self, from: Data(line.utf8))
            }
    }

    private func sessionName() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter.string(from: Date())
    }
}
