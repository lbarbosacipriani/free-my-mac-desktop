import SwiftUI

struct ScanView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HeaderView(
                title: "Varredura",
                subtitle: "Configure uma busca conservadora por caches, logs, sobras do Xcode e versoes locais antigas."
            )

            Form {
                Section("Politica") {
                    Stepper("Tamanho minimo: \(appState.minimumSizeMB) MB", value: $appState.minimumSizeMB, in: 1...2048, step: 10)
                    Stepper("Mais antigo que: \(appState.olderThanDays) dias", value: $appState.olderThanDays, in: 1...365, step: 1)
                    Toggle("Incluir locais globais e Document Versions acessiveis", isOn: $appState.includeSystemLocations)
                }
            }
            .formStyle(.grouped)
            .frame(maxWidth: 560)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 260), spacing: 12)], spacing: 12) {
                PrimaryActionTile(
                    title: "Iniciar varredura",
                    subtitle: "Procura itens descartaveis sem mover nada.",
                    symbol: "magnifyingglass",
                    tint: .blue,
                    disabled: appState.isBusy
                ) {
                    Task { await appState.startScan() }
                }

                PrimaryActionTile(
                    title: "Enviar para quarentena",
                    subtitle: "Move apenas candidatos de baixo risco.",
                    symbol: "archivebox.fill",
                    tint: .orange,
                    disabled: appState.isBusy || appState.candidates.allSatisfy { $0.risk != "baixo" }
                ) {
                    Task { await appState.quarantineLowRiskCandidates() }
                }

                PrimaryActionTile(
                    title: "Ver quarentena",
                    subtitle: "Confira os itens movidos e ainda restauraveis.",
                    symbol: "archivebox",
                    tint: .orange
                ) {
                    appState.selectedSection = .quarantine
                }

                PrimaryActionTile(
                    title: "Revisar candidatos",
                    subtitle: "Veja itens medios e altos antes de mover.",
                    symbol: "list.bullet.rectangle",
                    tint: .teal,
                    disabled: appState.candidates.isEmpty
                ) {
                    appState.selectedSection = .candidates
                }
            }

            SoftSection(
                title: "Acompanhamento",
                subtitle: "A varredura mostra candidatos, mas nada sai do lugar sem sua acao."
            ) {
                if appState.scanStatus.running {
                    HStack(spacing: 10) {
                        ProgressView()
                            .controlSize(.small)
                        AdaptiveInfoPill(
                            text: "Tempo: \(appState.scanStatus.elapsedSeconds.secondsLabel)",
                            symbol: "timer",
                            tint: .blue
                        )
                    }
                }
                Text(appState.scanStatus.message)
                    .font(.headline)
                Text("Candidatos: \(appState.candidates.count) • Espaco potencial: \((appState.report?.totalSizeBytes ?? 0).humanSize)")
                    .foregroundStyle(.secondary)
                Text("Esses itens ainda nao estao em quarentena. Eles so saem do local original quando voce envia para quarentena.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Inclui caches do usuario, caches de apps, logs, Xcode Logs, Downloads antigos, instaladores antigos e sobras do Xcode. Locais globais e Document Versions exigem a opcao acima.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: 620, alignment: .leading)

            StatusStrip()
            Spacer()
        }
        .padding(24)
    }
}
