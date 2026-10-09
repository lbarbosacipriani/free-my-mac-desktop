import SwiftUI

struct QuarantineView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showPurgeConfirmation = false
    @State private var showPurgeAllConfirmation = false

    private var purgePreview: [QuarantineSession] {
        appState.quarantineSessions.filter { $0.ageDays >= appState.purgeRetentionDays }
    }

    private var purgedEntries: [CleanupHistoryEntry] {
        appState.cleanupHistory.filter { $0.action == "Liberado permanentemente" }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HeaderView(
                title: "Quarentena",
                subtitle: "Veja o que ainda pode ser restaurado e o que ja foi apagado permanentemente."
            )

            HStack(spacing: 12) {
                QuarantineStateCard(
                    title: "Ainda em quarentena",
                    value: appState.quarantineSessions.reduce(0) { $0 + $1.sizeBytes }.humanSize,
                    detail: "\(appState.quarantineSessions.reduce(0) { $0 + $1.itemCount }) item(ns) restauravel(is)",
                    symbol: "archivebox",
                    tint: .orange
                )

                QuarantineStateCard(
                    title: "Ja purgado",
                    value: appState.totalPermanentlyFreedBytes.humanSize,
                    detail: "\(purgedEntries.reduce(0) { $0 + $1.itemCount }) item(ns) sem restauracao pelo app",
                    symbol: "checkmark.circle",
                    tint: .green
                )
            }

            SoftSection(
                title: "Acoes da quarentena",
                subtitle: "Itens restauraveis ficam protegidos aqui ate voce apagar permanentemente."
            ) {
                HStack {
                    Stepper("Purga acima de \(appState.purgeRetentionDays)d", value: $appState.purgeRetentionDays, in: 1...365)
                    Spacer()
                    AdaptiveInfoPill(text: "\(purgePreview.count) sessao(oes) pronta(s)", symbol: "timer", tint: .orange)
                }

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 230), spacing: 12)], spacing: 12) {
                    PrimaryActionTile(
                        title: "Atualizar",
                        subtitle: "Recarrega o estado da quarentena.",
                        symbol: "arrow.clockwise",
                        tint: .blue,
                        disabled: appState.isBusy
                    ) {
                        Task { await appState.refreshSessions() }
                    }

                    PrimaryActionTile(
                        title: "Simular purga",
                        subtitle: "Mostra o que seria apagado sem remover nada.",
                        symbol: "eye",
                        tint: .teal,
                        disabled: appState.isBusy
                    ) {
                        Task { await appState.purge(olderThanDays: appState.purgeRetentionDays, execute: false) }
                    }

                    PrimaryActionTile(
                        title: "Apagar antigas",
                        subtitle: "Remove permanentemente apenas sessoes vencidas.",
                        symbol: "trash",
                        tint: .red,
                        disabled: purgePreview.isEmpty || appState.isBusy
                    ) {
                        showPurgeConfirmation = true
                    }

                    PrimaryActionTile(
                        title: "Purgar tudo",
                        subtitle: "Apaga 100% da quarentena agora.",
                        symbol: "trash.slash",
                        tint: .red,
                        disabled: appState.quarantineSessions.isEmpty || appState.isBusy
                    ) {
                        showPurgeAllConfirmation = true
                    }
                }
            }

            HSplitView {
                VStack(alignment: .leading, spacing: 10) {
                    Label("Ainda em quarentena", systemImage: "archivebox")
                        .font(.headline)
                    Text("Estes itens ainda estao guardados pelo app e podem ser restaurados.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if appState.quarantineSessions.isEmpty {
                        EmptyStateView(
                            "Nada restauravel",
                            systemImage: "archivebox",
                            description: Text("Itens movidos para quarentena aparecem aqui antes da purga permanente.")
                        )
                    } else {
                        List(appState.quarantineSessions) { session in
                            DisclosureGroup {
                                HStack {
                                    Button {
                                        Task { await appState.restore(session: session.session, all: true) }
                                    } label: {
                                        Label("Restaurar sessao", systemImage: "arrow.uturn.backward")
                                    }
                                    Spacer()
                                    Text("\(session.ageDays)d na quarentena")
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 4)

                                ForEach(session.items) { item in
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(URL(fileURLWithPath: item.originalPath).lastPathComponent)
                                            Text(item.originalPath)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                                .lineLimit(1)
                                        }
                                        Spacer()
                                        Text(item.sizeBytes.humanSize)
                                            .foregroundStyle(.secondary)
                                        Button("Restaurar") {
                                            Task { await appState.restore(session: session.session, ids: [item.id]) }
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            } label: {
                                HStack {
                                    Label(session.session, systemImage: "archivebox")
                                    Spacer()
                                    Text("\(session.itemCount) item(ns)")
                                    Text(session.sizeBytes.humanSize)
                                    if session.ageDays >= appState.purgeRetentionDays {
                                        RiskBadge(risk: "medio")
                                    }
                                }
                            }
                        }
                    }
                }
                .frame(minWidth: 520)

                VStack(alignment: .leading, spacing: 10) {
                    Label("Ja purgado", systemImage: "checkmark.circle")
                        .font(.headline)
                    Text("Estes registros ja foram apagados permanentemente da quarentena. O app nao consegue restaurar depois da purga.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if purgedEntries.isEmpty {
                        EmptyStateView(
                            "Nada purgado ainda",
                            systemImage: "checkmark.circle",
                            description: Text("Quando voce apagar sessoes antigas permanentemente, elas aparecem aqui como historico.")
                        )
                    } else {
                        List(purgedEntries) { entry in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(entry.bytes.humanSize)
                                        .font(.headline)
                                    Spacer()
                                    Text("\(entry.itemCount) item(ns)")
                                        .foregroundStyle(.secondary)
                                }
                                Text(entry.dateLabel)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(entry.detail)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 6)
                        }
                    }
                }
                .frame(minWidth: 360)
            }
            .frame(minHeight: 300)

            StatusStrip()
        }
        .padding(24)
        .confirmationDialog(
            "Apagar quarentenas antigas permanentemente?",
            isPresented: $showPurgeConfirmation,
            titleVisibility: .visible
        ) {
            Button("Apagar \(purgePreview.count) sessao(oes)", role: .destructive) {
                Task { await appState.purge(olderThanDays: appState.purgeRetentionDays, execute: true) }
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Essa acao remove definitivamente as sessoes com mais de \(appState.purgeRetentionDays) dias. Depois disso, o app nao consegue restaurar esses itens.")
        }
        .confirmationDialog(
            "Purgar 100% da quarentena?",
            isPresented: $showPurgeAllConfirmation,
            titleVisibility: .visible
        ) {
            Button("Purgar tudo permanentemente", role: .destructive) {
                Task { await appState.purge(olderThanDays: 0, execute: true) }
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Essa acao apaga permanentemente todas as sessoes ainda em quarentena. Depois disso, esses itens aparecem apenas no historico como ja purgados e nao podem ser restaurados pelo app.")
        }
    }
}

struct QuarantineStateCard: View {
    let title: String
    let value: String
    let detail: String
    let symbol: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: symbol)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2.weight(.semibold))
            Text(detail)
                .font(.caption)
                .foregroundStyle(tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}
