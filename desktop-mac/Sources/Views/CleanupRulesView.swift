import SwiftUI

struct CleanupRulesView: View {
    @EnvironmentObject private var appState: AppState
    @State private var appDocuments: [AppDocument] = []
    @State private var rules: [CleanupRule] = []
    @State private var selectedRuleID: String?
    @State private var simulatedCandidates: [Candidate] = []
    @State private var isSimulating = false

    private let docs = DocumentationService()
    private let discovery = RuleDiscoveryService()
    private let scanner = NativeScannerService()

    private var selectedRule: CleanupRule? {
        rules.first { $0.id == selectedRuleID } ?? rules.first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HeaderView(
                title: "Regras",
                subtitle: "Novas possibilidades de limpeza descobertas a partir da documentacao local."
            )

            HSplitView {
                List {
                    ForEach(Swift.Array<Int>(0..<rules.count), id: \.self) { (index: Int) in
                        let rule = rules[index]
                        RuleRow(rule: rule)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedRuleID = rule.id
                            }
                    }
                }
                .frame(minWidth: 300, idealWidth: 360, maxWidth: 420)

                RuleDetailView(
                    rule: selectedRule,
                    simulatedCandidates: simulatedCandidates,
                    isSimulating: isSimulating,
                    promote: promoteSelected,
                    ignore: ignoreSelected,
                    reset: resetSelected,
                    simulate: simulateSelected
                )
                .frame(minWidth: 440)
            }

            StatusStrip()
        }
        .padding(24)
        .task { reload() }
    }

    private func reload() {
        appDocuments = docs.loadDocuments()
        rules = discovery.rules(from: appDocuments)
        selectedRuleID = selectedRuleID ?? rules.first?.id
    }

    private func promoteSelected() {
        guard let selectedRule else { return }
        discovery.promote(selectedRule)
        reload()
    }

    private func ignoreSelected() {
        guard let selectedRule else { return }
        discovery.ignore(selectedRule)
        reload()
    }

    private func resetSelected() {
        guard let selectedRule else { return }
        discovery.reset(selectedRule)
        reload()
    }

    private func simulateSelected() {
        guard let selectedRule else { return }
        isSimulating = true
        simulatedCandidates = []
        Task {
            let result = await scanner.simulate(
                rule: selectedRule,
                minimumSizeMB: appState.minimumSizeMB,
                olderThanDays: appState.olderThanDays
            )
            await MainActor.run {
                simulatedCandidates = result
                isSimulating = false
            }
        }
    }
}

private struct RuleRow: View {
    let rule: CleanupRule

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(rule.title)
                    .fontWeight(.medium)
                Spacer()
                Text(rule.statusLabel)
                    .font(.caption)
                    .foregroundStyle(color)
            }
            Text(rule.pathPattern)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Text(rule.sourceDocument)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.vertical, 4)
    }

    private var color: Color {
        switch rule.status {
        case .active: return .green
        case .suggested: return .orange
        case .ignored: return .secondary
        }
    }
}

private struct RuleDetailView: View {
    let rule: CleanupRule?
    let simulatedCandidates: [Candidate]
    let isSimulating: Bool
    let promote: () -> Void
    let ignore: () -> Void
    let reset: () -> Void
    let simulate: () -> Void

    var body: some View {
        if let rule {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(rule.title)
                            .font(.title2.weight(.semibold))
                        Text(rule.pathPattern)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }
                    Spacer()
                    RiskBadge(risk: rule.risk)
                }

                DetailRow(title: "Status", value: rule.statusLabel)
                DetailRow(title: "Motivo", value: rule.reason)
                DetailRow(title: "Origem", value: "\(rule.sourceDocument) / \(rule.sourceSection)")

                HStack {
                    Button {
                        simulate()
                    } label: {
                        Label("Simular", systemImage: "play.circle")
                    }
                    .disabled(isSimulating)

                    Button {
                        promote()
                    } label: {
                        Label("Ativar regra", systemImage: "checkmark.circle")
                    }
                    .disabled(rule.status == .active)

                    Button {
                        ignore()
                    } label: {
                        Label("Ignorar", systemImage: "eye.slash")
                    }
                    .disabled(rule.status == .ignored)

                    Button {
                        reset()
                    } label: {
                        Label("Voltar para sugerida", systemImage: "arrow.counterclockwise")
                    }
                    .disabled(rule.status == .suggested)
                }

                Divider()

                HStack {
                    Text("Simulacao")
                        .font(.headline)
                    Spacer()
                    if isSimulating {
                        ProgressView()
                    } else {
                        Text("\(simulatedCandidates.count) candidato(s)")
                            .foregroundStyle(.secondary)
                    }
                }

                if simulatedCandidates.isEmpty && !isSimulating {
                    EmptyStateView(
                        "Nenhum resultado simulado",
                        systemImage: "doc.text.magnifyingglass",
                        description: Text("Clique em Simular para testar essa regra sem ativa-la.")
                    )
                } else {
                    Table(simulatedCandidates) {
                        TableColumn("Nome") { Text($0.displayName) }
                        TableColumn("Tamanho") { Text($0.sizeBytes.humanSize) }
                        TableColumn("Idade") { Text("\($0.ageDays)d") }
                    }
                }
            }
        } else {
            EmptyStateView(
                "Nenhuma regra",
                systemImage: "slider.horizontal.3",
                description: Text("Os docs ainda nao sugeriram regras de limpeza.")
            )
        }
    }
}
