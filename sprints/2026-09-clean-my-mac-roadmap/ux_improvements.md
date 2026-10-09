# Melhorias de experiencia

## Problemas atuais

- O app depende do Docker e isso nem sempre fica claro para o usuario.
- A interface mostra candidatos, mas ainda nao explica bem o risco.
- A varredura pode demorar e o usuario precisa confiar que algo esta acontecendo.
- O fluxo de quarentena poderia ser mais visual.
- O `.app` ainda parece um lancador tecnico.

## Melhorias propostas

### 1. Tela inicial orientada a tarefa

Mostrar tres acoes principais:

- Varrer meu Mac
- Ver quarentena
- Abrir logs do app

### 2. Estados claros

Estados sugeridos:

- Docker nao encontrado
- Docker abrindo
- Container subindo
- Interface pronta
- Varredura em andamento
- Varredura concluida
- Erro com acao recomendada

### 3. Cards de resumo

Depois da varredura:

- Espaco potencial recuperavel
- Itens de baixo risco
- Itens que exigem revisao
- Ultima varredura
- Total em quarentena

### 4. Revisao por grupos

Agrupar candidatos por origem:

- Downloads
- Caches de desenvolvimento
- Xcode
- Python/uv
- npm
- HuggingFace
- Logs de usuario
- Diagnosticos macOS

### 5. Linguagem mais humana

Trocar descricoes genericas por frases mais claras:

- "Pode ser recriado automaticamente"
- "Provavelmente e um instalador antigo"
- "Pode ser util se voce estiver investigando crash"
- "Revisar antes de mover"

### 6. Modo avancado separado

Esconder acoes mais sensiveis:

- incluir `/Library/Logs`;
- reduzir retencao para menos de 30 dias;
- purga permanente;
- selecionar tudo em categorias de medio risco.

### 7. Instalacao mais macOS

Melhorias:

- app em `/Applications`;
- icone refinado;
- tela de status sem depender do Terminal;
- opcao "Abrir no navegador";
- opcao "Parar servico".

