# Refinamento - Historico e visao de desenvolvedor

## Entregue

- Tela `Historico` na sidebar.
- Cartoes de resumo para:
  - espaco liberado permanentemente;
  - espaco atualmente em quarentena;
  - espaco ja revisado.
- Persistencia local em `reports/cleanup-history.json`.
- Registro automatico quando itens vao para quarentena.
- Registro automatico quando sessoes antigas sao apagadas permanentemente.
- Tela `Desenvolvedor` na sidebar.
- Explicacoes para alvos comuns de projetos:
  - Python virtual environments;
  - `node_modules`;
  - Rust `target`;
  - Java/Kotlin build caches;
  - mobile build artifacts.
- Regras sugeridas ampliadas para:
  - `.venv`, `venv`, `env`, `.tox`;
  - `node_modules`;
  - Rust `target`;
  - `.next`, `.nuxt`, `dist`, `build`, `.svelte-kit`;
  - Ruby `vendor/bundle`;
  - Go module cache;
  - Flutter/Dart artifacts;
  - `__pycache__`, `.pytest_cache`, `.mypy_cache`, `.ruff_cache`;
  - Gradle, Maven, Homebrew, HuggingFace, Docker e CoreSimulator.
- Scanner agora suporta busca recursiva segura por diretorios nomeados.
- Historico agora exibe barras proporcionais por evento.
- Tela de desenvolvedor usa grade adaptativa para caber melhor em diferentes tamanhos de janela.
- Tela `Quarentena` separa claramente `Ainda em quarentena` de `Ja purgado`, deixando explicito o que ainda pode ser restaurado e o que ja foi apagado permanentemente.
- Scanner agora detecta explicitamente `Xcode Logs`, incluindo `*.xcactivitylog` e logs antigos de build/test dentro de `DerivedData`.
- Tela `Varredura` agora permite enviar itens de baixo risco diretamente para quarentena e deixa claro que candidatos ainda nao estao em quarentena.
- Tela `Quarentena` agora tem `Purgar tudo` para apagar 100% da quarentena com confirmacao explicita.
- Refinamento visual com botoes grandes em bloco, icones destacados e superficies `Material` adaptativas para modo claro e escuro nas telas `Visao geral`, `Varredura`, `Quarentena`, `Desenvolvedor` e `Logs`.

## Politica de seguranca

- A visao de desenvolvedor nao apaga nada.
- Regras de desenvolvedor entram como sugestao.
- Para entrar na varredura principal, a regra precisa ser ativada manualmente na tela `Regras`.
- Mesmo ativa, a regra apenas lista candidatos; remocao continua passando por quarentena.

## Arquivos principais

- `desktop-mac/Sources/Views/CleanupHistoryView.swift`
- `desktop-mac/Sources/Views/DeveloperView.swift`
- `desktop-mac/Sources/Services/CleanupHistoryService.swift`
- `desktop-mac/Sources/Models/CleanupHistoryModels.swift`
- `desktop-mac/Sources/Services/RuleDiscoveryService.swift`
- `desktop-mac/Sources/Services/NativeScannerService.swift`
