import SwiftUI

@main
struct FreeMyMacDesktopApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup("Free My Mac Desktop") {
            ContentView()
                .environmentObject(appState)
                .frame(minWidth: 1040, minHeight: 680)
                .task {
                    await appState.refreshAll()
                }
        }
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Atualizar Status") {
                    Task { await appState.refreshAll() }
                }
                .keyboardShortcut("r", modifiers: [.command])
            }

            CommandMenu("Limpeza") {
                Button("Iniciar Varredura") {
                    Task { await appState.startScan() }
                }
                .keyboardShortcut("f", modifiers: [.command])
                .disabled(appState.isBusy)

                Button("Revisar Candidatos") {
                    appState.selectedSection = .candidates
                }
                .keyboardShortcut("1", modifiers: [.command])
                .disabled(appState.candidates.isEmpty)

                Button("Abrir Quarentena") {
                    appState.selectedSection = .quarantine
                }
                .keyboardShortcut("2", modifiers: [.command])

                Divider()

                Button("Abrir Relatorios") {
                    appState.openReports()
                }
            }
        }

        Settings {
            SettingsView()
                .environmentObject(appState)
        }
    }
}
