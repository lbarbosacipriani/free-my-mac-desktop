import Foundation

struct NativeScannerService {
    private let fileManager = FileManager.default
    private let installerExtensions = Set(["dmg", "iso", "pkg", "mpkg", "zip", "tar", "tgz", "gz", "xz", "bz2"])
    private let logExtensions = Set(["log", "trace", "crash", "ips", "spin", "diag", "txt"])
    private let xcodeLogExtensions = Set(["xcactivitylog", "log", "txt", "trace", "diag"])
    private let protectedPrefixes = [
        "/System",
        "/bin",
        "/sbin",
        "/usr/bin",
        "/usr/sbin",
        "/Applications",
        "/Library/Apple"
    ]

    func scan(minimumSizeMB: Int, olderThanDays: Int, includeSystem: Bool) async -> ScanReport {
        await Task.detached(priority: .userInitiated) {
            buildReport(minimumSizeMB: minimumSizeMB, olderThanDays: olderThanDays, includeSystem: includeSystem)
        }.value
    }

    private func buildReport(minimumSizeMB: Int, olderThanDays: Int, includeSystem: Bool) -> ScanReport {
        let minimumBytes = minimumSizeMB * 1_048_576
        var candidates: [Candidate] = []

        let home = FileSystemHelpers.homeURL
        let scanRoots: [(URL, String, String)] = [
            (home.appendingPathComponent("Library/Logs", isDirectory: true), "log", "Log antigo do usuario"),
            (home.appendingPathComponent("Library/Caches", isDirectory: true), "cache", "Cache antigo do usuario"),
            (home.appendingPathComponent(".cache", isDirectory: true), "cache", "Cache antigo do usuario"),
            (home.appendingPathComponent(".npm/_cacache", isDirectory: true), "cache", "Cache antigo do npm"),
            (home.appendingPathComponent("Downloads", isDirectory: true), "installer", "Instalador ou arquivo compactado antigo"),
            (home.appendingPathComponent("Downloads", isDirectory: true), "download", "Arquivo antigo na pasta Downloads"),
            (home.appendingPathComponent("Library/Developer/Xcode/DerivedData", isDirectory: true), "devdata", "Dados derivados do Xcode"),
            (home.appendingPathComponent("Library/Developer/Xcode/Archives", isDirectory: true), "devarchive", "Arquivo antigo do Xcode"),
            (home.appendingPathComponent("Library/Developer/Xcode/iOS DeviceSupport", isDirectory: true), "xcode-junk", "Suporte antigo de dispositivos iOS no Xcode"),
            (home.appendingPathComponent("Library/Developer/Xcode/watchOS DeviceSupport", isDirectory: true), "xcode-junk", "Suporte antigo de dispositivos watchOS no Xcode"),
            (home.appendingPathComponent("Library/Developer/Xcode/tvOS DeviceSupport", isDirectory: true), "xcode-junk", "Suporte antigo de dispositivos tvOS no Xcode"),
            (home.appendingPathComponent("Library/Developer/Xcode/UserData/Previews", isDirectory: true), "xcode-junk", "Cache antigo de previews do Xcode"),
            (home.appendingPathComponent("Library/Developer/Xcode/Products", isDirectory: true), "xcode-junk", "Produto intermediario antigo do Xcode")
        ]

        for (root, kind, reason) in scanRoots {
            if ["devdata", "devarchive", "xcode-junk"].contains(kind) {
                candidates.append(contentsOf: directoryCandidates(
                    root: root,
                    kind: kind,
                    reason: reason,
                    minimumBytes: minimumBytes,
                    olderThanDays: kind == "devarchive" ? max(olderThanDays * 3, olderThanDays) : olderThanDays
                ))
            } else {
                candidates.append(contentsOf: fileCandidates(
                    root: root,
                    kind: kind,
                    reason: reason,
                    minimumBytes: minimumBytes,
                    olderThanDays: olderThanDays
                ))
            }
        }

        candidates.append(contentsOf: scopedFileCandidates(
            root: home.appendingPathComponent("Library/Containers", isDirectory: true),
            kind: "cache",
            reason: "Cache antigo dentro de apps do usuario",
            requiredPathFragments: ["/Data/Library/Caches/"],
            allowedExtensions: nil,
            minimumBytes: minimumBytes,
            olderThanDays: olderThanDays
        ))
        candidates.append(contentsOf: scopedFileCandidates(
            root: home.appendingPathComponent("Library/Group Containers", isDirectory: true),
            kind: "cache",
            reason: "Cache antigo dentro de grupos de apps do usuario",
            requiredPathFragments: ["/Library/Caches/"],
            allowedExtensions: nil,
            minimumBytes: minimumBytes,
            olderThanDays: olderThanDays
        ))
        candidates.append(contentsOf: scopedFileCandidates(
            root: home.appendingPathComponent("Library/Containers", isDirectory: true),
            kind: "log",
            reason: "Log antigo dentro de apps do usuario",
            requiredPathFragments: ["/Data/Library/Logs/", "/Data/Library/DiagnosticReports/"],
            allowedExtensions: logExtensions,
            minimumBytes: minimumBytes,
            olderThanDays: olderThanDays
        ))
        candidates.append(contentsOf: scopedFileCandidates(
            root: home.appendingPathComponent("Library/Group Containers", isDirectory: true),
            kind: "log",
            reason: "Log antigo dentro de grupos de apps do usuario",
            requiredPathFragments: ["/Library/Logs/", "/Library/DiagnosticReports/"],
            allowedExtensions: logExtensions,
            minimumBytes: minimumBytes,
            olderThanDays: olderThanDays
        ))
        candidates.append(contentsOf: scopedFileCandidates(
            root: home.appendingPathComponent("Library/Developer/Xcode/DerivedData", isDirectory: true),
            kind: "xcode-log",
            reason: "Log antigo de build do Xcode",
            requiredPathFragments: ["/Logs/Build/", "/Logs/Test/", "/Logs/Launch/"],
            allowedExtensions: xcodeLogExtensions,
            minimumBytes: max(1_048_576, minimumBytes / 10),
            olderThanDays: olderThanDays
        ))
        candidates.append(contentsOf: scopedFileCandidates(
            root: home.appendingPathComponent("Library/Developer/Xcode", isDirectory: true),
            kind: "xcode-log",
            reason: "Log antigo relacionado ao Xcode",
            requiredPathFragments: ["/Logs/", "/UserData/Previews/"],
            allowedExtensions: xcodeLogExtensions,
            minimumBytes: max(1_048_576, minimumBytes / 10),
            olderThanDays: olderThanDays
        ))

        if includeSystem {
            let systemRoots: [(URL, String, String)] = [
                (URL(fileURLWithPath: "/Library/Logs", isDirectory: true), "log", "Log global antigo acessivel"),
                (URL(fileURLWithPath: "/Library/Caches", isDirectory: true), "cache", "Cache global antigo acessivel"),
                (URL(fileURLWithPath: "/private/var/log", isDirectory: true), "log", "Log do sistema antigo acessivel"),
                (URL(fileURLWithPath: "/.DocumentRevisions-V100", isDirectory: true), "document-version", "Versao local antiga de documento gerenciada pelo macOS")
            ]
            for (root, kind, reason) in systemRoots {
                if kind == "document-version" {
                    candidates.append(contentsOf: directoryCandidates(
                        root: root,
                        kind: kind,
                        reason: reason,
                        minimumBytes: minimumBytes,
                        olderThanDays: max(olderThanDays * 3, olderThanDays)
                    ))
                } else {
                    candidates.append(contentsOf: fileCandidates(
                        root: root,
                        kind: kind,
                        reason: reason,
                        minimumBytes: minimumBytes,
                        olderThanDays: olderThanDays
                    ))
                }
            }
        }

        for rule in RuleDiscoveryService().activeRules() {
            candidates.append(contentsOf: ruleCandidates(for: rule, minimumBytes: minimumBytes, olderThanDays: olderThanDays))
        }

        candidates = candidates
            .sorted { $0.sizeBytes > $1.sizeBytes }
            .enumerated()
            .map { index, candidate in
                Candidate(
                    id: "native-\(index + 1)",
                    kind: candidate.kind,
                    path: candidate.path,
                    sizeBytes: candidate.sizeBytes,
                    modifiedAt: candidate.modifiedAt,
                    ageDays: candidate.ageDays,
                    reason: candidate.reason,
                    risk: candidate.risk
                )
            }

        let total = candidates.reduce(0) { $0 + $1.sizeBytes }
        return ScanReport(
            generatedAt: FileSystemHelpers.isoFormatter.string(from: Date()),
            policy: ScanPolicy(
                scanHome: home.path,
                minSizeMB: minimumSizeMB,
                olderThanDays: olderThanDays,
                includeSystem: includeSystem,
                note: "Varredura nativa conservadora com caches de usuario, Downloads, sobras do Xcode, logs e Document Versions quando locais globais estiverem ativados."
            ),
            totalSizeBytes: total,
            candidates: candidates
        )
    }

