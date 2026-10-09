# Backlog - Sprint Descoberta orientada por documentacao

## P0 - Fundacao

| Prioridade | Tarefa | Detalhe | Aceite |
|---|---|---|---|
| P0 | Criar `DocumentationService` | Ler documentos Markdown conhecidos do projeto. | Retorna lista de docs encontrados e ausentes. |
| P0 | Criar `RuleDiscoveryService` | Extrair possiveis regras de limpeza a partir dos docs. | Retorna regras sugeridas com origem. |
| P0 | Criar modelos de docs | `AppDocument`, `DocumentSection`, resultado de busca. | Compila sem dependencias externas. |
| P0 | Criar modelos de regra | `CleanupRule`, `RuleSource`, `RuleStatus`. | Diferencia regra ativa, sugerida e ignorada. |
| P0 | Criar tela `Ajuda` | Nova secao na sidebar. | Usuario consegue ler README dentro do app. |
| P0 | Criar tela `Regras` | Nova secao para regras ativas/sugeridas. | Usuario ve de onde surgem novos alvos. |
| P0 | Extrair titulos Markdown | Parse simples de linhas iniciadas por `#`. | Indice mostra secoes principais. |
| P0 | Estado vazio | Quando docs nao existem, mostrar mensagem amigavel. | App nao quebra. |

## P1 - Ajuda contextual

| Prioridade | Tarefa | Detalhe | Aceite |
|---|---|---|---|
| P1 | Explicar categoria no detalhe | Mapear `cache`, `log`, `download`, `xcode-junk`, `document-version`. | Painel de candidato exibe explicacao curta. |
| P1 | Explicar risco | Mapear baixo/medio/alto. | Usuario entende por que revisar. |
| P1 | Simular regra sugerida | Rodar uma regra nova sem ativar. | Mostra possiveis candidatos e tamanho estimado. |
| P1 | Promover regra | Ativar uma regra sugerida apos revisao. | Regra entra na proxima varredura. |
| P1 | Ignorar regra | Ocultar uma regra sugerida indesejada. | Ela nao reaparece como pendente. |
| P1 | Busca em docs | Campo de busca por termo. | Busca retorna secoes com termo. |
| P1 | Link visual para docs | Botao `Ver regra` ou `Abrir ajuda`. | Navega para tela Ajuda. |
| P1 | Regras no relatorio | Adicionar secao `Regras usadas` no Markdown. | Relatorio inclui politica de seguranca e docs usados. |

## P2 - Polimento

| Prioridade | Tarefa | Detalhe | Aceite |
|---|---|---|---|
| P2 | Abrir arquivo original | Botao para abrir `.md` no editor padrao. | Funciona via `NSWorkspace`. |
| P2 | Exportar pacote de suporte | Gerar Markdown consolidado com docs + ultimo relatorio. | Arquivo aparece em `reports/`. |
| P2 | Validar documentos | Checar docs esperados e indicar ausentes. | Tela Ajuda mostra status. |
| P2 | Persistir ultimo doc aberto | Lembrar doc/secao selecionado. | Reabre onde parou. |
| P2 | Perfis de varredura | Conservador, Desenvolvedor, Completo. | Usuario controla amplitude. |

## Exemplos de novas regras a investigar

| Categoria | Possivel caminho | Risco inicial | Observacao |
|---|---|---|---|
| Gradle cache | `~/.gradle/caches` | medio | Pode ser recriado, mas pode afetar builds offline. |
| Homebrew cache | `~/Library/Caches/Homebrew` | baixo | Geralmente seguro revisar. |
| CoreSimulator | `~/Library/Developer/CoreSimulator` | medio | Pode ocupar muito espaco; revisar antes. |
| Python cache | `.pytest_cache`, `__pycache__` | baixo | Melhor limitar a projetos conhecidos. |
| Node artifacts | `node_modules` antigo | medio | Nao remover dentro de projeto ativo sem revisao. |
| HuggingFace cache | `~/.cache/huggingface` | medio | Pode ser grande, mas redownload custa tempo. |
| Docker leftovers | `~/Library/Containers/com.docker.docker` caches | medio | Requer cuidado se Docker estiver em uso. |

## Design UX

- Nao transformar a tela principal em manual.
- Ajuda contextual deve ser curta.
- Texto completo fica na tela `Ajuda`.
- Linguagem deve ser nao tecnica.
- Acoes perigosas continuam separadas e confirmadas.

## Sequencia sugerida de implementacao

1. `DocumentationModels.swift`
2. `DocumentationService.swift`
3. `CleanupRuleModels.swift`
4. `RuleDiscoveryService.swift`
5. `DocumentationView.swift`
6. `CleanupRulesView.swift`
7. Adicionar `SidebarSection.help` e `SidebarSection.rules`
8. Conectar ajuda contextual em `CandidateDetailPanel`
9. Atualizar scanner para aceitar regras ativas extras
10. Atualizar relatorio Markdown
11. Build e instalacao do app
