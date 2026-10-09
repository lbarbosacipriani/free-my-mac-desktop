import SwiftUI
import AppKit

struct CandidatesView: View {
    @EnvironmentObject private var appState: AppState
    @State private var riskFilter = "Todos"
    @State private var kindFilter = "Todos"
    @State private var searchText = ""
    @State private var showQuarantineConfirmation = false

    private var kindOptions: [String] {
        ["Todos"] + Array(Set(appState.candidates.map(\.kind))).sorted()
    }

    private var filteredCandidates: [Candidate] {
        appState.candidates.filter { candidate in
            let matchesRisk = riskFilter == "Todos" || candidate.risk == riskFilter
            let matchesKind = kindFilter == "Todos" || candidate.kind == kindFilter
            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            let matchesSearch = query.isEmpty
                || candidate.displayName.localizedCaseInsensitiveContains(query)
                || candidate.path.localizedCaseInsensitiveContains(query)
            return matchesRisk && matchesKind && matchesSearch
        }
    }

    private var selectedCandidate: Candidate? {
        guard appState.selectedCandidateIDs.count == 1,
              let id = appState.selectedCandidateIDs.first else {
            return nil
        }
        return appState.candidates.first { $0.id == id }
    }

    private var hasHighRiskSelection: Bool {
        appState.selectedCandidateIDs.contains { id in
            appState.candidates.first(where: { $0.id == id })?.risk == "alto"
        }
    }

    private var summaryBuckets: [CandidateSummaryBucket] {
        ["baixo", "medio", "alto"].map { risk in
            let items = appState.candidates.filter { $0.risk == risk }
            return CandidateSummaryBucket(
                id: risk,
                title: riskLabel(risk),
                count: items.count,
                bytes: items.reduce(0) { $0 + $1.sizeBytes },
                symbol: riskSymbol(risk)
            )
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HeaderView(
                title: "Candidatos",
                subtitle: "Revise os itens antes de mover para quarentena."
            )

            HStack(spacing: 12) {
                ForEach(summaryBuckets) { bucket in
                    CandidateSummaryTile(bucket: bucket)
                }
            }

            HStack(spacing: 12) {
                Picker("Risco", selection: $riskFilter) {
                    Text("Todos").tag("Todos")
                    Text("Baixo").tag("baixo")
                    Text("Medio").tag("medio")
                    Text("Alto").tag("alto")
                }
                .pickerStyle(.segmented)
                .frame(width: 300)

                Picker("Categoria", selection: $kindFilter) {
                    ForEach(kindOptions, id: \.self) { kind in
                        Text(kind == "Todos" ? "Todas categorias" : kindLabel(kind)).tag(kind)
                    }
                }
                .frame(width: 220)

                TextField("Buscar nome ou caminho", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .frame(minWidth: 220)
            }

            HStack {
                Text("\(appState.selectedCandidateIDs.count) selecionado(s) • \(appState.selectedBytes.humanSize)")
                    .foregroundStyle(.secondary)

                Text("\(filteredCandidates.count) visivel(is)")
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    appState.selectedCandidateIDs = Set(filteredCandidates.filter { $0.risk == "baixo" }.map(\.id))
                } label: {
                    Label("Selecionar baixo risco visivel", systemImage: "checklist")
                }
                .disabled(filteredCandidates.allSatisfy { $0.risk != "baixo" })

                Button {
                    appState.selectedCandidateIDs.removeAll()
                } label: {
                    Label("Limpar selecao", systemImage: "xmark.circle")
                }
                .disabled(appState.selectedCandidateIDs.isEmpty)

                Button {
                    openSelectedInFinder()
                } label: {
                    Label("Mostrar no Finder", systemImage: "folder")
                }
                .disabled(appState.selectedCandidateIDs.count != 1)

                Button(role: .destructive) {
                    showQuarantineConfirmation = true
                } label: {
                    Label("Mover para quarentena", systemImage: "archivebox")
                }
                .disabled(appState.selectedCandidateIDs.isEmpty || appState.isBusy)
            }

            if filteredCandidates.isEmpty {
                EmptyStateView(
                    "Nenhum candidato visivel",
                    systemImage: "line.3.horizontal.decrease.circle",
                    description: Text("Ajuste os filtros ou rode uma nova varredura.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                HSplitView {
                    Table(filteredCandidates, selection: $appState.selectedCandidateIDs) {
                        TableColumn("Nome") { candidate in
                            VStack(alignment: .leading, spacing: 2) {
                                Label(candidate.displayName, systemImage: candidate.kindSymbol)
                                    .fontWeight(.medium)
                                Text(candidate.path)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        TableColumn("Categoria") { Text($0.kindLabel) }
                        TableColumn("Tamanho") { Text($0.sizeBytes.humanSize) }
                        TableColumn("Idade") { Text("\($0.ageDays)d") }
                        TableColumn("Risco") { RiskBadge(risk: $0.risk) }
                        TableColumn("Motivo") { candidate in
                            Text(candidate.reason)
                                .lineLimit(2)
                        }
                    }

                    CandidateDetailPanel(candidate: selectedCandidate)
                        .frame(minWidth: 280, idealWidth: 320, maxWidth: 380)
                        .padding(.leading, 8)
                }
                .frame(minHeight: 280)
            }

            if hasHighRiskSelection {
                Label("Ha item de alto risco selecionado. Revise o detalhe antes de mover para quarentena.", systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
                    .font(.caption)
            }

            StatusStrip()
        }
        .padding(24)
        .confirmationDialog(
            "Mover itens para quarentena?",
            isPresented: $showQuarantineConfirmation,
            titleVisibility: .visible
        ) {
            Button("Mover \(appState.selectedCandidateIDs.count) item(ns)", role: .destructive) {
                Task { await appState.quarantineSelected() }
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Os arquivos saem do local original, mas podem ser restaurados pela tela Quarentena.")
        }
    }

    private func openSelectedInFinder() {
        guard let id = appState.selectedCandidateIDs.first,
              let candidate = appState.candidates.first(where: { $0.id == id }) else {
            return
        }
        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: candidate.path)])
    }

    private func kindLabel(_ kind: String) -> String {
        Candidate(
            id: "",
            kind: kind,
            path: "",
            sizeBytes: 0,
            modifiedAt: "",
            ageDays: 0,
            reason: "",
            risk: ""
        ).kindLabel
    }

    private func riskLabel(_ risk: String) -> String {
        switch risk {
        case "baixo": return "Baixo risco"
        case "medio": return "Medio risco"
        case "alto": return "Alto risco"
        default: return risk
        }
    }

    private func riskSymbol(_ risk: String) -> String {
        switch risk {
        case "baixo": return "checkmark.circle"
        case "medio": return "exclamationmark.circle"
        case "alto": return "exclamationmark.triangle"
        default: return "circle"
        }
    }
}

struct CandidateDetailPanel: View {
    let candidate: Candidate?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let candidate {
                Label(candidate.kindLabel, systemImage: candidate.kindSymbol)
                    .font(.headline)

                Text(candidate.displayName)
                    .font(.title3.weight(.semibold))
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                RiskBadge(risk: candidate.risk)

                Divider()

                DetailRow(title: "Tamanho", value: candidate.sizeBytes.humanSize)
                DetailRow(title: "Idade", value: "\(candidate.ageDays) dias")
                DetailRow(title: "Motivo", value: candidate.reason)
                DetailRow(title: "Por que apareceu aqui?", value: CandidateRuleHelp.explanation(for: candidate))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Caminho")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(candidate.path)
                        .font(.caption)
                        .textSelection(.enabled)
                        .lineLimit(6)
                }

                Spacer()
            } else {
                EmptyStateView(
                    "Selecione um item",
                    systemImage: "sidebar.right",
                    description: Text("O detalhe ajuda a decidir antes da quarentena.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}

struct DetailRow: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.callout)
                .textSelection(.enabled)
                .lineLimit(3)
        }
    }
}

enum CandidateRuleHelp {
    static func explanation(for candidate: Candidate) -> String {
        let category = categoryExplanation(candidate.kind)
        let risk = riskExplanation(candidate.risk)
        return "\(category) \(risk)"
    }

