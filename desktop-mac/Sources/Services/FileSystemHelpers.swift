import Foundation

enum FileSystemHelpers {
    static let fileManager = FileManager.default
    static let isoFormatter = ISO8601DateFormatter()

    static var homeURL: URL {
        fileManager.homeDirectoryForCurrentUser
    }

    static var projectRoot: URL {
        homeURL.appendingPathComponent("Documents/dev/free-my-mac-desktop", isDirectory: true)
    }

    static var reportsRoot: URL {
        projectRoot.appendingPathComponent("reports", isDirectory: true)
    }

    static var quarantineRoot: URL {
        projectRoot.appendingPathComponent("quarantine", isDirectory: true)
    }

    static var logsRoot: URL {
        projectRoot.appendingPathComponent("logs", isDirectory: true)
    }

    static func ensureDirectory(_ url: URL) throws {
        try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
    }

    static func ageDays(for date: Date, now: Date = Date()) -> Int {
        max(0, Int(now.timeIntervalSince(date) / 86_400))
    }

    static func directorySize(_ url: URL) -> Int {
        let keys: [URLResourceKey] = [.isRegularFileKey, .isDirectoryKey, .isSymbolicLinkKey, .fileSizeKey]
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: keys,
            options: [.skipsPackageDescendants, .skipsHiddenFiles]
        ) else {
            return 0
        }

        var total = 0
        for case let itemURL as URL in enumerator {
            guard let values = try? itemURL.resourceValues(forKeys: Set(keys)) else { continue }
            if values.isSymbolicLink == true {
                if values.isDirectory == true {
                    enumerator.skipDescendants()
                }
                continue
            }
            if values.isRegularFile == true {
                total += values.fileSize ?? 0
            }
        }
        return total
    }

    static func uniqueDestination(for url: URL) -> URL {
        guard fileManager.fileExists(atPath: url.path) else { return url }

        let directory = url.deletingLastPathComponent()
        let baseName = url.deletingPathExtension().lastPathComponent
        let pathExtension = url.pathExtension

        for index in 1...10_000 {
            let candidateName = pathExtension.isEmpty
                ? "\(baseName)-\(index)"
                : "\(baseName)-\(index).\(pathExtension)"
            let candidate = directory.appendingPathComponent(candidateName)
            if !fileManager.fileExists(atPath: candidate.path) {
                return candidate
            }
        }

        return directory.appendingPathComponent("\(baseName)-\(UUID().uuidString)")
    }
}
