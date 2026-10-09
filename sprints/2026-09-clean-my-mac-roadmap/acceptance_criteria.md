# Criterios de aceite

## Experiencia

- O usuario consegue abrir o app sem terminal.
- Se Docker nao estiver rodando, o app explica o problema.
- A interface abre automaticamente quando o container estiver pronto.
- A varredura mostra tempo decorrido.
- Erros comuns mostram uma acao recomendada.

## Varredura

- Nenhum arquivo e removido durante a varredura.
- Todos os candidatos mostram tipo, tamanho, idade, caminho, risco e motivo.
- O usuario consegue filtrar por tipo.
- O usuario consegue ordenar por tamanho e idade.
- A mesma regra nunca sugere arquivos em `/System`.

## Logs macOS

- O app nao apaga bases ativas do Unified Logging.
- `.logarchive` aparece como diagnostico exportado, nao como log comum.
- Logs recentes ficam fora da selecao padrao.
- Logs em `/Library/Logs` sao marcados como risco medio.
- Logs em `~/Library/Logs` antigos e grandes podem ser baixo risco.

## Quarentena

- Itens selecionados sao movidos, nao apagados.
- O manifesto registra origem, destino, tamanho, hash quando aplicavel e horario.
- Itens podem ser restaurados individualmente.
- Purga permanente exige confirmacao explicita.
- A purga padrao nao inclui sessoes recentes.

## Instalacao

- O `.app` pode ficar em `/Applications`.
- O projeto continua em `~/Documents/dev/mac-safe-cleaner`.
- O app registra logs de execucao.
- O icone aparece no Finder.

