# Proxima sprint - Descoberta orientada por documentacao

## Objetivo

Fazer o Clean My Mac Desktop ler, organizar e usar os documentos definidos anteriormente no projeto para descobrir novas classes de arquivos que podem ser descartados com seguranca.

Hoje o app ja tem regras fixas no scanner nativo. A proxima evolucao e transformar os documentos do projeto em uma fonte de conhecimento para propor novas regras de varredura, mantendo revisao humana, quarentena e classificacao de risco.

## Resultado esperado

O usuario deve conseguir abrir o app e entender:

- quais categorias sao varridas;
- quais categorias novas foram sugeridas pelos docs;
- por que um item aparece como candidato;
- por que um item tem risco baixo, medio ou alto;
- o que acontece ao mover para quarentena;
- quando e seguro apagar permanentemente;
- quais regras foram usadas na varredura atual.

O app deve conseguir sugerir novos alvos de varredura a partir dos docs, por exemplo caches de ferramentas de desenvolvimento, logs antigos, artefatos temporarios e diretorios historicamente seguros para revisar.

## Status de execucao

Implementado em `doc_aware_implementation_notes.md`.

## Documentos de entrada

O app deve considerar como fonte inicial:

- `desktop-mac/README.md`
- `sprints/2026-10-apple-ux-redesign/native_app_only_refinement.md`
- `sprints/2026-10-apple-ux-redesign/apple_ux_backlog.md`
- `sprints/2026-10-apple-ux-redesign/technical_plan.md`
- `sprints/2026-09-clean-my-mac-roadmap/macos_log_cleanup_research.md`
- `sprints/2026-09-clean-my-mac-roadmap/acceptance_criteria.md`

## Escopo P0

| Item | Descricao | Resultado esperado |
|---|---|---|
| Catalogo local de docs | Criar um leitor nativo Swift para localizar docs `.md` conhecidos do projeto. | O app reconhece os documentos disponiveis. |
| Extrator de regras candidatas | Ler docs e identificar trechos que mencionem diretorios, extensoes, caches, logs e artefatos temporarios. | App gera uma lista de possiveis novas regras. |
| Registro de regras sugeridas | Separar regra ativa de regra sugerida. | Nada novo entra na varredura automaticamente sem revisao. |
| Tela de regras | Mostrar regras ativas e sugeridas com origem documental. | Usuario entende de onde veio a sugestao. |
| Tela `Ajuda` ou `Docs` | Adicionar nova secao na sidebar para visualizar docs dentro do app. | Usuario le README e notas sem sair do app. |
| Indice por topico | Extrair titulos Markdown (`#`, `##`, `###`) e montar navegacao simples. | Docs ficam navegaveis por assunto. |
| Ajuda contextual | Em Varredura, Candidatos e Quarentena, exibir link para topicos relacionados. | Usuario entende cada decisao no momento certo. |
| Politica de seguranca visivel | Mostrar regras: nada apaga automaticamente, quarentena antes da purga, riscos altos exigem revisao. | Confiança maior no fluxo. |

## Escopo P1

| Item | Descricao | Resultado esperado |
|---|---|---|
| Mapeamento categoria -> doc | Associar `cache`, `log`, `download`, `xcode-junk`, `document-version` a trechos explicativos. | Painel de detalhe mostra explicacao da categoria. |
| Mapeamento risco -> doc | Associar baixo/medio/alto a criterios documentados. | Risco deixa de parecer arbitrario. |
| Promover regra sugerida | Permitir marcar uma regra sugerida como ativa apos revisao. | Novas categorias entram no scanner com controle. |
| Simular nova regra | Rodar uma regra sugerida em modo simulacao. | Usuario ve candidatos antes de ativar regra. |
| Relatorio com referencias | Incluir no `native-latest.md` uma secao `Regras usadas`. | Relatorio fica auditavel. |
| Busca local nos docs | Campo de busca para pesquisar termos como Xcode, Downloads, Document Versions, quarentena. | Usuario encontra respostas rapido. |
| Estado de docs ausentes | Se um doc nao existir, mostrar aviso amigavel. | App nao quebra quando documentação mudar. |

## Escopo P2

| Item | Descricao | Resultado esperado |
|---|---|---|
| Validacao de docs | Checar links internos e documentos esperados. | Sprint docs nao ficam quebrados. |
| Exportar pacote de suporte | Gerar um `.md` consolidado com regras, ultimos resultados e estado da quarentena. | Facilita depuracao e suporte. |
| Versao das regras | Salvar no relatorio qual versao dos docs/regras foi usada. | Reprodutibilidade melhor. |
| Perfil de regras | Criar perfis como `Conservador`, `Desenvolvedor`, `Completo`. | Usuario escolhe amplitude da varredura. |

