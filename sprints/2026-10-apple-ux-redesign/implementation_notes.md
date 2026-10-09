# Implementation notes

Data: 2026-10-01

## Entregue nesta execucao

- Substituida a janela AppKit/WebView improvisada por uma base SwiftUI nativa.
- Criado `CleanMyMacDesktopApp` com `WindowGroup` e `Settings`.
- Criado `NavigationSplitView` com sidebar:
  - Visao geral
  - Varredura
  - Candidatos
  - Quarentena
  - Logs
  - Interface web
- Criado `AppState` centralizado.
- Criado `DockerService` para iniciar/parar Docker Compose.
- Criado `CleanerAPIClient` para consumir a API local.
- Criados modelos Swift para:
  - candidatos;
  - relatorio de varredura;
  - status de varredura;
  - sessoes de quarentena;
  - respostas de quarentena/restauracao/purga.
- Criadas telas nativas:
  - `OverviewView`
  - `ScanView`
  - `CandidatesView`
  - `QuarantineView`
  - `LogsView`
  - `SettingsView`
  - `WebFallbackView`
- Atualizado `build_app.sh` para compilar todos os arquivos Swift.
- Build manual validado com sucesso.

## Resultado do build

App gerado:

```text
desktop-mac/build/Clean My Mac Desktop.app
```

Validacoes:

```text
Info.plist OK
Mach-O 64-bit executable arm64
AppIcon.icns OK
```

## Limites atuais

- A API ainda exige que o backend Docker esteja disponivel.
- A tela nativa ainda depende dos endpoints existentes.
- A confirmacao nativa refinada para purga ainda deve ser melhorada.
- Preferencias ainda nao persistem em `UserDefaults`.
- A tabela de candidatos e funcional, mas ainda pode ganhar painel de detalhe.

## Proxima rodada recomendada

1. Persistir preferencias em `AppStorage`.
2. Adicionar painel de detalhe para candidato selecionado.
3. Adicionar dialogo nativo de confirmacao antes de quarentena e purga.
4. Melhorar estados vazios.
5. Adicionar filtros por categoria alem de risco.
6. Remover a dependencia visual da aba Web no fluxo principal.

