import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                ProductSidebarHeader()
                    .padding(.horizontal, 14)
                    .padding(.top, 18)
                    .padding(.bottom, 8)

                List(selection: $appState.selectedSection) {
                    Section("Limpeza") {
                        SidebarLink(section: .overview)
                        SidebarLink(section: .scan)
                        SidebarLink(section: .candidates)
                        SidebarLink(section: .quarantine)
                    }

                    Section("Controle") {
                        SidebarLink(section: .rules)
                        SidebarLink(section: .history)
                        SidebarLink(section: .logs)
                    }

                    Section("Suporte") {
                        SidebarLink(section: .developer)
                        SidebarLink(section: .help)
                    }
                }
                .listStyle(.sidebar)

                SidebarStatusFooter()
                    .padding(14)
            }
            .navigationSplitViewColumnWidth(min: 210, ideal: 240)
        } detail: {
            Group {
                switch appState.selectedSection {
                case .overview:
                    OverviewView()
                case .scan:
                    ScanView()
                case .candidates:
                    CandidatesView()
                case .rules:
                    CleanupRulesView()
                case .developer:
                    DeveloperView()
                case .history:
                    CleanupHistoryView()
                case .quarantine:
                    QuarantineView()
                case .help:
                    DocumentationView()
                case .logs:
                    LogsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .toolbar {
            ToolbarItemGroup {
                Button {
                    Task { await appState.startScan() }
                } label: {
                    Label("Varrer", systemImage: "magnifyingglass")
                }
                .disabled(appState.isBusy)

                Button {
                    Task { await appState.refreshAll() }
                } label: {
                    Label("Atualizar", systemImage: "arrow.clockwise")
                }
            }

            ToolbarItemGroup {
                Button {
                    appState.openLogs()
                } label: {
                    Label("Logs", systemImage: "folder")
                }

                Button {
                    appState.openReports()
                } label: {
                    Label("Relatorios", systemImage: "doc.text")
                }
            }
        }
    }
}

private struct SidebarLink: View {
    let section: SidebarSection

    var body: some View {
        Label(section.title, systemImage: section.symbol)
            .tag(section)
    }
}

private struct ProductSidebarHeader: View {
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles.rectangle.stack")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(.blue.gradient, in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text("Free My Mac")
                    .font(.headline)
                Text("Clean Your Mac")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
    }
}

private struct SidebarStatusFooter: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: statusSymbol)
                .foregroundStyle(statusColor)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 2) {
                Text(appState.appStatus.label)
                    .font(.caption.weight(.medium))
                    .lineLimit(1)
                Text("\(appState.candidates.count) candidatos")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(10)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    private var statusSymbol: String {
        switch appState.appStatus {
        case .ready: return "checkmark.circle.fill"
        case .error: return "exclamationmark.triangle.fill"
        case .scanning, .quarantining, .restoring, .purging: return "clock.fill"
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
