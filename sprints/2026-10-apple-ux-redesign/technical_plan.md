# Plano tecnico - Swift/AppKit/SwiftUI

## Direcao recomendada

Migrar a interface para SwiftUI, mantendo pequenas pontes AppKit quando necessario.

Arquitetura sugerida:

```text
CleanMyMacDesktop
  App
  AppState
  DockerService
  ScannerClient
  QuarantineClient
  Views
    SidebarView
    OverviewView
    ScanView
    CandidatesView
    CandidateDetailView
    QuarantineView
    LogsView
    SettingsView
```

## Backend

Manter inicialmente:

- Docker Compose;
- API local em `127.0.0.1:8080`;
- endpoints existentes:
  - `/api/scan`;
  - `/api/scan-status`;
  - `/api/quarantine`;
  - `/api/sessions`;
  - `/api/restore`;
  - `/api/purge`.

## Camada de servico

### DockerService

Responsabilidades:

- verificar Docker;
- abrir Docker Desktop;
- subir compose;
- parar compose;
- checar status do servico.

### ScannerClient

Responsabilidades:

- iniciar varredura;
- acompanhar progresso;
- carregar candidatos;
- mapear JSON para modelos Swift.

### QuarantineClient

Responsabilidades:

- listar sessoes;
- mover candidatos para quarentena;
- restaurar itens;
- simular/executar purga.

## Modelos Swift

```swift
struct Candidate: Identifiable, Codable {
    let id: String
    let kind: String
    let path: String
    let sizeBytes: Int
    let ageDays: Int
    let reason: String
    let risk: String
}
```

```swift
struct ScanStatus: Codable {
    let running: Bool
    let elapsedSeconds: Double
    let message: String
    let error: String?
    let candidateCount: Int
    let totalSizeBytes: Int
}
```

## Implementacao incremental

### Fase 1

- Criar SwiftUI app com sidebar e toolbar.
- Manter WebView apenas como aba temporaria.
- DockerService funcionando.

### Fase 2

- Implementar tela nativa de varredura.
- Consumir `/api/scan-status`.
- Mostrar progresso e resumo.

### Fase 3

- Implementar tabela nativa de candidatos.
- Selecionar e mover para quarentena.

### Fase 4

- Implementar quarentena nativa.
- Restaurar e purgar.

### Fase 5

- Remover WebView da experiencia principal.
- Deixar WebView apenas como fallback/debug.

## Observacao sobre Xcode

O app deve ser aberto pelo `Package.swift` enquanto estiver em desenvolvimento. Para distribuicao local, gerar `.app` com `build_app.sh` ou criar projeto Xcode formal com bundle identifier, icone e signing.