    private static func categoryExplanation(_ kind: String) -> String {
        switch kind {
        case "cache":
            return "Caches costumam ser recriados pelo app ou ferramenta, mas podem custar tempo para baixar novamente."
        case "log":
            return "Logs antigos ajudam em diagnostico, mas normalmente perdem valor com o tempo."
        case "installer":
            return "Instaladores antigos geralmente podem ser baixados novamente se forem necessarios."
        case "download":
            return "Downloads podem conter arquivos pessoais; por isso exigem revisao manual."
        case "devdata", "xcode-junk":
            return "Artefatos de desenvolvimento podem ser recriados, mas podem afetar builds e simuladores."
        case "devarchive":
            return "Archives do Xcode podem ser importantes para historico de distribuicao."
        case "document-version":
            return "Versoes locais de documentos sao sensiveis e devem ser revisadas com muito cuidado."
        default:
            return "Esse item veio de uma regra de varredura ativa."
        }
    }

    private static func riskExplanation(_ risk: String) -> String {
        switch risk {
        case "baixo":
            return "Risco baixo: normalmente seguro mover para quarentena apos revisar."
        case "medio":
            return "Risco medio: revise origem e impacto antes de mover."
        case "alto":
            return "Risco alto: nao selecione em lote; confira o caminho e o motivo."
        default:
            return "Revise antes de mover para quarentena."
        }
    }
}

struct CandidateSummaryBucket: Identifiable {
    let id: String
    let title: String
    let count: Int
    let bytes: Int
    let symbol: String
}

struct CandidateSummaryTile: View {
    let bucket: CandidateSummaryBucket

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(bucket.title, systemImage: bucket.symbol)
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline) {
                Text("\(bucket.count)")
                    .font(.title3.weight(.semibold))
                Text(bucket.bytes.humanSize)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}

struct RiskBadge: View {
    let risk: String

    var body: some View {
        Text(label)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.16), in: Capsule())
            .foregroundStyle(color)
    }

    private var label: String {
        switch risk {
        case "baixo": return "Baixo"
        case "medio": return "Medio"
        case "alto": return "Alto"
        default: return risk
        }
    }

    private var color: Color {
        switch risk {
        case "baixo": return .green
        case "medio": return .orange
        case "alto": return .red
        default: return .secondary
        }
    }
}
