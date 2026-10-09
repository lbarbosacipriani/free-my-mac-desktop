# Free My Mac Desktop

Versao desktop macOS em SwiftUI/AppKit para o Free My Mac Desktop.

O caminho oficial e abrir o app nativo. Ele nao precisa subir Docker, servidor local nem interface web.

## O que ele faz

- abre uma janela nativa macOS com sidebar e toolbar;
- executa a varredura diretamente pelo app;
- procura arquivos antigos e grandes em locais conservadores, como caches do usuario, caches de apps, logs, Xcode Logs, Downloads antigos, instaladores antigos e sobras do Xcode;
- pode incluir locais globais e Document Versions acessiveis quando essa opcao for ativada;
- mostra candidatos antes de qualquer acao;
- move itens aprovados para quarentena, preservando o caminho original em manifesto local;
- permite restaurar itens da quarentena;
- permite simular e executar purga permanente de sessoes antigas;
- salva relatorios em JSON e Markdown dentro do projeto.

## Requisitos

- macOS;
- Xcode ou Xcode Command Line Tools;
- projeto mantido em:

```text
~/Documents/dev/free-my-mac-desktop
```

Docker Desktop nao e necessario para usar o app nativo.

## Rodar no Xcode

1. Abra o Xcode.
2. Escolha `File > Open...`.
3. Abra:

```text
~/Documents/dev/free-my-mac-desktop/desktop-mac/Package.swift
```

4. Selecione o alvo `FreeMyMacDesktop`.
5. Clique em Run.

O app nativo vai abrir uma janela propria imediatamente. Use `Varredura`, revise `Candidatos` e mova somente o que aceitar para `Quarentena`.

Se nada aparecer, confira se o esquema selecionado no topo do Xcode e `FreeMyMacDesktop`, nao apenas `Package`.

Atalho pelo terminal:

```bash
cd ~/Documents/dev/free-my-mac-desktop
./desktop-mac/open_in_xcode.sh
```

## Build manual

Se o Swift toolchain estiver configurado no terminal:

```bash
cd ~/Documents/dev/free-my-mac-desktop
./desktop-mac/build_app.sh
```

O app gerado fica em:

```text
desktop-mac/build/Free My Mac Desktop.app
```

Rodar pelo `.app` gerado usa o `Info.plist` em `desktop-mac/Info.plist`, incluindo o bundle identifier. Ao rodar diretamente como Swift Package no Xcode, o console pode mostrar um aviso como `missing main bundle identifier`; esse aviso nao impede o app de funcionar.

## Instalar em Applications

Depois do build manual:

```bash
cp -R "desktop-mac/build/Free My Mac Desktop.app" /Applications/
```

## Arquivos locais

Relatorios:

```text
~/Documents/dev/free-my-mac-desktop/reports/native-latest.json
~/Documents/dev/free-my-mac-desktop/reports/native-latest.md
```

Quarentena:

```text
~/Documents/dev/free-my-mac-desktop/quarantine/
```

Logs:

```text
~/Documents/dev/free-my-mac-desktop/logs/
```

Nada e apagado automaticamente durante a varredura. A primeira acao real e mover para quarentena; a remocao permanente fica separada e exige acao explicita.