    func simulate(rule: CleanupRule, minimumSizeMB: Int, olderThanDays: Int) async -> [Candidate] {
        await Task.detached(priority: .userInitiated) {
            ruleCandidates(
                for: rule,
                minimumBytes: minimumSizeMB * 1_048_576,
                olderThanDays: olderThanDays
            )
            .sorted { $0.sizeBytes > $1.sizeBytes }
            .enumerated()
            .map { index, candidate in
                Candidate(
                    id: "rule-\(rule.id)-\(index + 1)",
                    kind: candidate.kind,
                    path: candidate.path,
                    sizeBytes: candidate.sizeBytes,
                    modifiedAt: candidate.modifiedAt,
                    ageDays: candidate.ageDays,
                    reason: candidate.reason,
                    risk: candidate.risk
                )
            }
        }.value
    }

    private func fileCandidates(root: URL, kind: String, reason: String, minimumBytes: Int, olderThanDays: Int) -> [Candidate] {
        guard fileManager.fileExists(atPath: root.path), !isProtected(root) else { return [] }

        let keys: [URLResourceKey] = [.isRegularFileKey, .isDirectoryKey, .isSymbolicLinkKey, .fileSizeKey, .contentModificationDateKey]
        guard let enumerator = fileManager.enumerator(
            at: root,
            includingPropertiesForKeys: keys,
            options: [.skipsPackageDescendants]
        ) else {
            return []
        }

        var result: [Candidate] = []
        for case let url as URL in enumerator {
            guard !isProtected(url), let values = try? url.resourceValues(forKeys: Set(keys)) else {
                enumerator.skipDescendants()
                continue
            }

            if values.isSymbolicLink == true {
                if values.isDirectory == true {
                    enumerator.skipDescendants()
                }
                continue
            }

            if values.isDirectory == true {
                continue
            }

            guard values.isRegularFile == true else { continue }
            guard kind != "installer" || installerExtensions.contains(url.pathExtension.lowercased()) else { continue }
            guard kind != "download" || !installerExtensions.contains(url.pathExtension.lowercased()) else { continue }

            let size = values.fileSize ?? 0
            guard size >= minimumBytes else { continue }

            let modified = values.contentModificationDate ?? Date.distantPast
            let age = FileSystemHelpers.ageDays(for: modified)
            guard age >= olderThanDays else { continue }

            result.append(Candidate(
                id: UUID().uuidString,
                kind: kind,
                path: url.path,
                sizeBytes: size,
                modifiedAt: FileSystemHelpers.isoFormatter.string(from: modified),
                ageDays: age,
                reason: reason,
                risk: risk(for: kind, path: url.path)
            ))
        }

        return result
    }

