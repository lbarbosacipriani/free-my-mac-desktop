# Pesquisa - limpeza segura de logs no macOS

## Resumo

No macOS moderno, a limpeza de logs precisa ser conservadora porque parte importante dos logs e gerenciada pelo Unified Logging System. Esse sistema e centralizado, usa memoria e disco, e e administrado por componentes do sistema como `logd`.

Conclusao pratica para o `mac-safe-cleaner`: evitar apagar diretamente bases ativas do Unified Logging. O app deve sugerir apenas artefatos antigos, exportados, arquivados ou claramente gerados para diagnostico, como `.logarchive`, logs de usuario antigos, crash reports antigos e instaladores/arquivos temporarios.

## Fontes consultadas

- Apple Developer Documentation - Logging: https://developer.apple.com/documentation/os/logging
- Apple Developer Documentation - Customizing Logging Behavior While Debugging: https://developer.apple.com/documentation/os/customizing-logging-behavior-while-debugging
- `logd(8)` manual: https://manp.gs/mac/8/logd
- `os_log(3)` manual: https://manp.gs/mac/3/os_log
- Apple WWDC - Unified Logging and Activity Tracing: https://devstreaming-cdn.apple.com/videos/wwdc/2016/721wh2etddp4ghxhpcg/721/721_unified_logging_and_activity_tracing.pdf

## Achados principais

### 1. Unified Logging substituiu mecanismos antigos

A Apple descreve o Unified Logging como o sistema que centraliza armazenamento de logs em memoria e disco, substituindo APIs antigas como ASL e syslog em muitos cenarios modernos.

Implicacao:

- Nao tratar todo log como arquivo `.log` simples.
- Nao sair apagando bases internas do sistema.
- Usar a CLI `log` para inspecao/coleta, nao para limpeza agressiva.

### 2. `logd` gerencia historico e metadados

O `logd` e o componente responsavel por lidar com dados historicos e metadados do Unified Logging.

Implicacao:

- Evitar mexer manualmente em arquivos ativos mantidos por `logd`.
- Nao criar funcionalidade de "apagar Unified Logs" por padrao.
- Se algum dia for exposto, deve ser uma acao avancada, explicita e fora do fluxo comum.

### 3. Logs sao uteis para suporte, diagnostico e performance

Logs podem ser usados para diagnosticar crashes, erros e problemas de performance. Apagar logs recentes pode reduzir a capacidade de investigar problemas.

Implicacao:

- Manter logs recentes por padrao.
- Sugerir apenas logs antigos ou exportados.
- Preferir uma retencao minima de 30 dias.

### 4. `.logarchive` costuma ser artefato exportado/coletado

Arquivos `.logarchive` geralmente sao snapshots/coletas de diagnostico. Eles podem ser grandes, mas podem ser necessarios se o usuario estiver investigando um problema com suporte tecnico.

Politica proposta:

- Sugerir `.logarchive` somente se:
  - tiver mais de 30 dias;
  - for maior que um limite configuravel;
  - estiver fora de areas criticas do sistema;
  - o usuario confirmar que nao precisa mais do diagnostico.

### 5. Logs tradicionais e rotacionados ainda existem

Arquivos como `.log`, `.log.N`, `.gz`, `.bz2` e logs em `~/Library/Logs` ou `/Library/Logs` ainda podem existir.

Politica proposta:

- Priorizar `~/Library/Logs` antes de `/Library/Logs`.
- Nao mexer em `/System`.
- Para `/Library/Logs`, usar risco maior e exigir confirmacao mais clara.
- Sugerir apenas arquivos antigos e grandes.

## Politica recomendada para o app

### Baixo risco

- Logs de usuario em `~/Library/Logs` com mais de 30 dias e grandes.
- Logs compactados antigos em area de usuario.
- `.logarchive` em Downloads, Desktop ou Documents, se antigo.
- Crash reports antigos em `~/Library/Logs/DiagnosticReports`.

### Medio risco

- Logs em `/Library/Logs` quando antigos e grandes.
- Relatorios de diagnostico recentes, se forem grandes.
- Logs de apps ainda instalados e ativos.

### Alto risco / evitar

- Bases ativas do Unified Logging.
- Pastas internas gerenciadas por `logd`.
- `/System`.
- Logs recentes.
- Arquivos com permissao do sistema que exigem escalacao.

## Funcionalidades sugeridas

1. Classificacao por tipo:
   - log de usuario;
   - log global;
   - crash report;
   - logarchive;
   - diagnostico temporario;
   - desconhecido.

2. Politica de retencao:
   - padrao: 30 dias;
   - conservador: 90 dias;
   - agressivo: 7 dias, escondido atras de modo avancado.

3. Mensagem por candidato:
   - "Log antigo de usuario";
   - "Arquivo de diagnostico exportado";
   - "Crash report antigo";
   - "Log global: revisar antes de mover".

4. Nao apagar diretamente:
   - sempre mover para quarentena;
   - manter manifesto;
   - permitir restauracao.

## Perguntas para pesquisa futura

- Onde o macOS atual armazena diferentes classes de diagnosticos em Sequoia/Sonoma?
- Quais diretorios de `DiagnosticReports` sao mais seguros de sugerir?
- Como detectar se um app ainda esta instalado antes de sugerir logs dele?
- Qual e o impacto real de apagar logs de usuario no suporte a apps?
- Vale criar uma regra para logs de containers Docker?

