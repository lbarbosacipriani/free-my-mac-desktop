# Backlog priorizado

## Sprint 1 - Experiencia e confiabilidade do app

Objetivo: tornar o uso diario mais previsivel e menos dependente de terminal.

### Itens

| Prioridade | Item | Resultado esperado |
|---|---|---|
| P0 | Melhorar status do `.app` | Usuario entende se Docker esta abrindo, subindo container ou se houve erro. |
| P0 | Tela de erro amigavel | Erros de Docker, porta ocupada e permissao viram mensagens claras. |
| P0 | Botao "Parar container" | Usuario para o servico pela interface. |
| P1 | Indicador de progresso por etapa | Exibir: preparando Docker, varrendo, salvando relatorio, pronto. |
| P1 | Link direto para logs | Abrir `logs/launcher.log` pela interface ou Finder. |
| P1 | Reexecutar ultima varredura | Usar parametros anteriores sem reconfigurar. |
| P2 | Preferencias locais | Salvar tamanho minimo, idade minima e filtros favoritos. |

## Sprint 2 - Lista de candidatos mais util

Objetivo: melhorar revisao antes da quarentena.

### Itens

| Prioridade | Item | Resultado esperado |
|---|---|---|
| P0 | Filtros por tipo | Usuario filtra cache, instalador, log, Xcode, HuggingFace, npm, uv. |
| P0 | Ordenacao por tamanho, idade e risco | Revisao fica mais rapida. |
| P1 | Agrupamento por origem | Mostrar totais por pasta/ferramenta. |
| P1 | Previa segura | Mostrar metadados sem abrir arquivos sensiveis. |
| P1 | Motivo detalhado | Explicar por que o item foi sugerido e o risco. |
| P2 | Busca textual | Buscar por nome/caminho. |
| P2 | Selecao inteligente | Selecionar todos de baixo risco em uma categoria. |

## Sprint 3 - Politica segura de logs

Objetivo: tratar logs com regras especificas para macOS moderno.

### Itens

| Prioridade | Item | Resultado esperado |
|---|---|---|
| P0 | Classificar logs por categoria | Separar Unified Logging, arquivos `.log`, `.logarchive`, crash reports e diagnosticos. |
| P0 | Nunca apagar banco ativo do Unified Logging | Evitar mexer em armazenamento gerenciado pelo `logd`. |
| P0 | Sugerir apenas arquivos de log arquivados ou diagnosticos antigos | Reduzir risco e impacto. |
| P1 | Detectar `.logarchive` gerados por diagnostico | Sugerir se antigos e grandes, com explicacao. |
| P1 | Detectar crash reports antigos | Sugerir por idade, mantendo recentes. |
| P1 | Politica de retencao configuravel | Exemplo: manter 30, 60 ou 90 dias. |
| P2 | Integrar `newsyslog` em modo leitura | Ler configuracoes sem alterar o sistema. |

## Sprint 4 - Quarentena e restauracao melhores

Objetivo: aumentar confianca antes da purga permanente.

### Itens

| Prioridade | Item | Resultado esperado |
|---|---|---|
| P0 | Painel de quarentena | Ver sessoes, tamanho, data, itens e origem. |
| P0 | Restauracao por item | Restaurar um item especifico pela interface. |
| P1 | Verificacao de integridade | Comparar hash dos arquivos movidos. |
| P1 | Agendamento de purga | Sugerir purga apos X dias, sem apagar automaticamente por padrao. |
| P2 | Exportar manifesto | Gerar CSV/JSON do historico. |

## Sprint 5 - Instalacao e distribuicao local

Objetivo: deixar o app mais proximo de uma experiencia macOS.

### Itens

| Prioridade | Item | Resultado esperado |
|---|---|---|
| P0 | App em `/Applications` apontando para projeto fixo | Ja iniciado; formalizar e documentar. |
| P1 | App independente | Empacotar codigo e Compose dentro do `.app`. |
| P1 | Icone refinado | Criar icone mais polido. |
| P2 | Assinatura local/ad-hoc | Reduzir alertas de seguranca em ambiente proprio. |
| P2 | Comando de uninstall | Parar container e remover app/logs opcionais. |

