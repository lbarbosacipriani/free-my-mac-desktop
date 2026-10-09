# Sprint - Repaginacao Apple UX

Objetivo: redesenhar completamente a experiencia desktop macOS do Clean My Mac Desktop usando padroes nativos da Apple, com foco em clareza, seguranca e confianca.

## Principio central

O app deve parecer um utilitario macOS nativo, nao uma pagina web dentro de uma janela. A interface deve reduzir ansiedade ao lidar com limpeza de arquivos: mostrar estado, explicar risco e manter reversibilidade.

## Referencias oficiais

- Apple Human Interface Guidelines: https://developer.apple.com/design/human-interface-guidelines/
- Toolbars: https://developer.apple.com/design/human-interface-guidelines/toolbars
- Sidebars: https://developer.apple.com/design/human-interface-guidelines/sidebars
- Apple Design Resources: https://developer.apple.com/design/resources/
- Apple Style Guide: https://support.apple.com/guide/applestyleguide/welcome/web

## Direcao de produto

- Migrar a experiencia principal para interface nativa SwiftUI/AppKit.
- Manter o backend Docker/web enquanto a logica e amadurecida.
- Evitar visual de dashboard web.
- Usar janela com sidebar, toolbar macOS e paineis de detalhe.
- Fazer acoes destrutivas parecerem deliberadas, nao acidentais.

## Entregaveis desta sprint

- `apple_ux_backlog.md`: backlog priorizado.
- `navigation_model.md`: arquitetura de navegacao.
- `visual_direction.md`: direcao visual macOS.
- `technical_plan.md`: plano tecnico SwiftUI/AppKit.
- `acceptance_criteria.md`: criterios de aceite.

