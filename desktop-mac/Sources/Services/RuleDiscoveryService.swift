import Foundation

struct RuleDiscoveryService {
    private let activeKey = "cleanMyMac.activeCleanupRuleIDs"
    private let ignoredKey = "cleanMyMac.ignoredCleanupRuleIDs"

    func rules(from documents: [AppDocument] = DocumentationService().loadDocuments()) -> [CleanupRule] {
        let active = Set(UserDefaults.standard.stringArray(forKey: activeKey) ?? [])
        let ignored = Set(UserDefaults.standard.stringArray(forKey: ignoredKey) ?? [])

        return candidateRules(from: documents).map { rule in
            var mutable = rule
            if active.contains(rule.id) {
                mutable.status = .active
            } else if ignored.contains(rule.id) {
                mutable.status = .ignored
            }
            return mutable
        }
    }

    func activeRules() -> [CleanupRule] {
        rules().filter { $0.status == .active }
    }

    func promote(_ rule: CleanupRule) {
        updateSet(key: activeKey) { $0.insert(rule.id) }
        updateSet(key: ignoredKey) { $0.remove(rule.id) }
    }

    func ignore(_ rule: CleanupRule) {
        updateSet(key: ignoredKey) { $0.insert(rule.id) }
        updateSet(key: activeKey) { $0.remove(rule.id) }
    }

    func reset(_ rule: CleanupRule) {
        updateSet(key: ignoredKey) { $0.remove(rule.id) }
        updateSet(key: activeKey) { $0.remove(rule.id) }
    }

    private func candidateRules(from documents: [AppDocument]) -> [CleanupRule] {
        let corpus = documents
            .flatMap(\.sections)
            .map { "\($0.title)\n\($0.body)" }
            .joined(separator: "\n")
            .lowercased()

        let definitions: [(id: String, title: String, path: String, kind: String, risk: String, reason: String, keyword: String, mode: CleanupRuleMatchMode, names: [String])] = [
            ("python-venvs", "Python virtual environments", "~/Documents", "devdata", "medio", "Ambientes virtuais Python antigos podem ser recriados, mas podem conter dependencias especificas.", "venv", .namedDirectoriesRecursive, [".venv", "venv", "env", ".tox"]),
            ("node-modules", "Node modules antigos", "~/Documents", "devdata", "medio", "Dependencias de projetos podem ser reinstaladas, mas nao devem ser removidas sem revisar o projeto.", "node_modules", .namedDirectoriesRecursive, ["node_modules"]),
            ("rust-targets", "Rust target dirs", "~/Documents", "devdata", "baixo", "Artefatos de build do Cargo normalmente podem ser recriados.", "target", .namedDirectoriesRecursive, ["target"]),
            ("web-build-artifacts", "Web build artifacts", "~/Documents", "devdata", "baixo", "Builds frontend como `.next`, `dist` e `build` podem ser recriados, mas revise projetos ativos.", "dist", .namedDirectoriesRecursive, [".next", ".nuxt", "dist", "build", ".svelte-kit"]),
            ("ruby-bundles", "Ruby bundle/vendor dirs", "~/Documents", "devdata", "medio", "Dependencias Ruby podem ser reinstaladas, mas podem depender de versoes especificas.", "bundle", .namedDirectoriesRecursive, [".bundle", "vendor/bundle"]),
            ("go-cache-mod", "Go module cache", "~/go/pkg/mod", "cache", "medio", "Cache de modulos Go pode ser baixado novamente, mas pode afetar trabalho offline.", "golang", .topLevelDirectories, []),
            ("flutter-dart-artifacts", "Flutter/Dart artifacts", "~/Documents", "devdata", "baixo", "Artefatos Dart/Flutter de build e tooling normalmente podem ser recriados.", "flutter", .namedDirectoriesRecursive, [".dart_tool", ".flutter-plugins-dependencies"]),
            ("gradle-cache", "Gradle cache", "~/.gradle/caches", "cache", "medio", "Cache de builds Gradle; pode ser recriado, mas pode afetar builds offline.", "gradle", .topLevelDirectories, []),
            ("maven-cache", "Maven repository cache", "~/.m2/repository", "cache", "medio", "Cache local Maven pode ser baixado novamente, mas pode afetar builds offline.", "maven", .topLevelDirectories, []),
            ("homebrew-cache", "Homebrew cache", "~/Library/Caches/Homebrew", "cache", "baixo", "Downloads/cache do Homebrew geralmente podem ser refeitos.", "homebrew", .files, []),
            ("core-simulator", "CoreSimulator", "~/Library/Developer/CoreSimulator", "xcode-junk", "medio", "Simuladores antigos podem ocupar muito espaco; revisar antes.", "coresimulator", .topLevelDirectories, []),
            ("python-pycache", "Python caches", "~/Documents", "cache", "baixo", "Caches Python de teste e bytecode em projetos locais.", "pytest", .namedDirectoriesRecursive, ["__pycache__", ".pytest_cache", ".mypy_cache", ".ruff_cache"]),
            ("huggingface-cache", "HuggingFace cache", "~/.cache/huggingface", "cache", "medio", "Modelos podem ser grandes; remover pode exigir novo download.", "huggingface", .topLevelDirectories, []),
            ("docker-cache", "Docker caches", "~/Library/Containers/com.docker.docker", "cache", "medio", "Sobras do Docker podem ser grandes, mas dependem do uso atual do Docker.", "docker", .files, [])
        ]

        return definitions.compactMap { item in
            guard corpus.contains(item.keyword) || ["homebrew-cache", "python-pycache", "python-venvs", "node-modules", "rust-targets", "web-build-artifacts", "ruby-bundles", "go-cache-mod", "flutter-dart-artifacts"].contains(item.id) else {
                return nil
            }
            return CleanupRule(
                id: item.id,
                title: item.title,
                pathPattern: item.path,
                kind: item.kind,
                risk: item.risk,
                reason: item.reason,
                sourceDocument: sourceDocumentTitle(for: item.keyword, documents: documents),
                sourceSection: sourceSectionTitle(for: item.keyword, documents: documents),
                matchMode: item.mode,
                targetNames: item.names,
                status: .suggested
            )
        }
    }

    private func sourceDocumentTitle(for keyword: String, documents: [AppDocument]) -> String {
        documents.first { document in
            document.sections.contains { section in
                "\(section.title)\n\(section.body)".localizedCaseInsensitiveContains(keyword)
            }
        }?.title ?? "Regra sugerida pelo catalogo local"
    }

    private func sourceSectionTitle(for keyword: String, documents: [AppDocument]) -> String {
        documents.flatMap(\.sections).first { section in
            "\(section.title)\n\(section.body)".localizedCaseInsensitiveContains(keyword)
        }?.title ?? "Sugestao inicial"
    }

    private func updateSet(key: String, mutate: (inout Set<String>) -> Void) {
        var values = Set(UserDefaults.standard.stringArray(forKey: key) ?? [])
        mutate(&values)
        UserDefaults.standard.set(Array(values).sorted(), forKey: key)
    }
}
