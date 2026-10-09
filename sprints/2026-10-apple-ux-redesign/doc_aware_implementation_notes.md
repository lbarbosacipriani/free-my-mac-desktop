# Implementacao - Descoberta orientada por documentacao

## Entregue

- `DocumentationService` para localizar e ler documentos Markdown conhecidos do projeto.
- Modelos `AppDocument`, `DocumentSection` e `DocumentSearchResult`.
- Tela `Ajuda` na sidebar para leitura local dos documentos.
- Busca simples dentro dos documentos carregados.
- `RuleDiscoveryService` para transformar docs em regras sugeridas.
- Modelos `CleanupRule`, `CleanupRuleStatus` e `CleanupRuleMatchMode`.
- Tela `Regras` na sidebar com regras sugeridas, ativas e ignoradas.
- Simulacao de regra sugerida antes de ativar.
- Promocao manual de regra sugerida para regra ativa.
- Ignorar/resetar regra sugerida.
- Scanner nativo passa a incluir regras extras apenas quando estiverem ativas.
- Relatorio Markdown inclui secao `Regras usadas`.
- Painel de candidato explica categoria e risco em linguagem curta.
- Tela `Historico` com apresentacao do espaco liberado e espaco em quarentena.
- Tela `Desenvolvedor` para ambientes virtuais e artefatos de build.
- Scanner com suporte a diretorios nomeados recursivos, como `.venv`, `node_modules` e `target`.

## Regras sugeridas inicialmente

- Gradle cache: `~/.gradle/caches`
- Homebrew cache: `~/Library/Caches/Homebrew`
- CoreSimulator: `~/Library/Developer/CoreSimulator`
- Python caches em `~/Documents`
- `node_modules` antigos em `~/Documents`
- HuggingFace cache: `~/.cache/huggingface`
- Docker caches: `~/Library/Containers/com.docker.docker`

## Garantias de seguranca

- Nenhuma regra sugerida e ativada automaticamente.
- Regras ativas extras entram somente apos acao manual do usuario.
- Simulacao nao move nem apaga arquivos.
- A varredura continua apenas listando candidatos.
- A remocao continua passando por quarentena antes de purga permanente.

## Arquivos principais

- `desktop-mac/Sources/Services/DocumentationService.swift`
- `desktop-mac/Sources/Services/RuleDiscoveryService.swift`
- `desktop-mac/Sources/Models/DocumentationModels.swift`
- `desktop-mac/Sources/Models/CleanupRuleModels.swift`
- `desktop-mac/Sources/Views/DocumentationView.swift`
- `desktop-mac/Sources/Views/CleanupRulesView.swift`
- `desktop-mac/Sources/Services/NativeScannerService.swift`