## Experiencia sugerida

### Sidebar

Adicionar:

```text
Ajuda
```

ou:

```text
Docs
```

Preferencia: `Ajuda`, por ser menos tecnico.

### Painel de detalhe do candidato

Adicionar uma area curta:

```text
Por que apareceu aqui?
<explicacao da categoria e do risco>
```

Exemplo para Downloads:

```text
Arquivos antigos em Downloads recebem risco medio porque podem ser pessoais.
Revise antes de mover para quarentena.
```

### Tela de regras sugeridas

Adicionar area:

```text
Novas possibilidades encontradas nos docs

- ~/.gradle/caches
- ~/Library/Caches/Homebrew
- ~/Library/Developer/CoreSimulator
- .pytest_cache
- node_modules antigos fora de projetos ativos
```

Cada item deve mostrar:

- origem no documento;
- tipo esperado;
- risco sugerido;
- motivo;
- opcao de simular antes de ativar.

### Quarentena

Adicionar bloco fixo:

```text
Mover para quarentena e reversivel. Apagar permanentemente nao e.
```

## Modelo tecnico recomendado

Criar:

```text
desktop-mac/Sources/Services/DocumentationService.swift
desktop-mac/Sources/Services/RuleDiscoveryService.swift
desktop-mac/Sources/Models/DocumentationModels.swift
desktop-mac/Sources/Models/CleanupRuleModels.swift
desktop-mac/Sources/Views/DocumentationView.swift
desktop-mac/Sources/Views/CleanupRulesView.swift
```

### `DocumentationService`

Responsabilidades:

- localizar documentos conhecidos;
- ler Markdown como texto;
- extrair titulos;
- buscar termos;
- expor topicos curtos para ajuda contextual;
- lidar com docs ausentes sem falhar.

### `RuleDiscoveryService`

Responsabilidades:

- procurar padroes de caminho em docs;
- procurar palavras-chave como `cache`, `logs`, `DerivedData`, `DeviceSupport`, `Downloads`, `temp`, `build`, `artifacts`;
- gerar regras candidatas sem ativa-las automaticamente;
- apontar documento e secao de origem;
- classificar risco inicial;
- validar se o caminho existe no computador do usuario.

### `DocumentationModels`

Modelos:

```swift
struct AppDocument: Identifiable {
    let id: String
    let title: String
    let path: String
    let sections: [DocumentSection]
}

struct DocumentSection: Identifiable {
    let id: String
    let level: Int
    let title: String
    let body: String
}
```

```swift
struct CleanupRule: Identifiable {
    let id: String
    let title: String
    let pathPattern: String
    let kind: String
    let risk: String
    let sourceDocument: String
    let sourceSection: String
    let active: Bool
}
```

### `DocumentationView`

Controles esperados:

- lista de documentos;
- busca;
- indice de secoes;
- painel de leitura;
- botao `Abrir arquivo`.

## Criterios de aceite

- O app abre mesmo se nenhum documento for encontrado.
- A sidebar tem uma tela de ajuda/documentacao.
- Pelo menos README e nota da sprint atual aparecem dentro do app.
- A busca encontra termos em titulos e corpo.
- O app lista regras ativas e regras sugeridas separadamente.
- Regras sugeridas mostram documento/secao de origem.
- Nenhuma regra sugerida e ativada automaticamente.
- Uma regra sugerida pode ser simulada antes de entrar na varredura principal.
- O painel de candidato mostra uma explicacao curta da categoria/risco.
- O relatorio Markdown inclui uma secao com regras usadas.
- Build do app passa e o `.app` e atualizado em `/Applications`.

## Fora de escopo

- IA/LLM dentro do app.
- Download de documentacao externa.
- Sincronizacao cloud.
- Editor Markdown completo.
- Apagar ou reescrever docs automaticamente.
- Ativar novas regras sem revisao do usuario.

## Riscos

- Docs grandes podem deixar a tela ruidosa.
- Explicacoes longas podem atrapalhar o fluxo principal.
- Documentos podem mudar de caminho.
- Uma regra extraida de texto pode ser ampla demais.

## Mitigacoes

- Mostrar resumos curtos nas telas principais.
- Deixar leitura completa apenas na tela `Ajuda`.
- Centralizar caminhos esperados em `DocumentationService`.
- Tratar documento ausente como aviso, nao erro.
- Toda regra descoberta nasce como `sugerida`.
- Exigir simulacao e revisao antes de promover para `ativa`.
- Nunca sugerir caminhos protegidos do sistema como removiveis.
