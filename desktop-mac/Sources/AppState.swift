import Foundation
import AppKit
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    @Published var selectedSection: SidebarSection = .overview
    @Published var appStatus: AppRuntimeStatus = .ready
    @Published var scanStatus = ScanStatus.idle
    @Published var report: ScanReport?
    @Published var candidates: [Candidate] = []
    @Published var selectedCandidateIDs: Set<String> = []
    @Published var quarantineSessions: [QuarantineSession] = []
    @Published var cleanupHistory: [CleanupHistoryEntry] = []
    @Published var lastMessage = "App pronto."
    @Published var isBusy = false
    @Published var minimumSizeMB: Int {
        didSet { UserDefaults.standard.set(minimumSizeMB, forKey: DefaultsKeys.minimumSizeMB) }
    }
    @Published var olderThanDays: Int {
        didSet { UserDefaults.standard.set(olderThanDays, forKey: DefaultsKeys.olderThanDays) }
    }
    @Published var includeSystemLocations: Bool {
        didSet { UserDefaults.standard.set(includeSystemLocations, forKey: DefaultsKeys.includeSystemLocations) }
    }
    @Published var purgeRetentionDays: Int {
        didSet { UserDefaults.standard.set(purgeRetentionDays, forKey: DefaultsKeys.purgeRetentionDays) }
    }

    let projectPath = FileSystemHelpers.projectRoot.path

    private let scanner = NativeScannerService()
    private let quarantine = NativeQuarantineService()
    private let history = CleanupHistoryService()
    private var scanTimerTask: Task<Void, Never>?

    init() {
        let defaults = UserDefaults.standard
        let savedMinimumSize = defaults.integer(forKey: DefaultsKeys.minimumSizeMB)
        let savedOlderThan = defaults.integer(forKey: DefaultsKeys.olderThanDays)
        let savedPurgeDays = defaults.integer(forKey: DefaultsKeys.purgeRetentionDays)

        self.minimumSizeMB = savedMinimumSize == 0 ? 50 : savedMinimumSize
        self.olderThanDays = savedOlderThan == 0 ? 30 : savedOlderThan
        self.includeSystemLocations = defaults.bool(forKey: DefaultsKeys.includeSystemLocations)
        self.purgeRetentionDays = savedPurgeDays == 0 ? 30 : savedPurgeDays
    }

    var selectedCandidates: [Candidate] {
        candidates.filter { selectedCandidateIDs.contains($0.id) }
    }

    var selectedBytes: Int {
        selectedCandidates.reduce(0) { $0 + $1.sizeBytes }
    }

    func refreshAll() async {
        appStatus = .ready
        await refreshSessions()
        cleanupHistory = history.load()
        loadLastReport()
        lastMessage = "Dados atualizados."
    }

    func startScan() async {
        guard !isBusy else { return }

        isBusy = true
        appStatus = .scanning
        selectedCandidateIDs.removeAll()
        let started = Date().timeIntervalSince1970
        scanStatus = ScanStatus(
            running: true,
            startedAt: started,
            finishedAt: nil,
            elapsedSeconds: 0,
            message: "Varrendo arquivos locais com regras conservadoras...",
            error: nil,
            candidateCount: 0,
            totalSizeBytes: 0
        )
        lastMessage = scanStatus.message
        startScanTimer(started: started)

        let report = await scanner.scan(
            minimumSizeMB: minimumSizeMB,
            olderThanDays: olderThanDays,
            includeSystem: includeSystemLocations
        )

        apply(report: report)
        save(report: report)

        let finished = Date().timeIntervalSince1970
        scanStatus = ScanStatus(
            running: false,
            startedAt: started,
            finishedAt: finished,
            elapsedSeconds: finished - started,
            message: "Varredura concluida: \(report.candidates.count) candidato(s), \(report.totalSizeBytes.humanSize).",
            error: nil,
            candidateCount: report.candidates.count,
            totalSizeBytes: report.totalSizeBytes
        )
        lastMessage = scanStatus.message
        appStatus = .ready
        stopScanTimer()
        isBusy = false
    }

    func refreshSessions() async {
        quarantineSessions = await quarantine.sessions()
    }

    func quarantineSelected() async {
        guard !selectedCandidateIDs.isEmpty, !isBusy else { return }

        isBusy = true
        appStatus = .quarantining
        let movingIDs = selectedCandidateIDs
        let movingBytes = selectedBytes
        let result = await quarantine.quarantine(candidates: selectedCandidates)
        removeMovedCandidates(movingIDs: movingIDs, movedCount: result.moved)
        selectedCandidateIDs.removeAll()
        await refreshSessions()
        if result.moved > 0 {
            history.append(
                action: "Quarentena",
                itemCount: result.moved,
                bytes: movingBytes,
                detail: "Itens movidos para quarentena. Espaco recuperavel apos purga permanente."
            )
            cleanupHistory = history.load()
        }

        if result.errors.isEmpty {
            lastMessage = "Movidos para quarentena: \(result.moved)."
        } else {
            lastMessage = "Movidos: \(result.moved). Pendencias: \(result.errors.count)."
        }

        appStatus = .ready
        isBusy = false
    }

    func quarantineLowRiskCandidates() async {
        let lowRiskIDs = Set(candidates.filter { $0.risk == "baixo" }.map(\.id))
        guard !lowRiskIDs.isEmpty else {
            lastMessage = "Nenhum item de baixo risco para mover."
            return
        }
        selectedCandidateIDs = lowRiskIDs
        await quarantineSelected()
    }

    func restore(session: String, ids: [String]? = nil, all: Bool = false) async {
        guard !isBusy else { return }

        isBusy = true
        appStatus = .restoring
        let result = await quarantine.restore(session: session, ids: ids, all: all)
        lastMessage = result.errors.isEmpty
            ? "Restaurados: \(result.restored)."
            : "Restaurados: \(result.restored). Pendencias: \(result.errors.count)."
        await refreshSessions()
        appStatus = .ready
        isBusy = false
    }

    func purge(olderThanDays: Int, execute: Bool) async {
        guard !isBusy else { return }

        isBusy = true
        appStatus = .purging
        let sessions = await quarantine.purge(olderThanDays: olderThanDays, execute: execute)
        if execute && !sessions.isEmpty {
            history.append(
                action: "Liberado permanentemente",
                itemCount: sessions.reduce(0) { $0 + $1.itemCount },
                bytes: sessions.reduce(0) { $0 + $1.sizeBytes },
                detail: "Sessoes antigas apagadas da quarentena."
            )
            cleanupHistory = history.load()
        }
        lastMessage = execute
            ? "Apagadas permanentemente: \(sessions.count) sessao(oes)."
            : "Simulacao: \(sessions.count) sessao(oes) antiga(s)."
        await refreshSessions()
        appStatus = .ready
        isBusy = false
    }

    func openLogs() {
        try? FileSystemHelpers.ensureDirectory(FileSystemHelpers.logsRoot)
        NSWorkspace.shared.open(FileSystemHelpers.logsRoot)
    }

    func openReports() {
        try? FileSystemHelpers.ensureDirectory(FileSystemHelpers.reportsRoot)
        NSWorkspace.shared.open(FileSystemHelpers.reportsRoot)
    }

    var totalQuarantinedBytes: Int {
        cleanupHistory
            .filter { $0.action == "Quarentena" }
            .reduce(0) { $0 + $1.bytes }
    }

    var totalPermanentlyFreedBytes: Int {
        cleanupHistory
            .filter { $0.action == "Liberado permanentemente" }
            .reduce(0) { $0 + $1.bytes }
    }

    private func apply(report: ScanReport) {
        self.report = report
        self.candidates = report.candidates
    }

    private func removeMovedCandidates(movingIDs: Set<String>, movedCount: Int) {
        guard movedCount > 0 else { return }
        candidates.removeAll { movingIDs.contains($0.id) }
        let total = candidates.reduce(0) { $0 + $1.sizeBytes }
        if let current = report {
            report = ScanReport(
                generatedAt: current.generatedAt,
                policy: current.policy,
                totalSizeBytes: total,
                candidates: candidates
            )
        }
    }

    private func save(report: ScanReport) {
        do {
            try FileSystemHelpers.ensureDirectory(FileSystemHelpers.reportsRoot)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(report)
            try data.write(to: FileSystemHelpers.reportsRoot.appendingPathComponent("native-latest.json"), options: .atomic)
            try markdown(for: report).write(
                to: FileSystemHelpers.reportsRoot.appendingPathComponent("native-latest.md"),
                atomically: true,
                encoding: .utf8
            )
        } catch {
            lastMessage = "Relatorio gerado, mas nao foi possivel salvar: \(error.localizedDescription)"
        }
    }

    private func loadLastReport() {
        let url = FileSystemHelpers.reportsRoot.appendingPathComponent("native-latest.json")
        guard let data = try? Data(contentsOf: url),
              let report = try? JSONDecoder().decode(ScanReport.self, from: data) else {
            return
        }
        apply(report: report)
        scanStatus = ScanStatus(
            running: false,
            startedAt: nil,
            finishedAt: nil,
            elapsedSeconds: 0,
            message: "Ultimo relatorio carregado.",
            error: nil,
            candidateCount: report.candidates.count,
            totalSizeBytes: report.totalSizeBytes
        )
    }

    private func markdown(for report: ScanReport) -> String {
        var lines: [String] = [
            "# Relatorio nativo - Free My Mac Desktop",
            "",
            "- Gerado em: \(report.generatedAt)",
            "- Candidatos: \(report.candidates.count)",
            "- Espaco potencial: \(report.totalSizeBytes.humanSize)",
            "",
            "## Regras usadas",
            "",
            "- Nada e apagado automaticamente durante a varredura.",
            "- Itens precisam ser movidos para quarentena antes de remocao permanente.",
            "- Regras descobertas por documentacao so entram na varredura depois de ativacao manual.",
            "- Regras ativas extras: \(RuleDiscoveryService().activeRules().map(\.title).joined(separator: ", "))",
            "",
            "| Tipo | Tamanho | Idade | Risco | Caminho |",
            "| --- | ---: | ---: | --- | --- |"
        ]

        for candidate in report.candidates {
            lines.append("| \(candidate.kind) | \(candidate.sizeBytes.humanSize) | \(candidate.ageDays)d | \(candidate.risk) | `\(candidate.path)` |")
        }

        return lines.joined(separator: "\n") + "\n"
    }

    private func startScanTimer(started: Double) {
        scanTimerTask?.cancel()
        scanTimerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                await MainActor.run {
                    guard let self, self.scanStatus.running else { return }
                    let now = Date().timeIntervalSince1970
                    self.scanStatus = ScanStatus(
                        running: true,
                        startedAt: started,
                        finishedAt: nil,
                        elapsedSeconds: now - started,
                        message: self.scanStatus.message,
                        error: nil,
                        candidateCount: self.scanStatus.candidateCount,
                        totalSizeBytes: self.scanStatus.totalSizeBytes
                    )
                }
            }
        }
    }

    private func stopScanTimer() {
        scanTimerTask?.cancel()
        scanTimerTask = nil
    }
}

