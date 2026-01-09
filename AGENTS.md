# Projeto: MQL5 Object Replicator (Context7)

Este projeto sincroniza objetos gráficos entre múltiplos gráficos do mesmo ativo.

## Estrutura:

- `MainIndicator.mq5`: Ponto de entrada e captura de eventos `OnChartEvent`.
- `Context7_Logic.mqh`: Classe principal que gerencia o broadcast de objetos.

## Comandos Úteis:

- Compilar: MQL5.exe /compile:MainIndicator.mq5
- Testar: Arrastar para um gráfico e abrir outro gráfico do mesmo símbolo.
