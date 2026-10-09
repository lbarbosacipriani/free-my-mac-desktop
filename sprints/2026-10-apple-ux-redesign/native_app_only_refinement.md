# Refinamento: app nativo sem Docker

## Decisao

O fluxo principal do Clean My Mac Desktop passa a ser 100% via app macOS nativo. O usuario nao precisa subir Docker, servidor local ou interface web para usar varredura, selecao, quarentena, restauracao e purga.

## Entregue

- Motor de varredura nativo em Swift.
- Cobertura ampliada para caches do usuario, arquivos antigos em Downloads, caches/logs dentro de apps, sobras do Xcode, Document Versions acessiveis e logs locais/globais.
- Quarentena nativa com manifesto local.
- Restauracao de itens pela interface do app.
- Simulacao e execucao de purga de sessoes antigas.
- Relatorios locais em `reports/native-latest.json` e `reports/native-latest.md`.
- Remocao da dependencia de `DockerService`, `CleanerAPIClient` e tela de fallback web na versao desktop.
- Atualizacao da toolbar e da visao geral para o modelo app-only.
- Tela de candidatos refinada com busca, filtro por categoria, resumo por risco e acao de revelar item no Finder.
- Painel de detalhe para revisar caminho, motivo, tamanho, idade e risco antes da quarentena.
- Confirmacao nativa antes de mover itens para quarentena.
- Confirmacao nativa antes de apagar sessoes da quarentena permanentemente.
- Preferencias persistidas para tamanho minimo, idade minima, locais globais e retencao da quarentena.
- Visao geral com resumo das principais categorias encontradas.
- Tempo de varredura atualizado durante a execucao.
- Menu macOS `Limpeza` com atalhos para varredura, candidatos, quarentena e relatorios.
- Icone refinado em estilo macOS, com drive limpo, varredura e brilho; gerado como `.iconset` completo e `.icns`.

## Politica de seguranca

- A varredura nao apaga nada automaticamente.
- A primeira acao real e mover para quarentena.
- A remocao permanente fica separada e explicita.
- Symlinks e caminhos criticos do sistema sao ignorados.
- Locais globais acessiveis so entram quando o usuario ativa essa opcao.
- Document Versions recebe risco alto e exige revisao manual.
- Arquivos comuns de Downloads recebem risco medio e nao sao selecionados automaticamente.
- Sobras do Xcode em `DeviceSupport` recebem risco medio.
- Selecao rapida de baixo risco considera apenas os itens visiveis apos filtros.
- Acoes irreversiveis usam confirmacao nativa.

## Legado

O backend Python/Docker pode continuar existindo no repositorio como caminho legado ou para comparacao, mas nao e mais necessario para a experiencia desktop principal.
