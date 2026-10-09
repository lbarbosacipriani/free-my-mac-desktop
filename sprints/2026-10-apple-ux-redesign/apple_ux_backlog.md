# Backlog - Apple UX redesign

## Sprint goal

Criar uma versao desktop nativa que siga expectativas de apps macOS: janela clara, sidebar, toolbar, estados de sistema, preferencias e fluxos seguros.

## P0 - Base nativa

| Item | Descricao | Resultado esperado |
|---|---|---|
| Trocar shell visual por app SwiftUI | Criar app com `NavigationSplitView` ou `NSSplitViewController`. | Estrutura nativa com sidebar + detalhe. |
| Remover dependencia visual do WebView | Usar WebView apenas temporariamente em aba "Interface web". | Experiencia principal vira nativa. |
| Toolbar nativa | Adicionar toolbar com Iniciar, Parar, Recarregar, Abrir logs e Preferencias. | Controles no topo da janela, seguindo padrao macOS. |
| Status persistente | Mostrar estado: parado, iniciando Docker, container subindo, pronto, erro. | Usuario entende o que esta acontecendo. |
| Tela inicial nativa | Estado vazio com CTA "Iniciar varredura". | Nada de tela branca ou console confuso. |

## P1 - Experiencia de limpeza

| Item | Descricao | Resultado esperado |
|---|---|---|
| Lista nativa de candidatos | Tabela com checkbox, nome, tipo, tamanho, idade, risco e caminho. | Revisao mais clara que HTML. |
| Agrupamento por categoria | Downloads, caches, logs, Xcode, Docker, Python/uv, npm, HuggingFace. | Usuario entende origem do espaco. |
| Painel de detalhe | Ao selecionar item, mostrar motivo, risco, origem e acao recomendada. | Decisao mais segura. |
| Selecoes inteligentes | Botao "Selecionar baixo risco". | Evita selecionar tudo de forma perigosa. |
| Barra de resumo | Total selecionado, espaco potencial, quantidade de itens. | Feedback imediato. |

## P1 - Quarentena

| Item | Descricao | Resultado esperado |
|---|---|---|
| Secao Quarentena na sidebar | Mostrar sessoes, datas e tamanhos. | Restauracao fica facil. |
| Restaurar item | Botao por item e por sessao. | Fluxo reversivel claro. |
| Purga segura | Botao separado, com confirmacao nativa e resumo. | Acao permanente exige intencao. |

## P2 - Preferencias e polimento

| Item | Descricao | Resultado esperado |
|---|---|---|
| Settings nativo | Janela de preferencias macOS. | Configuracoes ficam fora do fluxo principal. |
| Preferencias persistidas | Min size, idade minima, incluir sistema, retencao da quarentena. | App lembra escolhas. |
| SF Symbols | Usar simbolos para sidebar e toolbar. | Visual mais Apple. |
| Icone final | Refinar icone para estilo macOS. | Melhor presenca no Dock/Finder. |
| Comandos de menu | View > Show Sidebar, File > Scan, Window, Help. | Integracao macOS melhor. |

