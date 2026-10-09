import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Form {
            Section("Varredura padrao") {
                Stepper("Tamanho minimo: \(appState.minimumSizeMB) MB", value: $appState.minimumSizeMB, in: 1...2048, step: 10)
                Stepper("Mais antigo que: \(appState.olderThanDays) dias", value: $appState.olderThanDays, in: 1...365)
                Toggle("Incluir locais globais por padrao", isOn: $appState.includeSystemLocations)
            }

            Section("Quarentena") {
                Stepper("Sugerir purga apos \(appState.purgeRetentionDays) dias", value: $appState.purgeRetentionDays, in: 1...365)
            }
        }
        .padding(24)
        .frame(width: 460)
    }
}
