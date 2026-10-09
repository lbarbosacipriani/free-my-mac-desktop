import SwiftUI

struct OverviewView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HeaderView(
                    title: "Visao geral",
                    subtitle: "Acompanhe a ultima varredura, revise candidatos e mantenha a quarentena sob controle."
                )

                OverviewHero(
                    potentialBytes: appState.report?.totalSizeBytes ?? 0,
                    candidateCount: appState.candidates.count,
                    lowRiskCount: lowRiskCount,
                    isBusy: appState.isBusy,
                    startScan: { Task { await appState.startScan() } },
                    reviewCandidates: { appState.selectedSection = .candidates }
                )

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 170), spacing: 12)], spacing: 12) {
                    MetricCard(title: "Estado", value: appState.appStatus.label, symbol: "checkmark.seal", tint: .green)
                    MetricCard(title: "Candidatos", value: "\(appState.candidates.count)", symbol: "list.bullet.rectangle", tint: .teal)
                    MetricCard(title: "Baixo risco", value: "\(lowRiskCount)", symbol: "checkmark.circle", tint: .green)
                    MetricCard(title: "Quarentena", value: "\(appState.quarantineSessions.count)", symbol: "archivebox", tint: .orange)
                    MetricCard(title: "Liberado", value: appState.totalPermanentlyFreedBytes.humanSize, symbol: "checkmark.circle", tint: .blue)
                }

                SafetyRailCard()

                HStack(alignment: .top, spacing: 16) {
                    SoftSection(
                        title: "Principais categorias",
                        subtitle: categorySummaries.isEmpty ? "Rode uma varredura para preencher este resumo." : "Ordenadas pelo espaco potencial."
                    ) {
                        if categorySummaries.isEmpty {
                            EmptyInlineState(text: "Nenhum candidato carregado.", symbol: "doc.text.magnifyingglass")
                        } else {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 10)], spacing: 10) {
                                ForEach(categorySummaries.prefix(6)) { summary in
                                    CategorySummaryCard(summary: summary)
                                }
                            }
                        }
                    }

                    SoftSection(
                        title: "Acoes principais",
                        subtitle: "Fluxo recomendado: varrer, revisar, quarentenar e purgar depois."
                    ) {
                        VStack(spacing: 10) {
                            PrimaryActionTile(
                                title: "Iniciar varredura",
                                subtitle: "Analisa caches, logs, Downloads e sobras de desenvolvimento.",
                                symbol: "magnifyingglass",
                                tint: .blue,
                                disabled: appState.isBusy
                            ) {
                                Task { await appState.startScan() }
                            }

                            PrimaryActionTile(
                                title: "Enviar baixo risco",
                                subtitle: "Move somente candidatos de baixo risco para quarentena.",
                                symbol: "archivebox.fill",
                                tint: .orange,
                                disabled: appState.isBusy || lowRiskCount == 0
                            ) {
                                Task { await appState.quarantineLowRiskCandidates() }
                            }

                            PrimaryActionTile(
                                title: "Ver quarentena",
                                subtitle: "Confira itens movidos e ainda restauraveis.",
                                symbol: "archivebox",
                                tint: .orange
                            ) {
                                appState.selectedSection = .quarantine
                            }
                        }
                    }
                    .frame(maxWidth: 360)
                }

                StatusStrip()
            }
            .padding(24)
        }
    }

    private var lowRiskCount: Int {
        appState.candidates.filter { $0.risk == "baixo" }.count
    }

    private var categorySummaries: [CategorySummary] {
        Dictionary(grouping: appState.candidates, by: \.kind)
            .map { kind, items in
                CategorySummary(
                    id: kind,
                    title: items.first?.kindLabel ?? kind,
                    symbol: items.first?.kindSymbol ?? "doc",
                    count: items.count,
                    bytes: items.reduce(0) { $0 + $1.sizeBytes }
                )
            }
            .sorted { $0.bytes > $1.bytes }
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let symbol: String
    let tint: Color

    init(title: String, value: String, symbol: String, tint: Color = .blue) {
        self.title = title
        self.value = value
        self.symbol = symbol
        self.tint = tint
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: symbol)
                    .foregroundStyle(tint)
                    .frame(width: 18)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .font(.title3.weight(.semibold))
                .lineLimit(2)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct OverviewHero: View {
    let potentialBytes: Int
    let candidateCount: Int
    let lowRiskCount: Int
    let isBusy: Bool
    let startScan: () -> Void
    let reviewCandidates: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 18) {
            VStack(alignment: .leading, spacing: 10) {
                Label("Painel de limpeza segura", systemImage: "shield.checkered")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.blue)

                Text(potentialBytes == 0 ? "Pronto para uma nova varredura" : "\(potentialBytes.humanSize) em espaco potencial")
                    .font(.system(size: 32, weight: .semibold))
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)

                Text(heroMessage)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 10) {
                    Button(action: startScan) {
                        Label("Varrer agora", systemImage: "magnifyingglass")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isBusy)

                    Button(action: reviewCandidates) {
                        Label("Revisar", systemImage: "list.bullet.rectangle")
                    }
                    .disabled(candidateCount == 0)
                }
            }

            Spacer(minLength: 12)

            VStack(alignment: .leading, spacing: 12) {
                HeroSignalRow(title: "Candidatos", value: "\(candidateCount)", symbol: "list.bullet.rectangle", tint: .teal)
                HeroSignalRow(title: "Baixo risco", value: "\(lowRiskCount)", symbol: "checkmark.circle", tint: .green)
                HeroSignalRow(title: "Exigem revisao", value: "\(max(candidateCount - lowRiskCount, 0))", symbol: "exclamationmark.circle", tint: .orange)
            }
            .frame(width: 220)
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.blue.opacity(0.16), lineWidth: 1)
        )
    }

    private var heroMessage: String {
        if candidateCount == 0 {
            return "A varredura encontra oportunidades sem mover nada. O primeiro passo real continua sendo a quarentena."
        }
        if lowRiskCount > 0 {
            return "\(lowRiskCount) item(ns) de baixo risco podem ir para quarentena depois da sua revisao."
        }
        return "Todos os candidatos atuais pedem revisao manual antes de qualquer movimento."
    }
}

