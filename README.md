# SyncObjects (MQL5)

**SyncObjects** é um utilitário para MetaTrader 5 projetado para sincronizar objetos gráficos entre múltiplos gráficos do mesmo ativo. Ideal para análises multi-timeframe.

## Funcionalidades

- **Sincronização Bidirecional**: Crie, edite ou exclua objetos em _qualquer_ janela do mesmo par, e a alteração será refletida em todas as outras.
- **Tipos de Objetos Suportados**:
  - Linhas (Vertical, Horizontal, Tendência)
  - Figuras (Triângulo, Retângulo)
  - Fibonacci & Canais (Desvio Padrão)
- **Filtro por Nome**: Apenas objetos cujo nome comece com os prefixos de timeframe são sincronizados:
  - `M1`, `M2`, `M5`, `M15`
  - `H1`, `H4`
  - `Daily`, `Weekly`
- **Show Object (Auto-Scroll)**: Ao criar um novo objeto, todas as outras janelas rolam automaticamente para focar no objeto criado.
- **Sincronização de Propriedades**:
  - Preço e Tempo
  - Cor, Estilo, Espessura
  - Visibilidade por Timeframe (`OBJPROP_TIMEFRAMES`)
  - Níveis de Fibonacci

## Instalação

1. Copie a pasta `syncObjects` para o diretório `MQL5/Indicators/` do seu MetaTrader 5.
2. Compile o arquivo `SyncObjects.mq5`.
3. Arraste o indicador **SyncObjects** para todos os gráficos que deseja sincronizar.

## Uso

1. Abra múltiplos gráficos do mesmo ativo (ex: EURUSD H1, EURUSD M15, EURUSD M1).
2. Adicione o indicador a todos eles.
3. Crie um objeto (ex: Linha de Tendência) e renomeie-o para começar com um prefixo válido (ex: `H1_Analise`).
   - _Nota: Se você usa algum painel que cria objetos automaticamente com esses prefixos, eles serão sincronizados._
4. O objeto aparecerá instantaneamente nos outros gráficos.

## Requisitos

- MetaTrader 5
