Padrões de Desenvolvimento MQL5 - Context7
• Arquitetura: Siga sempre o modelo Context7 (Coleta, Processamento, Estado, Renderização).

• POO: Lógica complexa deve estar em classes (.mqh). O arquivo .mq5 deve ser apenas um wrapper de eventos.

• Memória: Use `CheckPointer` e `delete` para objetos dinâmicos. Use `ArraySetAsSeries` para buffers.

• Performance: No `OnCalculate`, use sempre a verificação de `prev_calculated`.

• Nomenclatura: Membros de classe prefixados com `m_`, globais com `g_`, inputs com `Inp`.
