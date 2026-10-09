import SwiftUI

struct LogsView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HeaderView(
                title: "Logs",
                subtitle: "Abra registros e relatorios locais gerados pelo app."
            )

            VStack(alignment: .leading, spacing: 10) {
                LogRow(name: "native-latest.json", detail: "Ultimo relatorio em JSON")
                LogRow(name: "native-latest.md", detail: "Ultimo relatorio em Markdown")
                LogRow(name: "quarantine/manifest.jsonl", detail: "Historico de cada item movido")
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 240), spacing: 12)], spacing: 12) {
                PrimaryActionTile(
                    title: "Abrir relatorios",
                    subtitle: "Veja os relatórios gerados pela última varredura.",
                    symbol: "doc.text",
                    tint: .blue
                ) {
                    appState.openReports()
                }

                PrimaryActionTile(
                    title: "Abrir logs",
                    subtitle: "Acesse os registros internos do app.",
                    symbol: "folder",
                    tint: .orange
                ) {
                    appState.openLogs()
                }
            }

            Spacer()
            StatusStrip()
        }
        .padding(24)
    }
}

struct LogRow: View {
    let name: String
    let detail: String

    var body: some View {
        HStack {
            Image(systemName: "doc.text")
                .foregroundStyle(.secondary)
            VStack(alignment: .leading) {
                Text(name)
                    .fontWeight(.medium)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}
