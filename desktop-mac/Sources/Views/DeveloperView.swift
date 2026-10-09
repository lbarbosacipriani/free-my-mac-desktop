import SwiftUI

struct DeveloperView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selectedTargetID = "python-venv"

    private let targets: [DeveloperTarget] = [
        DeveloperTarget(
            id: "python-venv",
            title: "Python virtual environments",
            detail: "Procura `.venv`, `venv`, `env` e `.tox` antigos em projetos. Risco medio porque podem ser recriados, mas podem representar ambientes especificos.",
            risk: "medio",
            examples: ["~/Documents/**/.venv", "~/Documents/**/venv", "~/Documents/**/.tox"]
        ),
        DeveloperTarget(
            id: "node-modules",
            title: "Node dependencies",
            detail: "`node_modules` pode ocupar muito espaco. Revise se o projeto ainda esta ativo antes de mover.",
            risk: "medio",
            examples: ["~/Documents/**/node_modules"]
        ),
        DeveloperTarget(
            id: "rust-target",
            title: "Rust build targets",
            detail: "Pastas `target` sao artefatos de build do Cargo. Normalmente podem ser recriadas.",
            risk: "baixo",
            examples: ["~/Documents/**/target"]
        ),
        DeveloperTarget(
            id: "java-build",
            title: "Java/Kotlin build caches",
            detail: "Inclui `.gradle`, `build` e caches Maven/Gradle. Podem afetar builds offline.",
            risk: "medio",
            examples: ["~/.gradle/caches", "~/.m2/repository", "~/Documents/**/build"]
        ),
        DeveloperTarget(
            id: "mobile-build",
            title: "Mobile build artifacts",
            detail: "Builds de iOS/Android/Flutter podem crescer bastante. Sempre revisar projeto ativo.",
            risk: "medio",
            examples: ["~/Documents/**/DerivedData", "~/Documents/**/.dart_tool", "~/Documents/**/build"]
        ),
        DeveloperTarget(
            id: "web-build",
            title: "Web build outputs",
            detail: "Pastas `.next`, `.nuxt`, `dist` e `build` geralmente sao saidas de build. Revise projetos ativos antes.",
            risk: "baixo",
            examples: ["~/Documents/**/.next", "~/Documents/**/dist", "~/Documents/**/build"]
        ),
        DeveloperTarget(
            id: "ruby-go",
            title: "Ruby/Go dependencies",
            detail: "Caches e dependencias Ruby/Go podem ser grandes. Podem ser recriados, mas podem custar tempo e rede.",
            risk: "medio",
            examples: ["~/Documents/**/vendor/bundle", "~/go/pkg/mod"]
        )
    ]

    private var selectedTarget: DeveloperTarget {
        targets.first { $0.id == selectedTargetID } ?? targets[0]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HeaderView(
                title: "Desenvolvedor",
                subtitle: "Alvos comuns de projetos: ambientes virtuais, dependencias e artefatos de build."
            )

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 185), spacing: 12)], spacing: 12) {
                ForEach(targets) { target in
                    Button {
                        selectedTargetID = target.id
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            Label(target.title, systemImage: symbol(for: target.id))
                                .font(.headline)
                            RiskBadge(risk: target.risk)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                    }
                    .buttonStyle(.plain)
                    .background(selectedTargetID == target.id ? .regularMaterial : .thinMaterial, in: RoundedRectangle(cornerRadius: 8))
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                Text(selectedTarget.title)
                    .font(.title2.weight(.semibold))
                Text(selectedTarget.detail)
                    .foregroundStyle(.secondary)

                Text("Exemplos")
                    .font(.headline)
                ForEach(selectedTarget.examples, id: \.self) { example in
                    Label(example, systemImage: "folder")
                        .font(.callout.monospaced())
                        .textSelection(.enabled)
                }

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 240), spacing: 12)], spacing: 12) {
                    PrimaryActionTile(
                        title: "Abrir regras",
                        subtitle: "Ative manualmente os alvos que deseja incluir.",
                        symbol: "slider.horizontal.3",
                        tint: .indigo
                    ) {
                        appState.selectedSection = .rules
                    }

                    PrimaryActionTile(
                        title: "Rodar varredura",
                        subtitle: "Procura usando as regras que ja estao ativas.",
                        symbol: "magnifyingglass",
                        tint: .blue,
                        disabled: appState.isBusy
                    ) {
                        Task { await appState.startScan() }
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))

            AdaptiveInfoPill(
                text: "Regras de desenvolvedor entram na varredura somente depois de ativadas manualmente.",
                symbol: "info.circle",
                tint: .blue
            )

            StatusStrip()
            Spacer()
        }
        .padding(24)
    }

    private func symbol(for id: String) -> String {
        switch id {
        case "python-venv": return "chevron.left.forwardslash.chevron.right"
        case "node-modules": return "shippingbox"
        case "rust-target": return "hammer"
        case "java-build": return "cup.and.saucer"
        case "mobile-build": return "iphone"
        case "web-build": return "globe"
        case "ruby-go": return "shippingbox"
        default: return "terminal"
        }
    }
}
