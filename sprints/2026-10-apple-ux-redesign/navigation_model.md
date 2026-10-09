# Modelo de navegacao

## Estrutura recomendada

Usar um layout de tres niveis quando necessario:

```text
Sidebar -> Lista/Resumo -> Detalhe
```

Para a primeira versao, uma `NavigationSplitView` com sidebar e conteudo principal ja resolve.

## Sidebar

Itens:

- Visao geral
- Varredura
- Candidatos
- Quarentena
- Logs
- Preferencias

## Visao geral

Mostra:

- estado do servico;
- ultima varredura;
- espaco potencial;
- total em quarentena;
- acoes principais.

CTA principal:

- `Iniciar varredura`

CTA secundario:

- `Abrir logs`

## Varredura

Controles:

- tamanho minimo;
- idade minima;
- incluir logs/caches globais;
- botao `Varrer`;
- progresso/tempo decorrido.

Estados:

- aguardando;
- varrendo;
- concluido;
- erro.

## Candidatos

Tabela:

- selecao;
- nome;
- categoria;
- tamanho;
- idade;
- risco;
- caminho.

Filtros:

- Todos
- Baixo risco
- Revisar
- Logs
- Caches
- Instaladores
- Desenvolvimento

Detalhe lateral ou inferior:

- motivo da sugestao;
- politica aplicada;
- risco;
- caminho original;
- acao recomendada.

## Quarentena

Lista de sessoes:

- data;
- tamanho;
- quantidade de itens;
- idade da sessao.

Acoes:

- restaurar item;
- restaurar sessao;
- simular purga;
- apagar permanentemente.

## Logs

Mostrar:

- `desktop.log`;
- `launcher.log`, se existir;
- `web-latest.json`;
- `web-latest.md`.

Acoes:

- abrir pasta de logs;
- copiar caminho;
- atualizar.

## Preferencias

Preferencias:

- idade minima padrao;
- tamanho minimo padrao;
- retencao da quarentena;
- incluir locais globais por padrao;
- iniciar Docker automaticamente;
- abrir navegador externo apos iniciar.