    private func scopedFileCandidates(
        root: URL,
        kind: String,
        reason: String,
        requiredPathFragments: [String],
        allowedExtensions: Set<String>?,
        minimumBytes: Int,
        olderThanDays: Int
    ) -> [Candidate] {
        guard fileManager.fileExists(atPath: root.path), !isProtected(root) else { return [] }

        let keys: [URLResourceKey] = [.isRegularFileKey, .isDirectoryKey, .isSymbolicLinkKey, .fileSizeKey, .contentModificationDateKey]
        guard let enumerator = fileManager.enumerator(
            at: root,
            includingPropertiesForKeys: keys,
            options: [.skipsPackageDescendants]
        ) else {
            return []
        }

        var result: [Candidate] = []
        for case let url as URL in enumerator {
            guard !isProtected(url), let values = try? url.resourceValues(forKeys: Set(keys)) else {
                enumerator.skipDescendants()
                continue
            }

            if values.isSymbolicLink == true {
                if values.isDirectory == true {
                    enumerator.skipDescendants()
                }
                continue
            }

            guard values.isRegularFile == true else { continue }
            guard requiredPathFragments.contains(where: { url.path.contains($0) }) else { continue }
            if let allowedExtensions, !allowedExtensions.contains(url.pathExtension.lowercased()) {
                continue
            }

            let size = values.fileSize ?? 0
            guard size >= minimumBytes else { continue }

            let modified = values.contentModificationDate ?? Date.distantPast
            let age = FileSystemHelpers.ageDays(for: modified)
            guard age >= olderThanDays else { continue }

            result.append(Candidate(
                id: UUID().uuidString,
                kind: kind,
                path: url.path,
                sizeBytes: size,
                modifiedAt: FileSystemHelpers.isoFormatter.string(from: modified),
                ageDays: age,
                reason: reason,
                risk: risk(for: kind, path: url.path)
            ))
        }

        return result
    }

    private func directoryCandidates(root: URL, kind: String, reason: String, minimumBytes: Int, olderThanDays: Int) -> [Candidate] {
        guard fileManager.fileExists(atPath: root.path), !isProtected(root) else { return [] }
        guard let children = try? fileManager.contentsOfDirectory(
            at: root,
            includingPropertiesForKeys: [.isDirectoryKey, .isSymbolicLinkKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        var result: [Candidate] = []
        for url in children {
            guard !isProtected(url) else { continue }
            guard let values = try? url.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey, .contentModificationDateKey]) else { continue }
            guard values.isDirectory == true, values.isSymbolicLink != true else { continue }

            let modified = values.contentModificationDate ?? Date.distantPast
            let age = FileSystemHelpers.ageDays(for: modified)
            guard age >= olderThanDays else { continue }

            let size = FileSystemHelpers.directorySize(url)
            guard size >= minimumBytes else { continue }

            result.append(Candidate(
                id: UUID().uuidString,
                kind: kind,
                path: url.path,
                sizeBytes: size,
                modifiedAt: FileSystemHelpers.isoFormatter.string(from: modified),
                ageDays: age,
                reason: reason,
                risk: risk(for: kind, path: url.path)
            ))
        }

        return result
    }