private enum DefaultsKeys {
    static let minimumSizeMB = "cleanMyMac.minimumSizeMB"
    static let olderThanDays = "cleanMyMac.olderThanDays"
    static let includeSystemLocations = "cleanMyMac.includeSystemLocations"
    static let purgeRetentionDays = "cleanMyMac.purgeRetentionDays"
}

enum SidebarSection: String, CaseIterable, Identifiable {
    case overview
    case scan
    case candidates
    case rules
    case developer
    case history
    case quarantine
    case help
    case logs

    var id: String { rawValue }

    var title: String {
        switch self {
        case .overview: return "Visao geral"
        case .scan: return "Varredura"
        case .candidates: return "Candidatos"
        case .rules: return "Regras"
        case .developer: return "Desenvolvedor"
        case .history: return "Historico"
        case .quarantine: return "Quarentena"
        case .help: return "Ajuda"
        case .logs: return "Logs"
        }
    }

    var symbol: String {
        switch self {
        case .overview: return "gauge"
        case .scan: return "magnifyingglass"
        case .candidates: return "list.bullet.rectangle"
        case .rules: return "slider.horizontal.3"
        case .developer: return "terminal"
        case .history: return "chart.bar"
        case .quarantine: return "archivebox"
        case .help: return "questionmark.circle"
        case .logs: return "doc.text"
        }
    }
}

enum AppRuntimeStatus: Equatable {
    case ready
    case scanning
    case quarantining
    case restoring
    case purging
    case error(String)

    var label: String {
        switch self {
        case .ready: return "App pronto"
        case .scanning: return "Varrendo"
        case .quarantining: return "Movendo para quarentena"
        case .restoring: return "Restaurando"
        case .purging: return "Apagando"
        case .error(let message): return message
        }
    }
}
