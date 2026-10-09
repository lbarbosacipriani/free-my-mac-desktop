import SwiftUI

struct CleanupHistoryView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        let maxBytes = max(appState.cleanupHistory.map(\.bytes).max() ?? 1, 1)

        VStack(alignment: .leading, spacing: 20) {
            HeaderView(
                title: "Historico",
                subtitle: "Acompanhe o que foi para quarentena e quanto ja foi liberado permanentemente."
            )

            HStack(spacing: 12) {
                HistoryMetricCard(
                    title: "Liberado permanente",
                    value: appState.totalPermanentlyFreedBytes.humanSize,
                    symbol: "checkmark.circle.fill",
                    tint: .green
                )
                HistoryMetricCard(
                    title: "Em quarentena",
                    value: appState.quarantineSessions.reduce(0) { $0 + $1.sizeBytes }.humanSize,
                    symbol: "archivebox.fill",
                    tint: .orange
                )
                HistoryMetricCard(
                    title: "Ja revisado",
                    value: appState.totalQuarantinedBytes.humanSize,
                    symbol: "clock.arrow.circlepath",
                    tint: .blue
                )
            }

            if appState.cleanupHistory.isEmpty {
                EmptyStateView(
                    "Sem historico ainda",
                    systemImage: "chart.bar",
                    description: Text("Quando voce mover itens para quarentena ou apagar sessoes antigas, o historico aparece aqui.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(appState.cleanupHistory) { entry in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 14) {
                            Image(systemName: entry.action == "Liberado permanentemente" ? "checkmark.circle.fill" : "archivebox")
                                .foregroundStyle(entry.action == "Liberado permanentemente" ? .green : .orange)
                                .font(.title3)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(entry.action)
                                    .font(.headline)
                                Text(entry.detail)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(entry.dateLabel)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 4) {
                                Text(entry.bytes.humanSize)
                                    .font(.headline)
                                Text("\(entry.itemCount) item(ns)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        HistoryBar(value: entry.bytes, maxValue: maxBytes, tint: entry.action == "Liberado permanentemente" ? .green : .orange)
                    }
                    .padding(.vertical, 6)
                }
            }

            StatusStrip()
        }
        .padding(24)
        .task {
            await appState.refreshAll()
        }
    }
}

struct HistoryBar: View {
    let value: Int
    let maxValue: Int
    let tint: Color

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width * CGFloat(max(0.04, Double(value) / Double(maxValue)))
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.secondary.opacity(0.12))
                RoundedRectangle(cornerRadius: 4)
                    .fill(tint.opacity(0.65))
                    .frame(width: width)
            }
        }
        .frame(height: 7)
    }
}

struct HistoryMetricCard: View {
    let title: String
    let value: String
    let symbol: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: symbol)
                .font(.title2)
                .foregroundStyle(tint)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}
