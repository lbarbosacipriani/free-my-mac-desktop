# Direcao visual Apple/macOS

## Principios

- Usar controles nativos sempre que possivel.
- Evitar aparencia de dashboard web.
- Evitar cards decorativos em excesso.
- Deixar a hierarquia clara com sidebar, toolbar e paineis.
- Usar linguagem simples e orientada a risco.

## Janela

Recomendacao:

- largura inicial: 1100-1200 px;
- altura inicial: 720-800 px;
- sidebar com largura de 220-260 px;
- toolbar integrada ao topo;
- conteudo principal com tabela/lista.

## Toolbar

A toolbar deve conter comandos frequentes:

- Iniciar
- Parar
- Varrer
- Recarregar
- Abrir logs
- Preferencias

Usar SF Symbols:

- `play.fill` para iniciar;
- `stop.fill` para parar;
- `arrow.clockwise` para recarregar;
- `doc.text.magnifyingglass` ou `magnifyingglass` para varrer;
- `folder` para logs;
- `gearshape` para preferencias.

## Sidebar

Usar sidebar para navegacao persistente.

Itens sugeridos:

- Visao geral: `gauge`
- Varredura: `magnifyingglass`
- Candidatos: `list.bullet.rectangle`
- Quarentena: `archivebox`
- Logs: `doc.text`
- Preferencias: `gearshape`

## Tabela de candidatos

A tabela deve ser densa, mas limpa.

Colunas:

- checkbox;
- nome;
- categoria;
- tamanho;
- idade;
- risco;
- caminho.

Risco:

- baixo: texto/selo discreto verde;
- medio: amarelo/laranja;
- alto: vermelho, mas evitar uso excessivo.

## Acoes destrutivas

Fluxo recomendado:

1. Mover para quarentena: acao primaria apos selecao.
2. Apagar permanentemente: sempre em tela de quarentena, nunca na tela principal.
3. Confirmacao nativa antes de purga.
4. Mostrar resumo antes de apagar:
   - quantidade de itens;
   - tamanho total;
   - sessao afetada;
   - irreversibilidade.

## Linguagem

Preferir:

- "Mover para quarentena"
- "Restaurar"
- "Apagar permanentemente"
- "Baixo risco"
- "Revisar antes de mover"

Evitar:

- "Limpar tudo"
- "Otimizar Mac"
- "Remover lixo"
- "Acelerar sistema"

O app deve soar confiavel, nao agressivo.