private struct HeroSignalRow: View {
    let title: String
    let value: String
    let symbol: String
    let tint: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .foregroundStyle(tint)
                .frame(width: 18)
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.headline)
        }
        .font(.callout)
    }
}

private struct SafetyRailCard: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lock.shield")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.green)
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text("Modelo conservador")
                    .font(.headline)
                Text("A varredura nunca apaga nem move arquivos. A primeira acao real e sempre quarentena com caminho original preservado; purga permanente fica em uma etapa separada.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(.green.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.green.opacity(0.16), lineWidth: 1)
        )
    }
}

struct HeaderView: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.largeTitle.weight(.semibold))
            Text(subtitle)
                .foregroundStyle(.secondary)
        }
    }
}

struct CategorySummary: Identifiable {
    let id: String
    let title: String
    let symbol: String
    let count: Int
    let bytes: Int
}

struct CategorySummaryCard: View {
    let summary: CategorySummary

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: summary.symbol)
                .foregroundStyle(.secondary)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(summary.title)
                    .font(.callout.weight(.medium))
                    .lineLimit(1)
                Text("\(summary.count) item(ns) • \(summary.bytes.humanSize)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct EmptyInlineState: View {
    let text: String
    let symbol: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .foregroundStyle(.secondary)
            Text(text)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .font(.callout)
        .padding(.vertical, 8)
    }
}

struct StatusStrip: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: statusSymbol)
                .foregroundStyle(statusColor)
            Text(appState.lastMessage)
                .lineLimit(2)
            Spacer()
            if appState.isBusy {
                ProgressView()
                    .controlSize(.small)
            }
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    private var statusSymbol: String {
        switch appState.appStatus {
        case .ready: return "checkmark.circle.fill"
        case .error: return "exclamationmark.triangle.fill"
        case .scanning, .quarantining, .restoring, .purging: return "clock"
        }
    }

    private var statusColor: Color {
        switch appState.appStatus {
        case .ready: return .green
        case .error: return .orange
        case .scanning, .quarantining, .restoring, .purging: return .blue
        }
    }
}