    private func ruleCandidates(for rule: CleanupRule, minimumBytes: Int, olderThanDays: Int) -> [Candidate] {
        let root = URL(fileURLWithPath: rule.expandedPath, isDirectory: true)
        guard fileManager.fileExists(atPath: root.path), !isProtected(root) else { return [] }

        switch rule.matchMode {
        case .files:
            return fileCandidates(
                root: root,
                kind: rule.kind,
                reason: "Regra ativa: \(rule.reason)",
                minimumBytes: minimumBytes,
                olderThanDays: olderThanDays
            ).map { candidate in
                Candidate(
                    id: candidate.id,
                    kind: candidate.kind,
                    path: candidate.path,
                    sizeBytes: candidate.sizeBytes,
                    modifiedAt: candidate.modifiedAt,
                    ageDays: candidate.ageDays,
                    reason: candidate.reason,
                    risk: rule.risk
                )
            }
        case .topLevelDirectories:
            return directoryCandidates(
                root: root,
                kind: rule.kind,
                reason: "Regra ativa: \(rule.reason)",
                minimumBytes: minimumBytes,
                olderThanDays: olderThanDays
            ).map { candidate in
                Candidate(
                    id: candidate.id,
                    kind: candidate.kind,
                    path: candidate.path,
                    sizeBytes: candidate.sizeBytes,
                    modifiedAt: candidate.modifiedAt,
                    ageDays: candidate.ageDays,
                    reason: candidate.reason,
                    risk: rule.risk
                )
            }
        case .namedDirectoriesRecursive:
            return namedDirectoryCandidates(
                root: root,
                names: Set(rule.targetNames),
                kind: rule.kind,
                reason: "Regra ativa: \(rule.reason)",
                minimumBytes: minimumBytes,
                olderThanDays: olderThanDays,
                risk: rule.risk
            )
        }
    }

    private func namedDirectoryCandidates(
        root: URL,
        names: Set<String>,
        kind: String,
        reason: String,
        minimumBytes: Int,
        olderThanDays: Int,
        risk: String
    ) -> [Candidate] {
        guard !names.isEmpty, fileManager.fileExists(atPath: root.path), !isProtected(root) else { return [] }
        let keys: [URLResourceKey] = [.isDirectoryKey, .isSymbolicLinkKey, .contentModificationDateKey]
        guard let enumerator = fileManager.enumerator(
            at: root,
            includingPropertiesForKeys: keys,
            options: [.skipsPackageDescendants, .skipsHiddenFiles]
        ) else {
            return []
        }

        var result: [Candidate] = []
        for case let url as URL in enumerator {
            guard !isProtected(url), let values = try? url.resourceValues(forKeys: Set(keys)) else {
                enumerator.skipDescendants()
                continue
            }
            guard values.isDirectory == true, values.isSymbolicLink != true else { continue }

            if names.contains(url.lastPathComponent) {
                enumerator.skipDescendants()
                let modified = values.contentModificationDate ?? Date.distantPast
                let age = FileSystemHelpers.ageDays(for: modified)
                guard age >= olderThanDays else { continue }

                let size = FileSystemHelpers.directorySize(url)
                guard size >= minimumBytes else { continue }

                result.append(Candidate(
                    id: UUID().uuidString,
                    kind: kind,
                    path: url.path,
                    sizeBytes: size,
                    modifiedAt: FileSystemHelpers.isoFormatter.string(from: modified),
                    ageDays: age,
                    reason: reason,
                    risk: risk
                ))
            }
        }
        return result
    }

    private func isProtected(_ url: URL) -> Bool {
        let path = url.standardizedFileURL.path
        return protectedPrefixes.contains { path == $0 || path.hasPrefix($0 + "/") }
    }

    private func risk(for kind: String, path: String) -> String {
        if kind == "document-version" {
            return "alto"
        }
        if kind == "devarchive" {
            return "medio"
        }
        if kind == "xcode-junk" && path.contains("DeviceSupport") {
            return "medio"
        }
        if kind == "xcode-log" {
            return "baixo"
        }
        if kind == "download" {
            return "medio"
        }
        if path.hasPrefix("/Library") || path.hasPrefix("/private/var") {
            return "medio"
        }
        return "baixo"
    }
}
